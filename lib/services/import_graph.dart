// lib/services/import_graph.dart
//
// Service d'analyse des imports/exports internes au projet.
// Retourne des graphes simples: file -> set(files ciblés).
//
// Hypothèses / Bornes :
// - On ne suit pas les "show/hide/as" (on lit juste la cible de l'import/export).
// - On ignore "dart:" et "package:" d'autres packages.
// - Les chemins retournés sont POSIX relatifs à la racine projet (ex: lib/foo/bar.dart).
// - On ne renvoie que les cibles qui sont dans la liste "files" fournie (périmètre de fusion).

import 'dart:io';
import 'package:fusionneur/core/utils/utils.dart'; // PathUtils + PathValidator

// Debug local : activer pour voir la résolution des imports dans la console.
const bool kImportGraphDebug = true;

void _debug(String msg) {
  if (kImportGraphDebug) print(msg);
}

class ImportGraph {
  // Regex simples pour import/export en tête de ligne (espaces acceptés).
  static final RegExp _importRe =
  RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''', multiLine: true);
  static final RegExp _exportRe =
  RegExp(r'''^\s*export\s+['"]([^'"]+)['"]''', multiLine: true);

  /// Construit la map des imports internes.
  Future<Map<String, Set<String>>> computeImports({
    required String projectRoot,
    required List<String> files,
    required String packageName,
  }) async {
    final normalizedRoot = PathUtils.normalize(projectRoot);
    final inScope = files.map(PathUtils.normalize).toSet(); // périmètre retenu
    final result = <String, Set<String>>{};

    for (final rawSrc in files) {
      if (!rawSrc.endsWith('.dart')) continue; // uniquement les fichiers Dart

      final src = PathUtils.normalize(rawSrc);
      final abs = PathUtils.join(normalizedRoot, src);
      final text = await _readSafe(abs);
      if (text == null) continue;

      final matches = _importRe.allMatches(text);
      for (final m in matches) {
        final spec = m.group(1)!;
        final resolved = _resolveToPosixPath(
          projectRoot: normalizedRoot,
          currentFile: src,
          importOrExport: spec,
          packageName: packageName,
        );

        if (resolved == null) {
          _debug('[ImportGraph] $src ignore "$spec" (résolution nulle)');
          continue;
        }

        final normalizedResolved = PathUtils.normalize(resolved);

        if (!inScope.contains(normalizedResolved)) {
          _debug('[ImportGraph] $src → $normalizedResolved (HORS périmètre)');
          continue;
        }

        (result[src] ??= <String>{}).add(normalizedResolved);
        _debug('[ImportGraph] $src → $normalizedResolved (OK)');
      }
    }
    return result;
  }

  /// Construit la map des exports internes (barrel files).
  Future<Map<String, Set<String>>> computeExports({
    required String projectRoot,
    required List<String> files,
    required String packageName,
  }) async {
    final normalizedRoot = PathUtils.normalize(projectRoot);
    final inScope = files.map(PathUtils.normalize).toSet();
    final result = <String, Set<String>>{};

    for (final rawSrc in files) {
      if (!rawSrc.endsWith('.dart')) continue;
      final src = PathUtils.normalize(rawSrc);
      final abs = PathUtils.join(normalizedRoot, src);
      final text = await _readSafe(abs);
      if (text == null) continue;

      final matches = _exportRe.allMatches(text);
      for (final m in matches) {
        final spec = m.group(1)!;
        final resolved = _resolveToPosixPath(
          projectRoot: normalizedRoot,
          currentFile: src,
          importOrExport: spec,
          packageName: packageName,
        );

        if (resolved == null) {
          _debug('[ImportGraph] $src ignore export "$spec"');
          continue;
        }

        final normalizedResolved = PathUtils.normalize(resolved);

        if (!inScope.contains(normalizedResolved)) {
          _debug('[ImportGraph] $src export → $normalizedResolved (HORS périmètre)');
          continue;
        }

        (result[src] ??= <String>{}).add(normalizedResolved);
        _debug('[ImportGraph] $src export → $normalizedResolved (OK)');
      }
    }
    return result;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  String? _resolveToPosixPath({
    required String projectRoot,
    required String currentFile,
    required String importOrExport,
    required String packageName,
  }) {
    final spec = importOrExport.trim();

    // 1) Cas "dart:..."
    if (spec.startsWith('dart:')) {
      _debug('[ImportGraph] IGNORE dart:$spec');
      return null;
    }

    // 2) Cas "package:..."
    if (spec.startsWith('package:')) {
      final rest = spec.substring('package:'.length);
      final slash = rest.indexOf('/');
      if (slash <= 0) {
        _debug(
            '[ImportGraph] Rejet import package sans "/" : "$rest" (attendu: $packageName/<rel>)');
        return null;
      }
      final pkg = rest.substring(0, slash);
      final pathInPkg = rest.substring(slash + 1);

      if (pkg != packageName) {
        _debug(
            '[ImportGraph] Rejet import package:$pkg/$pathInPkg (attendu: $packageName)');
        return null;
      }

      final mapped = PathUtils.normalize('lib/$pathInPkg');
      _debug(
          '[ImportGraph] RESOLVED package:$pkg/$pathInPkg (pkg match=$packageName) → $mapped');
      return mapped;
    }

    // 3) Cas relatifs
    final baseDir = PathUtils.dirname(currentFile);
    final joined = PathUtils.join(baseDir, spec);
    final posix = PathUtils.normalize(joined);

    _debug('[ImportGraph] RESOLVED relatif $spec depuis $currentFile → $posix');
    return posix;
  }

  Future<String?> _readSafe(String absPath) async {
    try {
      return await File(absPath).readAsString();
    } catch (_) {
      return null;
    }
  }
}
