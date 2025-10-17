import 'dart:io';

import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:fusionneur/services/file_scanner.dart';

/// Spécifie ce qu'on veut inclure/exclure avant filtrage .dart/.g.dart/etc.
/// - includeDirs  : dossiers (relatifs au projectRoot) à scanner récursivement.
/// - excludeDirs  : dossiers à exclure entièrement (récursif).
/// - includeFiles : fichiers à inclure explicitement (chemins relatifs).
/// - excludeFiles : fichiers à exclure explicitement (chemins relatifs).
///
/// Remarques :
/// - Tous les chemins sont traités en POSIX.
/// - Les exclusions priment sur les inclusions de dossiers,
///   mais PAS sur includeFiles (un fichier explicitement inclus est conservé).
class SelectionSpec {
  final List<String> includeDirs;
  final List<String> excludeDirs;
  final List<String> includeFiles;
  final List<String> excludeFiles;

  const SelectionSpec({
    this.includeDirs = const ['lib'],
    this.excludeDirs = const [],
    this.includeFiles = const [],
    this.excludeFiles = const [],
  });

  SelectionSpec copyWith({
    List<String>? includeDirs,
    List<String>? excludeDirs,
    List<String>? includeFiles,
    List<String>? excludeFiles,
  }) {
    return SelectionSpec(
      includeDirs: includeDirs ?? this.includeDirs,
      excludeDirs: excludeDirs ?? this.excludeDirs,
      includeFiles: includeFiles ?? this.includeFiles,
      excludeFiles: excludeFiles ?? this.excludeFiles,
    );
  }
}

/// Résout la sélection : scanne chaque dossier inclus,
/// applique les exclusions de dossiers/fichiers, ajoute les fichiers explicitement inclus,
/// et retourne une liste POSIX **sans doublons**, triée alpha.
class FileSelectionResolver {
  final FileScanner _scanner;

  FileSelectionResolver({FileScanner? scanner})
      : _scanner = scanner ?? FileScanner();

  Future<List<String>> resolve({
    required String projectRoot,
    required SelectionSpec spec,
  }) async {
    // Normaliser en POSIX
    final includeDirs = spec.includeDirs.map(PathUtils.toPosix).toList();
    final excludeDirs = spec.excludeDirs.map(_ensureDirPrefix).toSet();
    final includeFiles = spec.includeFiles.map(PathUtils.toPosix).toSet();
    final excludeFiles = spec.excludeFiles.map(PathUtils.toPosix).toSet();

    // Scanner chaque dossier inclus (doucement si dossier absent → liste vide)
    final acc = <String>{};
    for (final dir in includeDirs) {
      final listed = await _scanner.listFiles(projectRoot: projectRoot, subDir: dir);
      for (final p in listed) {
        // exclure si sous un dossier exclu
        if (_isUnderAny(excludeDirs, p)) continue;
        // exclure si fichier explicitement exclu
        if (excludeFiles.contains(p)) continue;
        acc.add(p);
      }
    }

    // Ajouter les fichiers explicitement inclus (s'ils existent)
    for (final rel in includeFiles) {
      final abs = PathUtils.join(projectRoot, rel);
      if (await File(abs).exists()) {
        // même si sous un dossier exclu, includeFiles prend le dessus
        acc.add(rel);
      }
    }

    final out = acc.toList()..sort();
    return out;
  }

  /// Vrai si `path` est sous au moins un des dossiers [dirs] (POSIX).
  bool _isUnderAny(Set<String> dirs, String path) {
    final p = PathUtils.toPosix(path);
    for (final d in dirs) {
      if (PathUtils.isUnder(d, p) || p == d.replaceAll(RegExp(r'/$'), '')) {
        return true;
      }
    }
    return false;
  }

  /// Garantit un trailing slash pour un dossier (POSIX).
  String _ensureDirPrefix(String d) {
    final posix = PathUtils.toPosix(d);
    return posix.endsWith('/') ? posix : '$posix/';
  }
}
