# CLAUDE.md — Fusionneur

## Vue d'ensemble

**Fusionneur** est une application Flutter/Dart de bureau qui fusionne tous les fichiers d'un projet en un seul document Markdown enrichi, conçu pour être partagé avec des IA. Le fichier produit contient :
- Un **manifest** (métadonnées du projet et du preset)
- Un **index JSON** (numéros de fichiers, chemins, imports, plages de lignes)
- Le **code source** de chaque fichier, délimité par des tags `::FUSION::`

**Trois modes de fusion :**
- **Mode Projet** — fusion complète via un preset (sélection, ordre, filtres)
- **Mode Entrypoint** — fusion partielle à partir d'un fichier Dart et de ses imports transitifs
- **Mode Unused Files** - fusion des fichiers qui ne sont pas importés dans les autres fichiers de l'app.

**CLI disponible** (`bin/cli.dart`) pour exécuter sans UI.

---

## Commandes essentielles

```bash
# Lancer l'application
flutter run

# Lancer les tests
flutter test

# Génération de code (adaptateurs Hive)
dart run build_runner build --delete-conflicting-outputs

# CLI (fusion sans UI)
dart run bin/cli.dart --project <chemin> --preset <id> [--dry-run]

# Linter
flutter analyze
```

---

## Architecture

```
lib/
├── core/               # Services transversaux (constants, glob, json_models, utils)
├── data/
│   ├── hive/           # Modèles Hive + adaptateurs générés
│   ├── repositories/   # CRUD abstraits (ProjectRepository, PresetRepository)
│   ├── providers/      # Providers Riverpod
│   └── services/       # Lecture/écriture presets & runs
├── services/           # Moteur de fusion (business logic)
│   ├── concatenator.dart          # Orchestrateur 2 passes
│   ├── concatenator_parts/        # 15+ sous-services factorisés
│   ├── import_graph.dart          # Analyse des imports/exports Dart
│   ├── file_scanner.dart          # Scan récursif
│   ├── file_filter.dart           # Filtrage glob
│   ├── hash/                      # HashGuardService (déduplication CRC32)
│   ├── fusion/                    # FusionGenerator, DedupService
│   └── storage.dart               # Gestion centralisée des chemins
└── pages/
    ├── home/           # Sélection projet/preset, lancement fusion
    ├── entry_mode/     # Fusion par entrypoint
    ├── preset/         # Éditeur de presets
    └── admin/          # Debug Hive
```

**Patterns utilisés :**
| Pattern                  | Où                                                                   |
|--------------------------|----------------------------------------------------------------------|
| Repository Pattern       | `data/repositories/` — abstraction Hive                              |
| Service Locator          | `Storage.I` — accès global aux chemins                               |
| Dependency Injection     | Constructeurs avec params optionnels (testabilité)                   |
| StateNotifier + Riverpod | State management UI                                                  |
| Two-Pass Processing      | `Concatenator` : index provisoire (pass 1) → index finalisé (pass 2) |
| Strategy Pattern         | `FileOrderingPolicy`, `NumberingStrategy`                            |

---

## Fichiers clés

| Fichier                                     | Rôle                                         |
|---------------------------------------------|----------------------------------------------|
| `lib/services/concatenator.dart`            | Moteur principal de fusion (2 passes)        |
| `lib/services/storage.dart`                 | Chemins d'export (`~/Documents/fusionneur/`) |
| `lib/services/import_graph.dart`            | Calcul des imports et reverse-imports        |
| `lib/services/hash/hash_guard_service.dart` | Déduplication par hash CRC32                 |
| `lib/core/json_models.dart`                 | `FusionFileEntry`, `FusionIndex`             |
| `lib/core/constants.dart`                   | Tags `::FUSION::`, constantes globales       |
| `lib/data/hive/models/`                     | `HiveProject`, `HivePreset`, `HiveRun`, etc. |
| `bin/cli.dart`                              | Point d'entrée CLI                           |
| `lib/pages/entry_mode/`                     | Mode entrypoint complet                      |
| `docs/README_technical_ref.md`              | Référence technique complète                 |

---

## Conventions

### Langue

- **Noms de code** (méthodes, variables, classes, fichiers) : **anglais**
- **Commentaires** (`///` et `//`) : **français**
- Exception : termes techniques courants restent en anglais dans les commentaires (HTTP, JSON, hash, API, Hive, etc.)

```dart
// ✅ Correct
/// Sauvegarde le fichier fusionné dans le dossier exports.
Future<void> saveExport(String path, Uint8List bytes) async { ... }

// ❌ Incorrect
/// Save the fused file in the exports folder.
Future<void> sauvegarderExport(String chemin, Uint8List octets) async { ... }
```

### Placement des fichiers

- **Local à une feature** (`pages/<feature>/widgets/` ou `services/`) si utilisé dans **1 seule page**
- **Partagé** (`core/` ou `services/`) si utilisé dans **2+ features** ou générique

---

## Stack technique

| Technologie                   | Version         | Usage                           |
|-------------------------------|-----------------|---------------------------------|
| Dart SDK                      | ^3.8.1          | Langage                         |
| Flutter                       | SDK             | Framework UI multiplateforme    |
| Hive + hive_flutter           | ^2.2.3 / ^1.1.0 | Persistance locale              |
| flutter_riverpod              | ^3.0.0          | State management                |
| file_picker                   | ^10.3.3         | Sélection de fichiers           |
| path_provider                 | ^2.1.2          | Chemins système                 |
| crypto                        | ^3.0.3          | Hash CRC32                      |
| uuid                          | ^4.5.1          | Génération d'identifiants       |
| build_runner + hive_generator | dev             | Génération des adaptateurs Hive |

---

## À ne pas faire

- Ne jamais écrire de code en français (noms de variables, méthodes, classes)
- Ne jamais appeler `Icons.*` directement — utiliser `AppIcon`
- Ne jamais déroger à l'architecture "pour gagner du temps" sans justification documentée
- Ne pas créer de "quick fix" dans la couche UI qui appartient à un service
- Ne pas mélanger anglais inventé et français dans les commentaires (`sauvegarderImage` ❌, `saveImage` ✅)
