# Fusionneur

**Fusionneur** est un outil Flutter/Dart qui fusionne tous les fichiers d’un projet dans un seul fichier enrichi.  
Il permet d’analyser, partager et archiver un projet de manière simplifiée, tout en conservant les informations d’organisation (imports, dépendances, structure).

---

## 🚀 Fonctionnalités principales

- **Fusion complète de projets Flutter** → regroupe tous les fichiers sources dans un document unique.
- **Index JSON intégré** → chaque fichier est numéroté, avec son chemin, ses imports et ses dépendances inverses.
- **Navigation rapide** grâce à des tags (`::FUSION::code`, `::FUSION::import`, `::FUSION::imported`).
- **Gestion des presets** (Hive) → sauvegarde et réutilisation de sélections de fichiers.
- **Historique des fusions** → accès aux dernières exécutions depuis l’UI.
- **Modes d’entrée multiples** :
    - **Mode Projet** : fusion complète via un preset.
    - **Mode Entrypoint** : fusion partielle à partir d’un fichier Dart et de ses imports.
- **CLI intégrée** (`bin/cli.dart`) → exécution sans UI avec options `--project`, `--preset`, `--dry-run`.

---

## 📦 Stockage & persistance

- **Hive** : stockage local pour les projets, presets et historiques (`HiveProject`, `HivePreset`, `HiveRun`).
- **Exports** : les fusions sont enregistrées dans un dossier `exports/` avec un horodatage et un hash.
- **Commentaires** : possibilité d’ajouter des notes globales ou par fichier, stockées dans un JSON séparé (ne modifie pas le hash).

---

## 🛠️ Architecture

### 1. Données (`lib/data/`)
- **Hive models** : `HiveProject`, `HivePreset`, `HiveRun`, etc.
- **Repositories** : abstraction d’accès aux données (`ProjectRepository`, `PresetRepository`).
- **Services** : lecture/écriture de presets et runs.

### 2. Moteur (`lib/services/`)
- **Concatenator** : moteur de fusion (2 passes).
- **Parts** : sous-services factorisés (manifest, JSON index, code sections, tags).
- **ImportGraph** : calcule imports et reverse imports.
- **HashGuardService** : évite les doublons en comparant les hash.
- **Storage** : écrit les exports et gère les chemins.

### 3. Interface
- **UI Flutter (`lib/pages/`)** :
    - `HomePage` : sélection projet/preset et lancement fusion.
    - `PresetEditorPage` : gestion des presets.
    - `EntryModePage` : fusion par entrypoint.
- **CLI (`bin/cli.dart`)** :
    - Arguments : `--project`, `--preset`, `--dry-run`.
    - Réutilise le pipeline principal (`FusionRunner`).

---

## 📐 Modèles Hive

### `HiveProject`
- `id` : identifiant unique.
- `name` : nom lisible.
- `rootPath` : chemin racine du projet.
- `packageName` : nom du package.

### `HivePreset`
- `id`, `projectId`, `name`.
- `hiveSelectionSpec` : patterns de sélection.
- `hiveFileOrderingPolicy` : ordre des fichiers.
- `hiveFilterOptions` : exclusions glob.
- Flags : `isFavorite`, `isDefault`, `isArchived`.

### `HiveRun`
- Trace une exécution (preset, projet, horodatage, hash export).

---

## 🔄 Flux de traitement

### Mode Projet
```
HomePage → choix projet/preset
    ↓
FusionRunner (orchestration)
    ↓
ImportGraph (analyse dépendances)
    ↓
Concatenator (2 passes)
    ↓
HashGuardService + Storage
    ↓
HiveRun (historique UI)
```

### Mode Entrypoint
```
EntryModePage → choix d’un fichier
    ↓
EntrypointPlanBuilder (explore imports transitifs)
    ↓
EntrypointFusionOrchestrator
    ↓
EntrypointRunExecutor (writer injecté)
    ↓
Storage + HiveRun
```

---

## 🧭 Index JSON intégré

Chaque entrée du fichier fusionné suit le modèle `FusionFileEntry` :
- `fileNumber`, `fileName`, `filePath`.
- `startLine`, `endLine`.
- `imports`, `importedBy`.
- `fusionTags` (navigation rapide).
- `unused` (flag de non-utilisation).

Les entrées sont regroupées dans un `FusionIndex`.

---

## 🖥️ Utilisation

### Lancer l’application Flutter
```bash
flutter run
```

### Lancer la CLI
```bash
dart run bin/cli.dart --project <path> --preset <id> [--dry-run]
```

---


