import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:fusionneur/data/hive/models/hive_preset.dart';
import 'package:fusionneur/data/hive/models/hive_file_ordering_policy.dart';
import 'package:fusionneur/data/hive/models/hive_filter_options.dart';
import 'package:fusionneur/pages/home/services/preset_service.dart';
import 'package:fusionneur/data/repositories/preset_repository.dart';
import 'package:fusionneur/data/repositories/hive_project_repository.dart';
import 'package:fusionneur/pages/preset/preset_editor_page.dart';

class PresetUiActions {
  static Future<void> createPreset(BuildContext context, String projectRoot) async {
    final repo = HiveProjectRepository();
    final project = await repo.findByRootPath(projectRoot);
    if (project == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresetEditorPage(
          projectRoot: projectRoot,
          onCancel: () => Navigator.of(context).pop(),
          onSave: ({required String name, required bool favorite, required List<String> includedPaths}) async {
            final spec = PresetService.buildSpecFromIncludedPaths(projectRoot, includedPaths);
            final preset = HivePreset(
              id: const Uuid().v4(),
              projectId: project.id,
              name: name,
              isFavorite: favorite,
              hiveSelectionSpec: spec,
              hiveFileOrderingPolicy: HiveFileOrderingPolicy(), // valeur par défaut
              hiveFilterOptions: HiveFilterOptions(), // valeur par défaut
            );
            await PresetService.put(preset);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Demande une confirmation avant de supprimer un preset.
  /// Retourne `true` si le preset a été supprimé, `false` sinon.
  static Future<bool> confirmAndDelete(
      BuildContext context, HivePreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le preset ?'),
        content: Text('Voulez-vous vraiment supprimer le preset "${preset.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      await PresetRepository.delete(preset.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preset "${preset.name}" supprimé.')),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
      return false;
    }
  }

  static Future<void> updatePreset(BuildContext context, HivePreset preset, String projectRoot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresetEditorPage(
          projectRoot: projectRoot,
          initialName: preset.name,
          initialFavorite: preset.isFavorite,
          onCancel: () => Navigator.of(context).pop(),
          onSave: ({required String name, required bool favorite, required List<String> includedPaths}) async {
            final spec = PresetService.buildSpecFromIncludedPaths(projectRoot, includedPaths);
            final updated = HivePreset(
              id: preset.id,
              projectId: preset.projectId,
              name: name,
              isFavorite: favorite,
              hiveSelectionSpec: spec,
              hiveFileOrderingPolicy: preset.hiveFileOrderingPolicy,
              hiveFilterOptions: preset.hiveFilterOptions,
            );
            await PresetService.put(updated);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
