# Fusionneur — Référence technique

Ce document décrit l'architecture technique complète de Fusionneur :
- Les **modèles de données** (Hive + objets internes)
- Les **services et méthodes principales** avec leurs responsabilités
- Les **patterns architecturaux** utilisés
- Les **flux de données** pour chaque mode d'opération

**Dernière mise à jour** : 2025-12-02

---

## 📐 Architecture globale

### Structure modulaire

```
lib/
├── core/                   # Services transversaux
│   ├── constants.dart      # Tags ::FUSION::, constantes
│   ├── glob_matcher.dart   # Filtrage par patterns glob
│   ├── json_models.dart    # FusionFileEntry, FusionIndex
│   ├── tree_order.dart     # Stratégies d'ordonnancement
│   └── utils/              # PathUtils, BytesUtils, PubspecUtils, etc.
│
├── data/                   # Couche persistence
│   ├── hive/               # Modèles Hive et adaptateurs
│   ├── repositories/       # Accès aux données (CRUD)
│   ├── providers/          # Providers Riverpod
│   └── services/           # Services data (lecture/écriture)
│
├── services/               # Moteur de fusion (business logic)
│   ├── concatenator.dart   # Service principal (2 passes)
│   ├── concatenator_parts/ # Sous-services factorisés (15+)
│   ├── import_graph.dart   # Analyse des dépendances
│   ├── file_scanner.dart   # Scan récursif des fichiers
│   ├── file_filter.dart    # Filtrage (glob patterns)
│   ├── hash/               # HashGuardService (déduplication)
│   ├── fusion/             # FusionGenerator, DedupService
│   └── storage.dart        # Gestion centralisée des chemins
│
└── pages/                  # Interface utilisateur
    ├── home/               # Mode standard (fusion complète)
    ├── entry_mode/         # Mode entrypoint (fusion partielle)
    ├── preset/             # Éditeur de presets
    └── admin/              # Pages debug (HiveDebugPage)
```

### Patterns architecturaux

| Pattern | Usage |
|---------|-------|
| **Repository Pattern** | Accès à Hive via repositories abstraits |
| **Service Locator** | Storage.I pour accès global |
| **Dependency Injection** | Constructeurs avec params optionnels pour tests |
| **StateNotifier + Riverpod** | State management UI |
| **Two-Pass Processing** | Concatenator : index provisoire puis final |
| **Strategy Pattern** | FileOrderingPolicy, NumberingStrategy |

---

## 📦 Modèles de données

### HiveProject

```dart
@HiveType(typeId: 1)
class HiveProject extends HiveObject {
  @HiveField(0) final String id;           // UUID unique
  @HiveField(1) final String name;         // Nom lisible (déprécié, utiliser packageName)
  @HiveField(2) final String rootPath;     // Chemin absolu POSIX
  @HiveField(3) final String packageName;  // Nom du package (pubspec.yaml)
  @HiveField(4) final String slug;         // Version slugifiée (pour chemins exports)
}
```

**Responsabilités** :
- Représente un projet Flutter indexé/fusionnable
- Point d'ancrage pour les presets et les runs
- `rootPath` stocké en format POSIX (converti en natif pour FilePicker via `PathUtils.toNative()`)

---

### HivePreset

```dart
@HiveType(typeId: 2)
class HivePreset extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String projectId;
  @HiveField(2) final String name;
  @HiveField(3) final HiveSelectionSpec hiveSelectionSpec;
  @HiveField(4) final HiveFileOrderingPolicy hiveFileOrderingPolicy;
  @HiveField(5) final HiveFilterOptions hiveFilterOptions;
  @HiveField(6) final bool isFavorite;
  @HiveField(7) final bool isDefault;      // Un seul par projet
  @HiveField(8) final bool isArchived;     // Caché en UI
}
```

**Responsabilités** :
- Configuration réutilisable de fusion (fichiers, ordre, filtres)
- Permet de rejouer facilement une fusion identique
- Lié à un projet via `projectId`

---

### HiveRun

```dart
@HiveType(typeId: 3)
class HiveRun extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String projectId;
  @HiveField(2) final String presetId;
  @HiveField(3) final DateTime timestamp;
  @HiveField(4) final String exportPath;   // Chemin du fichier généré
  @HiveField(5) final String hash;         // Hash CRC32 du contenu
}
```

