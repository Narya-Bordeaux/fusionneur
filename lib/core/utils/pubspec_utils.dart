// lib/core/utils/pubspec_utils.dart
//
// Utilitaires pour lire des informations depuis pubspec.yaml.

import 'dart:io';
import 'package:fusionneur/core/utils/path_utils.dart';

class PubspecUtils {
  /// Essaie de lire le champ `name:` dans pubspec.yaml
  static Future<String?> tryReadName(String projectRoot) async {
    try {
      final pubspec = File(PathUtils.join(projectRoot, 'pubspec.yaml'));
      if (!await pubspec.exists()) return null;

      final content = await pubspec.readAsLines();
      final re = RegExp(r'^\s*name\s*:\s*([a-zA-Z0-9_]+)\s*$');

      for (final line in content) {
        final m = re.firstMatch(line);
        if (m != null) return m.group(1);
      }
    } catch (_) {
      // erreurs silencieuses, retourne null
    }
    return null;
  }
}
