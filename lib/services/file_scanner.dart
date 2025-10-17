import 'dart:io';

import 'package:fusionneur/core/utils/utils.dart'; // PathUtils + PathValidator

/// Scanner minimal (SRP) : énumère les fichiers sous un sous-dossier du projet.
/// - Pas de filtrage (ni .dart, ni exclusions) : à traiter ailleurs.
/// - Retourne des chemins POSIX relatifs au projet (ex: 'lib/feature/foo.dart').
class FileScanner {
  /// Liste tous les fichiers sous [projectRoot]/[subDir] (récursif).
  ///
  /// [projectRoot] : chemin du projet (dossier racine, au-dessus de lib/)
  /// [subDir]      : sous-dossier à scanner (par défaut 'lib')
  /// [followLinks] : suivre les liens symboliques (false par défaut)
  ///
  /// Retour : chemins POSIX relatifs (triés alpha).
  Future<List<String>> listFiles({
    required String projectRoot,
    String subDir = 'lib',
    bool followLinks = false,
  }) async {
    // Validation du dossier projet (et normalisation POSIX)
    final root = PathValidator.ensureExists(projectRoot);

    // Sous-dossier cible
    final subPath = PathUtils.join(root, subDir);
    final baseDir = Directory(subPath);
    if (!await baseDir.exists()) {
      // Sous-dossier absent → retourne liste vide (comportement doux)
      return <String>[];
    }

    final results = <String>[];

    await for (final entity in baseDir.list(
      recursive: true,
      followLinks: followLinks,
    )) {
      if (entity is! File) continue;

      final absPath = PathUtils.toPosix(entity.path);
      final relToProject = PathUtils.toProjectRelative(root, absPath);

      // Sécurité : ne garder que les chemins sous subDir/
      if (!_isUnderSubDir(relToProject, subDir)) continue;

      results.add(relToProject);
    }

    results.sort(); // tri alpha POSIX
    return results;
  }

  /// Vérifie que 'relPosix' commence par 'subDir/' (POSIX).
  bool _isUnderSubDir(String relPosix, String subDir) {
    final sd = subDir.endsWith('/') ? subDir : '$subDir/';
    return relPosix == subDir || relPosix.startsWith(sd);
  }
}
