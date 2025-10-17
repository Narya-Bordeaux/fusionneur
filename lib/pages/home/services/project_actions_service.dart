// lib/pages/home/services/project_actions_service.dart
//
// Service utilitaire pour gérer les projets (ajout, suppression).

import 'package:flutter/material.dart';
import 'package:fusionneur/services/project_add_service.dart';
import 'package:fusionneur/data/services/preset_write_service.dart';
import 'package:fusionneur/pages/home/models/project_info.dart';

class ProjectActionsService {
  static const ProjectAddService _projectAddService = ProjectAddService();

  /// Ajoute un projet via sélection dossier → renvoie [ProjectInfo] ou null si annulé.
  static Future<ProjectInfo?> addProject(BuildContext context) async {
    final hiveProject = await _projectAddService.pickAndAddProject();
    if (hiveProject == null) return null;

    return ProjectInfo(
      id: hiveProject.id,
      packageName: hiveProject.packageName,
      rootPath: hiveProject.rootPath,
    );
  }

  /// Supprime un projet + ses presets associés.
  static Future<bool> deleteProject(BuildContext context, ProjectInfo project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet ?'),
        content: Text('Voulez-vous supprimer "${project.packageName}" ? Tous ses presets seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return false;

    await PresetWriteService.deleteAllForProject(project.id);
    return true;
  }
}
