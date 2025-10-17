import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:fusionneur/core/utils/utils.dart';

/// Stratégie de nommage des exports (dossier + fichiers).
class ExportNamingStrategy {
  const ExportNamingStrategy._();

  /// Dossier racine des exports.
  /// - Priorité à FUSIONNEUR_EXPORTS_HOME si défini
  /// - Sinon <FUSION_STORAGE>/exports si dispo
  /// - Sinon ~/Documents/fusionneur/exports
  static String exportsHome() {
    // 1) Compat: FUSIONNEUR_EXPORTS_HOME
    final exOverride = Platform.environment['FUSIONNEUR_EXPORTS_HOME'];
    if (exOverride != null && exOverride.trim().isNotEmpty) {
      return PathUtils.toPosix(p.normalize(exOverride));
    }

    // 2) Compat Storage: FUSION_STORAGE
    final storageOverride = Platform.environment['FUSION_STORAGE'];
    if (storageOverride != null && storageOverride.trim().isNotEmpty) {
      return PathUtils.toPosix(
        p.join(p.normalize(storageOverride.trim()), 'exports'),
      );
    }

    // 3) Heuristique Documents (Windows/mac/Linux)
    try {
      if (Platform.isWindows) {
        final up = Platform.environment['USERPROFILE'];
        if (up != null && up.isNotEmpty) {
          return PathUtils.toPosix(
            p.join(up, 'Documents', 'fusionneur', 'exports'),
          );
        }
        final home = Platform.environment['HOMEPATH'] ?? '.';
        return PathUtils.toPosix(
          p.join(home, 'Documents', 'fusionneur', 'exports'),
        );
      }
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return PathUtils.toPosix(
          p.join(home, 'Documents', 'fusionneur', 'exports'),
        );
      }
    } catch (_) {
      // ignore
    }

    // 4) Fallback
    return PathUtils.toPosix(
      p.join('.', 'Documents', 'fusionneur', 'exports'),
    );
  }

  /// Construit le dossier d’export du projet: ~/fusionneur/exports/<projectLabel>
  static Directory projectExportDir(String projectLabel) {
    final base = exportsHome();
    final dir = Directory(p.join(base, projectLabel));
    return dir;
  }

  /// Construit le nom de fichier "<projectLabel>-<presetSlug>-<index>.md"
  static String makeFileName({
    required String projectLabel,
    required String presetName,
    required int index,
  }) {
    final presetSlug = _slugify(presetName);
    return '$projectLabel-$presetSlug-$index.md';
  }

  /// Retourne (outPath, tmpPath) prêts à l’emploi.
  static ({String outPath, String tmpPath}) makePaths({
    required Directory exportDir,
    required String fileName,
  }) {
    final outPath = PathUtils.toPosix(p.join(exportDir.path, fileName));
    return (outPath: outPath, tmpPath: '$outPath.tmp');
  }

  /// Slugification simple : minuscule, remplace non-alphanum par `-`,
  /// tronque à 64 caractères.
  static String _slugify(String input) {
    final lower = input.toLowerCase();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final compressed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
    final trimmed = compressed.replaceAll(RegExp(r'^-+|-+$'), '');
    return (trimmed.isEmpty)
        ? 'preset'
        : (trimmed.length > 64 ? trimmed.substring(0, 64) : trimmed);
  }
}
