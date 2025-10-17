// lib/services/project_add_service.dart
//
// Service pour ajouter un projet depuis un dossier choisi via un file picker.
// - Aucune dépendance à l'UI (pas de BuildContext).
// - Déduplication par rootPath (POSIX).
// - Lecture optionnelle de `pubspec.yaml` pour le packageName.
// - Persistance dans Hive (Boxes.projects) + préparation des dossiers (Storage).


import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fusionneur/core/utils/utils.dart'; // PathUtils + PubspecUtils
import 'package:fusionneur/data/hive/boxes.dart';
import 'package:fusionneur/data/hive/models/hive_project.dart';
import 'package:fusionneur/services/storage.dart';

class ProjectAddService {
  const ProjectAddService();

  /// Ouvre un sélecteur de dossier, crée (ou retrouve) le projet correspondant,
  /// le persiste dans Hive, puis le renvoie.
  ///
  /// Retourne `null` si l'utilisateur annule.
  Future<HiveProject?> pickAndAddProject() async {
    // 1) Sélection du dossier (dialogue natif)
    final pickedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Sélectionnez le dossier racine du projet',
      lockParentWindow: true,
    );
    if (pickedDir == null || pickedDir.trim().isEmpty) {
      return null; // cancel
    }

    // 2) Normalisation POSIX et existence
    final root = PathUtils.toPosix(pickedDir.trim());
    final dir = Directory(root);
    if (!await dir.exists()) {
      throw ArgumentError('Dossier introuvable: $root');
    }

    // 3) Déduplication par rootPath
    final existing = _findByRootPathPosix(root);
    if (existing != null) {
      return existing; // projet déjà en base
    }

    // 4) Lecture du packageName depuis pubspec.yaml (fallback: basename)
    final packageName =
        await PubspecUtils.tryReadName(root) ?? PathUtils.basename(root).toLowerCase();

    // 5) Création du modèle HiveProject
    final id = 'proj_${DateTime.now().microsecondsSinceEpoch}';
    final project = HiveProject(
      id: id,
      rootPath: root,
      packageName: packageName,
    );

    // 6) Persistance + préparation du stockage
    await Boxes.projects.put(project.id, project);
    try {
      Storage.I.ensureProjectDirs(project.slug); // exports/ & presets/
    } catch (_) {
      // Tolérant : si Storage n'est pas initialisé ici, ce n'est pas bloquant.
    }

    return project;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  /// Recherche un projet existant par rootPath (comparaison POSIX).
  HiveProject? _findByRootPathPosix(String rootPosix) {
    try {
      final posix = PathUtils.toPosix(rootPosix);
      return Boxes.projects.values.firstWhere(
            (p) => PathUtils.toPosix(p.rootPath) == posix,
      );
    } catch (_) {
      return null;
    }
  }
}