**Responsabilités** :
- Trace une exécution de fusion (historique)
- Permet déduplication via hash
- Affichage historique dans l'UI (RecentRunsSection)

---

### FusionFileEntry (index JSON)

```dart
class FusionFileEntry {
  final int fileNumber;        // Numéro d'ordre dans la fusion
  final String fileName;       // Nom du fichier (basename)
  final String filePath;       // Chemin relatif POSIX
  final int startLine;         // Ligne de début dans le fichier fusionné
  final int endLine;           // Ligne de fin
  final List<String> imports;  // Fichiers importés (format: "N,path")
  final List<String> importedBy; // Fichiers qui importent ce fichier
  final List<String> fusionTags; // Tags ::FUSION:: associés (inclut ::FUSION::unused si orphelin)
}
```

**Responsabilités** :
- Entrée de l'index JSON intégré au fichier fusionné
- Navigation rapide entre fichiers
- Analyse des dépendances (qui importe qui)

---

## 🛠️ Services & méthodes principales

### Concatenator

Service central qui produit le fichier fusionné en **deux passes**.

```dart
class Concatenator {
  Future<void> writeToTmpAndMaybeReplace({
    required String tmpPath,
    required ConcatenationOptions options,
  });
}
```

**Algorithme (2 passes)** :

**Pass 1** (index provisoire) :
1. Sélectionner les fichiers (SelectionSpec)
2. Filtrer (patterns glob, onlyDart)
3. Ordonner (TREE, explicit, alpha)
4. Numéroter (1, 2, 3...)
5. Calculer ImportGraph (qui importe qui)
6. Construire index JSON provisoire (startLine/endLine = -1)
7. Écrire fichier tmp avec MANIFEST + JSON provisoire + sections code

**Pass 2** (index final) :
1. Relire le fichier tmp
2. Scanner les bannières `::FUSION::code#N`
3. Mettre à jour startLine/endLine réels
4. Réécrire JSON index final
5. Renommer tmp → final

**Sous-services utilisés** (dans `concatenator_parts/`) :
- `ManifestWriter` : Écrit la section MANIFEST (adapté selon FusionMode)
- `JsonIndexWriter` : Écrit l'index JSON
- `CodeSectionWriter` : Écrit les sections code
- `FileOrderer` : Ordonnancement des fichiers
- `NumberingService` : Numérotation
- `IndexProvisionalBuilder` : Index provisoire
- `JsonIndexFinalizer` : Index final
- `UnusedTagger` : Détecte les fichiers orphelins
- ... (15+ sous-services)

---

### ConcatenationOptions

Configuration passée au `Concatenator`.

```dart
class ConcatenationOptions {
  final SelectionSpec selectionSpec;        // Quels fichiers inclure
  final List<String>? excludePatterns;      // Patterns glob (*.g.dart, *.arb)
  final bool onlyDart;                      // Filtre non-Dart
  final FileOrderingPolicy fileOrderingPolicy; // Ordre des fichiers
  final NumberingStrategy numbering;        // Stratégie de numérotation

  // Hooks pour calcul des graphes d'import/export
  final Future<Map<String, Set<String>>> Function(...)? computeImports;
  final Future<Map<String, Set<String>>> Function(...)? computeExports;

  // Métadonnées pour le manifest (adapte l'en-tête selon le mode)
  final FusionMode manifestMode;            // Mode: project/entrypoint/unused
  final String? manifestPresetName;         // Nom du preset (mode project)
  final String? manifestEntrypoint;         // Fichier d'entrée (mode entrypoint)
}
```

---

### ImportGraph

Analyse les dépendances entre fichiers.

```dart
class ImportGraph {
  static Future<Map<String, Set<String>>> computeImports({
    required String projectRoot,
    required List<String> files,
    required String packageName,
  });
}
```

**Algorithme** :
1. Parcourt chaque fichier `.dart`
2. Regex sur `import '...'` et `export '...'`
3. Résout les chemins (`package:`, `./`, `../`)
4. Filtre au périmètre (inScope uniquement)
5. Retourne `Map<filePath, Set<importedFiles>>`

---

### ManifestWriter

Génère la section MANIFEST en tête du fichier fusionné, adaptée selon le mode de fusion.

