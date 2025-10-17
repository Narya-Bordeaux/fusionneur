// Détecte les fichiers .dart "probablement inutilisés".

import 'dart:io';

import 'package:fusionneur/core/utils/path_utils.dart';

class UnusedTagger {
  // main() ou Future<void> main(...)
  static final RegExp _mainRegex =
  RegExp(r'(^|\s)(?:Future<\s*void\s*>\s+|void\s+)?main\s*\(',
      multiLine: true);

  // part 'x.dart';
  static final RegExp _partRegex =
  RegExp(r'''^\s*part\s+['"]([^'"]+)['"]\s*;''', multiLine: true);

  /// Retourne l'ensemble des chemins POSIX relatifs à tagger "::FUSION::unused".
  ///
  /// [files]        : tous les fichiers (POSIX relatifs) dans le périmètre fusionné.
  /// [importsMap]   : map file -> {cibles importées} (chemins POSIX relatifs).
  /// [exportsMap]   : map file -> {cibles exportées} (barrel files).
  /// [projectRoot]  : racine absolue du projet (pour lire les sources).
  Future<Set<String>> computeUnused({
    required List<String> files,
    required Map<String, Set<String>> importsMap,
    required Map<String, Set<String>> exportsMap,
    required String projectRoot,
  }) async {
    // Limiter l’analyse aux .dart
    final dartFiles = files.where((p) => p.endsWith('.dart')).toList();
    final inScope = dartFiles.toSet();

    // 1) Cibles référencées par import/export
    final referenced = <String>{};
    for (final s in importsMap.values) {
      referenced.addAll(s.where(inScope.contains));
    }
    for (final s in exportsMap.values) {
      referenced.addAll(s.where(inScope.contains));
    }

    // 2) Cibles référencées par "part 'x.dart';"
    final partsTargets = await _collectPartsTargets(
      projectRoot: projectRoot,
      files: dartFiles,
    );
    referenced.addAll(partsTargets.where(inScope.contains));

    // 3) Fichiers qui exposent un main()
    final hasMain = await _filesWithMain(
      projectRoot: projectRoot,
      files: dartFiles,
    );

    // 4) Décision : unused = .dart qui n’est jamais référencé ET n’a pas main()
    final unused = <String>{};
    for (final p in dartFiles) {
      if (!referenced.contains(p) && !hasMain.contains(p)) {
        unused.add(p);
      }
    }
    return unused;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Internes

  /// Retourne l'ensemble des cibles référencées via `part 'x.dart';`
  Future<Set<String>> _collectPartsTargets({
    required String projectRoot,
    required List<String> files,
  }) async {
    final targets = <String>{};
    for (final src in files) {
      final abs = _join(projectRoot, src);
      final text = await _readSafe(abs);
      if (text == null) continue;

      for (final m in _partRegex.allMatches(text)) {
        final spec = m.group(1)!;
        final baseDir = _dirname(src);
        final joined = PathUtils.join(baseDir, spec);
        targets.add(_toPosix(joined));
      }
    }
    return targets;
  }

  /// Liste les fichiers qui contiennent une fonction main().
  Future<Set<String>> _filesWithMain({
    required String projectRoot,
    required List<String> files,
  }) async {
    final result = <String>{};
    for (final p in files) {
      final abs = _join(projectRoot, p);
      final text = await _readSafe(abs);
      if (text != null && _mainRegex.hasMatch(text)) {
        result.add(p);
      }
    }
    return result;
  }

  Future<String?> _readSafe(String absPath) async {
    try {
      return await File(absPath).readAsString();
    } catch (_) {
      return null;
    }
  }

  String _join(String a, String b) => _toPosix(PathUtils.join(a, b));

  String _dirname(String path) {
    final p = _toPosix(path);
    final i = p.lastIndexOf('/');
    return i < 0 ? '' : p.substring(0, i);
  }

  String _toPosix(String p) => p.replaceAll('\\', '/');
}
