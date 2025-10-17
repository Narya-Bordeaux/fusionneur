// lib/services/storage.dart
//
// Service centralisé des chemins de stockage (PC uniquement).
// - Base: <Documents>/fusionneur (ou $FUSION_STORAGE si défini).
// - Arbo auto: hive/, exports/, presets/, logs/, cache/, temp/.
// - Helpers pour construire des chemins d’export nommés: <app>-<preset>-<n>.txt
//
// Usage rapide :
//   final storage = await Storage.init();
//   final dir = storage.projectExportsDir('fusionneur');
//   final file = storage.buildNamedExportPath(
//     projectSlug: 'fusionneur',
//     appName: 'fusionneur',
//     presetName: 'default',
//     sequence: 3,
//   ); // => .../exports/fusionneur/fusionneur-default-3.txt

import 'dart:io';

class Storage {
  static Storage? _instance;

  final String appName; // 'fusionneur'
  final String baseDir; // absolu POSIX
  late final Directory base;

  // Sous-dossiers standards
  late final Directory hiveDir;
  late final Directory exportsDir;
  late final Directory presetsDir;
  late final Directory logsDir;
  late final Directory cacheDir;
  late final Directory tempDir;

  Storage._(this.appName, this.baseDir) {
    base = Directory(_toPosix(baseDir));
  }

  // ──────────────────────────────────────────────
  // Initialisation / singleton

  static Future<Storage> init({String appName = 'fusionneur'}) async {
    final env = Platform.environment['FUSION_STORAGE'];
    final root = (env != null && env.trim().isNotEmpty)
        ? _toPosix(env.trim())
        : _defaultDocumentsBase(appName);
    return initWithBaseDir(root, appName: appName);
  }

  static Future<Storage> initWithBaseDir(
      String baseDir, {
        String appName = 'fusionneur',
      }) async {
    final s = Storage._(appName, baseDir);
    await s._ensureLayout();
    _instance = s;
    s._logBaseDir();
    return s;
  }

  static bool get isInitialized => _instance != null;

  static Storage get I {
    final s = _instance;
    if (s == null) {
      throw StateError('Storage not initialized. Call Storage.init(...) first.');
    }
    return s;
  }

  // ──────────────────────────────────────────────
  // Helpers PUBLICS

  Directory projectExportsDir(String projectSlug) =>
      _ensureExportSubdir(exportsDir.path, projectSlug);

  Directory projectEntrypointExportsDir(String projectSlug) =>
      _ensureExportSubdir(exportsDir.path, projectSlug, 'entrypoint');

  Directory projectUnusedExportsDir(String projectSlug) =>
      _ensureExportSubdir(exportsDir.path, projectSlug, 'unused');

  Directory projectPresetsDir(String projectSlug) =>
      _ensureExportSubdir(presetsDir.path, projectSlug);

  /// Prépare tous les dossiers d’un projet (exports + presets).
  void ensureProjectDirs(String projectSlug) {
    projectExportsDir(projectSlug);
    projectPresetsDir(projectSlug);
    projectEntrypointExportsDir(projectSlug);
    projectUnusedExportsDir(projectSlug);
  }

  /// Construit un nom d’export **sans extension** : <app>-<preset>-<n>
  String buildExportBasename({
    required String appName,
    required String presetName,
    required int sequence,
  }) {
    final app = _slug(appName);
    final preset = _slug(presetName.isEmpty ? 'default' : presetName);
    final n = (sequence <= 0) ? 1 : sequence;
    return '$app-$preset-$n';
  }

  /// Construit le chemin complet de l’export :
  /// <base>/exports/<projectSlug>/<app>-<preset>-<n>.txt
  String buildNamedExportPath({
    required String projectSlug,
    required String appName,
    required String presetName,
    required int sequence,
    String extension = 'txt',
  }) {
    final dir = projectExportsDir(projectSlug);
    final base = buildExportBasename(
      appName: appName,
      presetName: presetName,
      sequence: sequence,
    );
    final ext = _sanitizeExtension(extension);
    return '${dir.path}/$base.$ext';
  }

  // ──────────────────────────────────────────────
  // Internes

  Directory _ensureExportSubdir(String basePath, String projectSlug,
      [String? subdir]) {
    final safe = _slug(projectSlug);
    final path = (subdir == null)
        ? '$basePath/$safe'
        : '$basePath/$safe/$subdir';
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static String _defaultDocumentsBase(String appName) {
    final docs = _userDocumentsDir();
    return '$docs/${_slug(appName)}';
  }

  Future<void> _ensureLayout() async {
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    hiveDir = Directory('${base.path}/hive');
    exportsDir = Directory('${base.path}/exports');
    presetsDir = Directory('${base.path}/presets');
    logsDir = Directory('${base.path}/logs');
    cacheDir = Directory('${base.path}/cache');
    tempDir = Directory('${base.path}/temp');

    for (final d in [hiveDir, exportsDir, presetsDir, logsDir, cacheDir, tempDir]) {
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    }
  }

  void _logBaseDir() {
    stdout.writeln('[storage] baseDir = ${base.path}');
    stdout.writeln('[storage] hive    = ${hiveDir.path}');
    stdout.writeln('[storage] exports = ${exportsDir.path}');
  }

  static String _userDocumentsDir() {
    try {
      if (Platform.isWindows) {
        final up = Platform.environment['USERPROFILE'];
        if (up != null && up.isNotEmpty) {
          return _toPosix('$up/Documents');
        }
        final home = Platform.environment['HOMEPATH'] ?? '';
        return _toPosix('$home/Documents');
      }
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw StateError('HOME not set');
      }
      return _toPosix('$home/Documents');
    } catch (_) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      return _toPosix('$home/Documents');
    }
  }

  static String _sanitizeExtension(String extension) {
    final e = extension.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return e.isEmpty ? 'txt' : e;
  }

  static String _slug(String s) {
    final p = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]+'), '-');
    return p.replaceAll(RegExp(r'-{2,}'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  static String _toPosix(String p) => p.replaceAll('\\', '/');
}
