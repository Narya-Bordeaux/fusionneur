// Centralise l'initialisation de l'application :
// - Hive
// - Storage
// - Migration des projets existants

import 'package:fusionneur/data/hive/hive_initializer.dart';
import 'package:fusionneur/data/repositories/hive_project_repository.dart';
import 'package:fusionneur/services/storage.dart';

class AppInitializer {
  /// Initialise toutes les dépendances avant de lancer l'app
  static Future<void> init() async {
    // 1. Hive
    await initializeHive();

    // 2. Storage global (dans ~/Documents/fusionneur par défaut)
    await Storage.init();

    // 3. Migration des projets existants (assurer les dossiers exports/presets/entrypoint)
    final repo = HiveProjectRepository();
    await repo.migrateStorageForExistingProjects();
  }
}