```dart
enum FusionMode {
  project,     // Fusion basée sur un preset (sélection utilisateur)
  entrypoint,  // Fusion à partir d'un entrypoint + imports transitifs
  unused,      // Fusion des fichiers orphelins (jamais référencés)
}

class ManifestInfo {
  final String projectName;   // Nom logique du projet (affichage)
  final String formatVersion; // ex: "Fusion v3"
  final FusionMode mode;      // Mode de fusion
  final String? presetName;   // Preset utilisé (mode project)
  final String? entrypoint;   // Fichier d'entrée (mode entrypoint)
}

class ManifestWriter {
  void writeTo(StringSink out, ManifestInfo info);
}
```

**Manifests générés selon le mode** :

**Mode Project** :
```
Fusion v3 — Project: MyApp (preset: default_preset)
This file contains a selection of files from the project, based on user-defined inclusion patterns.
```

**Mode Entrypoint** :
```
Fusion v3 — Entrypoint fusion (project: MyApp)
Entrypoint: lib/main.dart
This file contains the entrypoint file and all its transitive internal imports.
```

**Mode Unused** :
```
Fusion v3 — Unused files analysis (project: MyApp)
This file contains all files from the project that are never referenced (no imports, no exports, no main()).
These files are potential candidates for cleanup.
```

**Caractéristiques** :
- Aucune donnée volatile (pas de date, pas de durée) pour préserver le déterminisme du hash
- Texte en anglais (convention : code/output en anglais, commentaires en français)
- Instructions de navigation identiques pour tous les modes
- Tags ::FUSION:: standardisés

---

### HashGuardService

Déduplication par hash CRC32.

```dart
class HashGuardService {
  Future<HashGuardResult> guardAndMaybeCommitFusion({
    required String projectRoot,
    required String finalPath,
    required String tempPath,
    required ConcatenationOptions options,
    bool force = false,
    bool dryRun = false,
  });
}
```

**Logique** :
1. Appel Concatenator → écrit `tempPath`
2. Calcul CRC32(tempPath)
3. Si finalPath existe : calcul CRC32(finalPath)
4. Décision :
   - **skippedIdentical** : Hashes identiques et !force → delete tmpPath
   - **dryRunDifferent** : dryRun=true → delete tmpPath
   - **committed** : !dryRun → rename tmpPath → finalPath

---

### Storage

Service Locator pour les chemins système.

```dart
class Storage {
  static Storage get I { ... }  // Singleton

  Directory projectExportsDir(String projectSlug);
  Directory projectEntrypointExportsDir(String projectSlug);
  Directory projectUnusedExportsDir(String projectSlug);

  String buildNamedExportPath({
    required String projectSlug,
    required String appName,
    required String presetName,
    required int sequence,
    String extension = 'txt',
  });
}
```

**Chemins par défaut** :
```
~/Documents/fusionneur/
├── hive/                # Bases Hive
├── exports/             # Fichiers fusionnés
│   └── <projectSlug>/
│       ├── <app>-<preset>-<n>.md        # Mode project
│       ├── entrypoint/
│       │   └── <file>-<timestamp>.md    # Mode entrypoint
│       └── unused/
│           └── <pkg>-unused-<timestamp>.md  # Mode unused
├── presets/             # Exports de presets (JSON)
├── temp/                # Fichiers temporaires
├── logs/                # Logs d'exécution
└── cache/               # Cache interne
```

---

## 🎯 Modes d'opération

### Mode Standard (HomePage)

**Flux complet** :
```
HomePage
  ├─ Sélectionner un HiveProject
  ├─ Sélectionner un HivePreset (ou créer nouveau)
  │  └─ PresetEditorPage (configuration fichiers inclus/exclus)
  └─ Cliquer "Fusionner"
      └─ FusionRunner.run()
         ├─ Calcul du hash du projet label
         ├─ Appel à FusionGenerator (Concatenator + HashGuardService)
         ├─ Vérification déduplication (DedupService)
         └─ Enregistrement HiveRun (historique)
```

**Caractéristiques** :
- Fusion complète du projet (tous les fichiers de `lib/`)
- Configuration réutilisable via presets
- Historique persisté dans Hive
- Déduplication par hash (ne ré-écrit pas si identique)
- Export : `~/Documents/fusionneur/exports/<projectLabel>/<app>-<preset>-<n>.md`

---

### Mode Entrypoint (EntryModePage)

