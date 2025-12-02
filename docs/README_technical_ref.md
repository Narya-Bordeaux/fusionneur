# Fusionneur — Référence technique

Ce document décrit l'architecture technique complète de Fusionneur :
- Les **modèles de données** (Hive + objets internes)
- Les **services et méthodes principales** avec leurs responsabilités
- Les **patterns architecturaux** utilisés
- Les **flux de données** pour chaque mode d'opération

**Dernière mise à jour** : 2025-12-01

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
  final List<String> fusionTags; // Tags ::FUSION:: associés
  final bool unused;           // Fichier jamais importé ?
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
- `ManifestWriter` : Écrit la section MANIFEST
- `JsonIndexWriter` : Écrit l'index JSON
- `CodeSectionWriter` : Écrit les sections code
- `FileOrderer` : Ordonnancement des fichiers
- `NumberingService` : Numérotation
- `IndexProvisionalBuilder` : Index provisoire
- `JsonIndexFinalizer` : Index final
- ... (15+ sous-services)

---

### ConcatenationOptions

Configuration passée au `Concatenator`.

```dart
class ConcatenationOptions {
  final String projectRoot;                 // Chemin racine (POSIX)
  final SelectionSpec selectionSpec;        // Quels fichiers inclure
  final List<String>? excludePatterns;      // Patterns glob (*.g.dart, *.arb)
  final bool onlyDart;                      // Filtre non-Dart
  final FileOrderingPolicy fileOrderingPolicy; // Ordre des fichiers
  final Future<Map<String, Set<String>>> Function(...)? computeImports;
  final Future<Map<String, Set<String>>> Function(...)? computeExports;
  final String packageName;                 // Du pubspec.yaml
  // ... autres options
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
│       ├── <app>-<preset>-<n>.md
│       ├── entrypoint/
│       │   └── <file>-<timestamp>.md
│       └── unused/
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
# MANIFEST
- Projet: qrcoder
- Date: 2025-12-01 14:30:00
- Hash: a3b5c7d9
- Fichiers: 164

# JSON INDEX
[
  {
    "fileNumber": 1,
    "fileName": "main.dart",
    "filePath": "lib/main.dart",
    "startLine": 42,
    "endLine": 67,
    "imports": ["2,lib/app.dart"],
    "importedBy": [],
    "fusionTags": ["::FUSION::json#1", "::FUSION::code#main"],
    "unused": false
  },
  ...
]

# CODE SECTIONS
::FUSION::code#1
::FUSION::import#2
lib/main.dart (26 lignes)

import 'package:flutter/material.dart';
import './app.dart';

void main() { runApp(const MyApp()); }

::FUSION::code#2
...
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

📘 **Document** : README technical ref.md
📅 **Version** : 2025-12-01
✍️ **Auteur** : Narya / Olivier Claverie
🤖 **Contributeur** : Claude (Anthropic)
