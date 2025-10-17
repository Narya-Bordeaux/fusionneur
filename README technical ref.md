# Fusionneur — Référence technique

Ce document décrit :
- Les **modèles de données** (Hive + objets internes).
- Les **services et méthodes principales** avec leurs signatures et responsabilités.

---

## 📦 Modèles de données

### HiveProject
```dart
@HiveType(typeId: 1)
class HiveProject extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String rootPath;
  @HiveField(3) final String packageName;
  @HiveField(4) final String slug;
}
```
- Représente un projet indexé/fusionnable.
- Sert de point d’ancrage pour les presets et les runs.

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
  @HiveField(7) final bool isDefault;
  @HiveField(8) final bool isArchived;
}
```
- Définit une configuration de fusion (sélections, filtres, ordre).
- Permet de rejouer facilement une fusion.

---

### HiveRun
```dart
@HiveType(typeId: 3)
class HiveRun extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String projectId;
  @HiveField(2) final String presetId;
  @HiveField(3) final DateTime timestamp;
  @HiveField(4) final String exportPath;
  @HiveField(5) final String hash;
}
```
- Trace une exécution de fusion.
- Permet l’affichage d’un historique dans l’UI.

---

### FusionFileEntry (index JSON)
```dart
class FusionFileEntry {
  final int fileNumber;
  final String fileName;
  final String filePath;
  final int startLine;
  final int endLine;
  final List<String> imports;
  final List<String> importedBy;
  final List<String> fusionTags;
  final bool unused;
}
```
- Entrée de l’index JSON inséré dans chaque fichier fusionné.
- Sert de table de correspondance et de navigation.

---

## 🛠️ Services & méthodes principales

### Concatenator
Service central qui produit le fichier concaténé en deux passes.
```dart
Future<String> concatenate(ConcatenationOptions options)
```
- **Pass 1** : construit un index provisoire (numérotation, imports, tags).
- **Pass 2** : écrit le fichier complet avec manifest, JSON index et code.

---

### ConcatenationOptions

Objet de configuration passé au `Concatenator`.

```dart
class ConcatenationOptions {
  final String projectRoot;                 // chemin racine du projet
  final List<String> includedFiles;         // fichiers retenus (relatifs POSIX)
  final List<String> excludePatterns;       // motifs glob à exclure (*.g.dart, *.freezed.dart…)
  final bool onlyDart;                      // si true → filtre non-Dart
  final NumberingStrategy numbering;        // stratégie de numérotation (alpha, tree…)
  final bool includeManifest;               // inclut la section MANIFEST
  final bool includeJsonIndex;              // inclut l’index JSON
  final bool includeUnusedTagging;          // marque les fichiers inutilisés
  final ImportGraph importGraph;            // graphe calculé (imports et reverse)
  final String packageName;                 // issu du pubspec.yaml
}

### FusionRunner
Orchestrateur haut niveau.
```dart
Future<void> runFusion({
  required HiveProject project,
  required HivePreset preset,
  required Storage storage,
})
```
- Construit les options à partir du preset.
- Lance le `Concatenator`.
- Passe par le `HashGuardService` pour éviter doublons.
- Enregistre un `HiveRun` dans Hive.

---

### HashGuardService
```dart
Future<bool> guardAndMaybeCommitFusion(String content, Storage storage)
```
- Calcule le hash du contenu.
- Vérifie s’il existe déjà.
- Écrit dans `exports/` uniquement si nouveau.

---

### Flux alternatif (mode “entrypoint”).
```dart
Future<void> runEntrypointFusion({
required String entryFile,
required EntrypointOptions options,
required RunWriter writer,
})
```

## Explore les imports transitifs à partir d’un fichier Dart unique.
Construit un plan de fusion partielle via EntrypointPlanBuilder.
Exécute la fusion via EntrypointRunExecutor, avec un writer injecté (buildEntrypointRunWriterAdapter).
Les fichiers fusionnés sont enregistrés dans exports/entrypoints/<project>/.

## Options de nettoyage et de parcours
Ces options sont portées par le modèle interne EntryModeOptions, manipulé depuis l’UI :

```dart
class EntryModeOptions {
final bool includeImportedByOnce; // inclure les fichiers qui importent ce fichier
final bool excludeGenerated;      // exclure les *.g.dart
final bool excludeI18n;           // exclure les *.arb
}
```
## Flux complet
EntryModePage (UI)
      ↓
EntryModeController (StateNotifier)
      ↓
EntrypointFusionOrchestrator → EntrypointPlanBuilder
      ↓
EntrypointRunExecutor (writer dynamique)
      ↓
Concatenator + HashGuardService + Storage


## Différences principales avec le mode standard :

Ne scanne pas tout lib/, mais part d’un seul fichier et suit ses imports.
Permet d’activer les mêmes filtres de nettoyage (*.g.dart, *.arb).
Écrit un fichier .md autonome dans le dossier exports/entrypoints/.

---

### Storage
```dart
class Storage {
  Future<File> writeExport(String content, String projectId, DateTime ts);
  Directory get baseDir;
  Directory get exportsDir;
}
```
- Centralise les chemins (`baseDir`, `exports/`, `hive/`).
- Gère l’écriture des fichiers fusionnés.

---

## 🔄 Pipeline résumé

1. **UI ou CLI** déclenche une fusion.
2. **FusionRunner** construit les options.
3. **Concatenator** génère le contenu (2 passes).
4. **HashGuardService** vérifie unicité.
5. **Storage** écrit l’export.
6. **HiveRun** enregistre l’historique.

---