**Flux complet** :
```
EntryModePage (UI)
  ├─ Sélectionner un fichier d'entrée (FilePicker)
  │  └─ Ouvre dans projectRoot/lib/ (PathUtils.toNative pour Windows)
  ├─ Configurer options (includeImportedByOnce, excludeGenerated, excludeI18n)
  ├─ Preview
  │  └─ EntrypointFusionOrchestrator.run()
  │     ├─ Fermeture transitive des imports depuis l'entrypoint
  │     ├─ Filtrage des fichiers sélectionnés
  │     └─ Affichage dans SelectionPreviewList (scrollable)
  │        ├─ Calcul taille totale (BytesUtils.prettyBytes)
  │        └─ Liste scrollable avec ScrollController explicite
  └─ Fusion
      └─ buildEntrypointRunWriterAdapter()
         ├─ Filtre les fichiers (exclude patterns)
         ├─ Construit ConcatenationOptions
         └─ Appel HashGuardService
             └─ Export : ~/Documents/fusionneur/exports/<packageName>/entrypoint/<file>-<timestamp>.md
```

**Caractéristiques** :
- Fusion partielle depuis un fichier d'entrée unique
- Fermeture transitive des imports (BFS)
- Pas de preset persisté, pas d'historique Hive
- Fusion "à la volée" sans déduplication Hive
- Options de nettoyage (*.g.dart, *.arb) appliquées à la volée
- Preview avec résumé (X fichiers • Y Ko) + liste scrollable

**Composants UI** :

**EntryFilePicker** :
- Ouvre FilePicker dans `projectRoot/lib/` (plus pratique)
- Conversion POSIX → natif via `PathUtils.toNative()` pour Windows
- Affiche le chemin sélectionné

**SelectionPreviewList** (StatefulWidget) :
- Calcule taille totale des fichiers via `File.lengthSync()`
- Affiche résumé : "X fichiers • Y Ko"
- Liste scrollable avec `ScrollController` explicite
- `Scrollbar` avec `thumbVisibility: true` pour Windows desktop
- `ScrollConfiguration` avec `dragDevices: {mouse, touch}` pour activer drag-scroll

