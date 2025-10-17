import 'dart:io';
import 'package:path/path.dart' as p;

/// Résout un label projet lisible (slug) à partir du `pubspec.yaml`.
/// - Si le fichier contient une ligne `name: ...` → slug de ce nom.
/// - Sinon, fallback = slug du projectId.
/// - Utilisé pour nommer les dossiers et fichiers d’export (affichage humain).
class ProjectLabelResolver {
  const ProjectLabelResolver._();

  /// Retourne le label projet (slug).
  static String resolve({
    required String projectId,
    required String projectRoot,
  }) {
    try {
      final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
      final file = File(pubspecPath);
      if (!file.existsSync()) return _slugify(projectId);

      final lines = file.readAsLinesSync();
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final match = RegExp(r'^name\s*:\s*([A-Za-z0-9_\-\.]+)\s*$')
            .firstMatch(line);
        if (match != null) {
          final name = match.group(1)!;
          final slug = _slugify(name);
          if (slug.isNotEmpty) return slug;
        }
      }
    } catch (_) {
      // Erreur de lecture, on retombe sur projectId
    }
    return _slugify(projectId);
  }

  /// Slugifie une chaîne pour usage dans des chemins (minuscules, tirets).
  static String _slugify(String input) {
    final lower = input.toLowerCase();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final compressed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
    final trimmed = compressed.replaceAll(RegExp(r'^-+|-+$'), '');
    return (trimmed.length > 64) ? trimmed.substring(0, 64) : trimmed;
  }
}
