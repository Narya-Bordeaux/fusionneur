import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_preset.dart';
import 'package:fusionneur/data/hive/models/hive_selection_spec.dart';
import 'package:fusionneur/pages/home/models/preset_summary.dart';

/// Service unique de gestion des presets (persistence + mapping).
class PresetService {
  static const String boxName = 'presets';

  static Future<Box<HivePreset>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<HivePreset>(boxName);
    }
    return Hive.openBox<HivePreset>(boxName);
  }

  static Future<void> put(HivePreset preset) async {
    final box = await _openBox();
    await box.put(preset.id, preset);
  }

  static Future<List<HivePreset>> findByProject(String projectId) async {
    final box = await _openBox();
    return box.values.where((p) => p.projectId == projectId).toList();
  }

  static Future<void> delete(String presetId) async {
    final box = await _openBox();
    await box.delete(presetId);
  }

  static PresetSummary toSummary(HivePreset p) => PresetSummary(
    id: p.id,
    name: p.name,
    isFavorite: p.isFavorite,
    isDefault: false,
    isArchived: false,
  );

  static Future<List<PresetSummary>> summariesByProject(String projectId) async {
    final list = await findByProject(projectId);
    return list.map(toSummary).toList();
  }

  /// Construit un HiveSelectionSpec à partir de la liste statique fournie par l’UI.
  static HiveSelectionSpec buildSpecFromIncludedPaths(
      String projectRoot,
      List<String> includedPaths,
      ) {
    final includeDirs = <String>[];
    final excludeDirs = <String>[];
    final includeFiles = <String>[];
    final excludeFiles = <String>[];

    // ⚠️ Simplification : ici, on considère que si un chemin est un dossier
    // => il va dans includeDirs. Sinon => includeFiles.
    for (final absPath in includedPaths) {
      final rel = p.relative(absPath, from: projectRoot);
      final entity = FileSystemEntity.typeSync(absPath);
      if (entity == FileSystemEntityType.directory) {
        includeDirs.add(rel);
      } else {
        includeFiles.add(rel);
      }
    }

    return HiveSelectionSpec(
      includeDirs: includeDirs,
      excludeDirs: excludeDirs,
      includeFiles: includeFiles,
      excludeFiles: excludeFiles,
    );
  }
}