**Corrections Windows Desktop** :
- FilePicker nécessite chemins natifs (`\` au lieu de `/`)
- Scrollbar nécessite `ScrollController` explicite (erreur "no ScrollPosition attached")
- Drag-scroll nécessite `ScrollConfiguration` avec `dragDevices` incluant mouse

---

### Mode Unused (HomePage → UnusedModeButton)

**Flux complet** :
```
HomePage
  ├─ Cliquer sur bouton "Fichiers inutilisés"
  └─ UnusedRunService.run()
     ├─ FileScanner : liste tous les fichiers sous lib/
     ├─ ImportGraph : calcule imports + exports
     ├─ UnusedTagger.computeUnused()
     │  ├─ Fichiers jamais référencés par import
     │  ├─ Fichiers jamais référencés par export (barrels)
     │  ├─ Fichiers jamais référencés par "part 'x.dart';"
     │  └─ Fichiers sans fonction main()
     ├─ ConcatenationOptions avec manifestMode: FusionMode.unused
     └─ HashGuardService
        └─ Export : ~/Documents/fusionneur/exports/<packageName>/unused/<pkg>-unused-<timestamp>.md
```

**Caractéristiques** :
- Détection automatique des fichiers orphelins
- Analyse complète du graphe des dépendances
- Pas d'historique Hive (fusion ponctuelle)
- Tous les fichiers ont le tag `::FUSION::unused` dans fusionTags
- Utile pour nettoyer un projet et détecter du code mort

**Algorithme UnusedTagger** :

1. **Collecter les références** :
   - Fichiers importés via `import '...'`
   - Fichiers exportés via `export '...'` (barrel files)
   - Fichiers inclus via `part 'x.dart';`

2. **Détecter les entrypoints** :
   - Fichiers contenant `main()` ou `Future<void> main(...)`

3. **Décision** :
   - **Unused** = fichier .dart jamais référencé ET sans main()
   - **Used** = tout le reste

**Cas particuliers** :
- Les fichiers `*.g.dart` (générés) ne sont jamais marqués unused
- Les fichiers `*.arb` (localisation) sont ignorés
- Les fichiers de test ne sont pas analysés

---

### Mode CLI (bin/cli.dart)

**Commandes** :
```bash
# Fusion standard
dart run bin/cli.dart [--project <path>] [--out <path>] [--dry-run] [--force]

# Lister les fichiers inutilisés
dart run bin/cli.dart -unused
```

**Caractéristiques** :
- Pas d'UI, fusion directe
- Support `--dry-run` (calcule hash, affiche décision sans écrire)
- Support `--force` (écrit même si identique)
- Export : `~/Documents/fusionneur/exports/<projectSlug>/<app>-<preset>-<n>.md`

---

## 🧰 Utilitaires (core/utils/)

### PathUtils

Manipulation de chemins multi-plateforme.

```dart
class PathUtils {
  static String toPosix(String path);        // '\' → '/'
  static String toNative(String path);       // '/' → '\' sur Windows
  static String normalize(String path);      // POSIX + lowercase + trim slash
  static String toProjectRelative(String projectRoot, String absPath);
  static String basename(String path);
  static String dirname(String path);
  static String join(String a, String b);
  static bool isUnder(String root, String path);
}
```

**Usage critique** :
- Tous les chemins stockés en POSIX (uniformité)
- Conversion en natif uniquement pour FilePicker sur Windows
- `join()` pour construire chemins (évite problèmes de trailing slash)

---

### BytesUtils

```dart
class BytesUtils {
  static String prettyBytes(int bytes);  // 1024 → "1 KB", 1048576 → "1 MB"
}
```

---

### PubspecUtils

```dart
class PubspecUtils {
  static Future<String?> tryReadName(String projectRoot);
}
```

Lit `pubspec.yaml` et extrait `name:`.

---

## 🔄 Pipeline résumé

### Mode Standard
1. **HomePage** : Utilisateur sélectionne projet + preset
2. **FusionRunner** : Construit ConcatenationOptions
3. **Concatenator** : Génère contenu (2 passes)
4. **HashGuardService** : Vérifie unicité (CRC32)
5. **Storage** : Écrit export dans `~/Documents/fusionneur/exports/`
6. **HiveRun** : Enregistre historique dans Hive

### Mode Entrypoint
1. **EntryModePage** : Utilisateur sélectionne fichier d'entrée + options
2. **EntrypointFusionOrchestrator** : BFS depuis entrypoint, fermeture transitive
3. **Preview** : SelectionPreviewList affiche fichiers + taille
4. **buildEntrypointRunWriterAdapter** : Filtre et construit options
5. **HashGuardService** : Génère fichier fusionné
6. **Storage** : Export dans `~/Documents/fusionneur/exports/<pkg>/entrypoint/`

### Mode Unused
1. **HomePage** : Utilisateur clique sur "Fichiers inutilisés"
2. **UnusedRunService** : Scanne tous les fichiers sous lib/
3. **ImportGraph** : Calcule imports + exports
4. **UnusedTagger** : Détecte les fichiers orphelins
5. **Concatenator** : Génère fichier fusionné (manifestMode: unused)
6. **HashGuardService** : Vérifie unicité
7. **Storage** : Export dans `~/Documents/fusionneur/exports/<pkg>/unused/`

---

## 🎨 État UI (Riverpod)

### Mode Standard (HomePage)

- `fusionServiceProvider` : FusionService
- `projectServiceProvider` : ProjectService
- `presetServiceProvider` : PresetService

### Mode Entrypoint (EntryModePage)

- `entryModeControllerProvider` : StateNotifierProvider<EntryModeController, EntryModeState>

**EntryModeState** :
```dart
class EntryModeState {
  final String? entryFile;
  final EntryModeOptions options;
  final List<String> previewFiles;
  final bool isLoadingPreview;
  final bool isRunning;
  final String? errorMessage;
  // ...
}
```

**EntryModeController** :
```dart
class EntryModeController extends StateNotifier<EntryModeState> {
  void setEntryFile(String? filePath);
  void updateOptions(EntryModeOptions newOptions);
  Future<void> loadPreview({...});  // Appel orchestrator.run()
  Future<void> runFusion({...});    // Appel executor.run()
}
```

---

## 📝 Fichiers générés

### Structure du fichier fusionné

```markdown
::FUSION::SECTION:MANIFEST
Fusion v3 — Project: MyApp (preset: default_preset)
This file contains a selection of files from the project, based on user-defined inclusion patterns.

HOW TO NAVIGATE THIS FILE
- Use the JSON Index to locate a file by "fileName" or "fileNumber".
- Jump directly to a code block by searching its tag: ::FUSION::code:<fileName>
- Or search by number: ::FUSION::code:<N,>  (comma avoids false positives: "17," ≠ "171,")
- Line ranges (startLine/endLine) are provided in JSON Index for each file.
- When multiple files share the same name, prefer number tags (::FUSION::code:<N,>) to disambiguate.
- Imports and reverse imports are listed in JSON Index, with ready-to-search tags.

TAGS CHEAT-SHEET (copy & search):
- JSON by name → ::FUSION::json:<fileName>
- JSON by num  → ::FUSION::json:<N,>
- IMPORT by name → ::FUSION::import:<fileName>
- IMPORT by num  → ::FUSION::import:<N,>
- IMPORTED by name → ::FUSION::imported:<fileName>
- IMPORTED by num  → ::FUSION::imported:<N,>
- CODE by name → ::FUSION::code:<fileName>
- CODE by num  → ::FUSION::code:<N,>

CONVENTIONS
- POSIX relative paths from project root.
- Lines are 1-indexed and count ALL lines (manifest, delimiters, JSON, banners, fences, code).
- Source code blocks are unmodified (no reformat, no lint).

::FUSION::SECTION:JSON_INDEX
The JSON Index is delimited by:
  ----- BEGIN JSON INDEX -----
  [ { ... }, { ... } ]
  ----- END JSON INDEX -----

::FUSION::SECTION:CODE
Each code block is introduced by a FILE banner and a tag line, for example:
  ---- FILE 1 - lib/main.dart ----
  ::FUSION::code:main.dart ::FUSION::code:1, ::FUSION::json:main.dart
  ```dart
  // file content...
  ```
  ---- END FILE 1 ----

----- BEGIN JSON INDEX -----
[
  {
    "fileNumber": 1,
    "fileName": "main.dart",
    "filePath": "lib/main.dart",
    "startLine": 55,
    "endLine": 80,
    "imports": ["2,lib/app.dart"],
    "importedBy": [],
    "fusionTags": ["::FUSION::json:main.dart", "::FUSION::json:1,", "::FUSION::code:main.dart", "::FUSION::code:1,"]
  },
  {
    "fileNumber": 2,
    "fileName": "app.dart",
    "filePath": "lib/app.dart",
    "startLine": 85,
    "endLine": 120,
    "imports": [],
    "importedBy": ["1,lib/main.dart"],
    "fusionTags": ["::FUSION::json:app.dart", "::FUSION::json:2,", "::FUSION::code:app.dart", "::FUSION::code:2,"]
  }
]
----- END JSON INDEX -----

---- FILE 1 - lib/main.dart ----
::FUSION::code:main.dart ::FUSION::code:1, ::FUSION::json:main.dart ::FUSION::json:1, ::FUSION::import:app.dart ::FUSION::import:2,
```dart
import 'package:flutter/material.dart';
import './app.dart';

void main() { runApp(const MyApp()); }
```
---- END FILE 1 ----

---- FILE 2 - lib/app.dart ----
::FUSION::code:app.dart ::FUSION::code:2, ::FUSION::json:app.dart ::FUSION::json:2, ::FUSION::imported:main.dart ::FUSION::imported:1,
```dart
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: Scaffold());
}
```
---- END FILE 2 ----
```

---

## 🐛 Problèmes résolus (Windows Desktop)

### FilePicker ne s'ouvre pas dans le bon dossier
**Symptôme** : Dialogue s'ouvre dans un dossier aléatoire.
**Cause** : FilePicker attend des chemins Windows (`\`) mais reçoit POSIX (`/`).
**Solution** : `PathUtils.toNative()` avant de passer à FilePicker.

### Scrollbar visible mais non fonctionnel
**Symptôme** : Scrollbar réagit au clic mais ne se déplace pas.
**Cause** : "The Scrollbar's ScrollController has no ScrollPosition attached"
**Solution** : Transformation en StatefulWidget avec `ScrollController` explicite partagé entre Scrollbar et ListView.

### Scroll à la souris désactivé
**Symptôme** : Impossible de scroller avec la molette ou drag.
**Cause** : Windows desktop ne détecte pas automatiquement le scroll à la souris.
**Solution** : `ScrollConfiguration` avec `dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch}`.

---

## 📚 Références

- **Architecture** : docs/README_instructions.md
- **Migrations** : docs/README_migration.md (si existe)
- **MAJ** : docs/README_maj.md (si existe)

---

📘 **Document** : README_technical_ref.md
📅 **Version** : 2025-12-02
✍️ **Auteur** : Narya / Olivier Claverie
🤖 **Contributeur** : Claude (Anthropic)
