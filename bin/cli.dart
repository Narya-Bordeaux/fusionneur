// bin/cli.dart
//
// CLI pour générer un fichier fusionné avec HashGuardService.
// + Mode additionnel : -unused → génère la liste des fichiers Dart non utilisés.
//
// Stocke par défaut dans le dossier géré par Storage :
//   <Documents>/fusionneur/exports/<projectSlug>/<app>-<preset>-<n>.md
// et le fichier temporaire dans :
//   <Documents>/fusionneur/temp/<app>-<preset>-<n>.md.tmp

import 'dart:io';

import 'package:fusionneur/services/hash/hash_guard_service.dart';
import 'package:fusionneur/services/concatenator.dart';
import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart';
import 'package:fusionneur/services/storage.dart';

void main(List<String> args) async {
  final parsed = _Args.parse(args);

  // ─────────────────────────────────────────────────────────────
  // MODE SPECIAL : UNUSED FILES
  if (parsed.unused) {
    final projectRoot = parsed.project ?? Directory.current.path;
    final appName =
        await _tryReadPubspecName(projectRoot) ?? _basename(projectRoot);

    final unusedFiles = await _findUnusedFiles(projectRoot, appName);

    final storage = await Storage.init();
    final outFile =
    File(PathUtils.join(storage.base.path, 'unused_files.txt'));
    await outFile.writeAsString(unusedFiles.join('\n'));

    stdout.writeln('📋 Unused files: ${unusedFiles.length}');
    stdout.writeln('→ Liste écrite dans ${outFile.path}');
    exit(0);
  }

  // ─────────────────────────────────────────────────────────────
  // MODE NORMAL : FUSION
  final projectRoot = parsed.project ?? Directory.current.path;

  final appName =
      await _tryReadPubspecName(projectRoot) ?? _basename(projectRoot);

  final presetName = 'default';

  final storage = await Storage.init();

  final projectSlug = _slug(appName);

  final nextSeq = await _nextSequence(
    storage: storage,
    projectSlug: projectSlug,
    appName: appName,
    presetName: presetName,
  );

  final defaultOut = storage.buildNamedExportPath(
    projectSlug: projectSlug,
    appName: appName,
    presetName: presetName,
    sequence: nextSeq,
    extension: 'md',
  );

  final outPath = parsed.out ?? defaultOut;

  final defaultTmp = PathUtils.join(
    storage.tempDir.path,
    '${PathUtils.basename(outPath)}.tmp',
  );
  final tmpPath = parsed.temp ?? defaultTmp;

  final selection = SelectionSpec(
    includeDirs: const ['lib'],
    includeFiles: parsed.withPubspec ? const ['pubspec.yaml'] : const [],
  );

  final options = ConcatenationOptions(selectionSpec: selection);

  final guard = HashGuardService();

  stdout.writeln('→ Running hash-guarded fusion');
  stdout.writeln('  project : $projectRoot');
  stdout.writeln('  app     : $appName');
  stdout.writeln('  preset  : $presetName');
  stdout.writeln('  seq     : $nextSeq');
  stdout.writeln('  out     : $outPath');
  stdout.writeln('  temp    : $tmpPath');
  stdout.writeln('  force   : ${parsed.force}');
  stdout.writeln('  dryRun  : ${parsed.dryRun}');
  if (parsed.withPubspec) stdout.writeln('  include : pubspec.yaml');
  stdout.writeln('');

  try {
    final result = await guard.guardAndMaybeCommitFusion(
      projectRoot: projectRoot,
      finalPath: outPath,
      tempPath: tmpPath,
      options: options,
      force: parsed.force,
      dryRun: parsed.dryRun,
    );

    switch (result.decision) {
      case HashGuardDecision.skippedIdentical:
        stdout.writeln(
            '✅ Identical — fusion skipped (hash ${result.currentHash}).');
        break;
      case HashGuardDecision.committed:
        stdout.writeln(
            '✅ Changes detected — file written.\n'
                '    old: ${result.previousHash ?? "(none)"}\n'
                '    new: ${result.currentHash}\n'
                '    → ${result.finalPath}');
        break;
      case HashGuardDecision.dryRunDifferent:
        stdout.writeln(
            'ℹ️  Dry-run: changes detected — nothing written.\n'
                '    old: ${result.previousHash ?? "(none)"}\n'
                '    new: ${result.currentHash}');
        exit(10);
    }
  } catch (e, st) {
    stderr.writeln('❌ Error: $e');
    stderr.writeln(st);
    exit(1);
  }
}

// ─────────────────────────────────────────────────────────────
// UNUSED DETECTOR

Future<List<String>> _findUnusedFiles(
    String projectRoot, String packageName) async {
  final libDir = Directory(PathUtils.join(projectRoot, 'lib'));
  if (!libDir.existsSync()) return [];

  final files = <String>[];
  final imported = <String>{};

  await for (var entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final rel =
      PathUtils.toPosix(PathUtils.toProjectRelative(projectRoot, entity.path));
      files.add(rel);

      final content = await entity.readAsString();
      final regex = RegExp(
          r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
          multiLine: true);
      for (final m in regex.allMatches(content)) {
        final spec = m.group(2)!;

        String? resolved;
        if (spec.startsWith('package:$packageName/')) {
          resolved = 'lib/' + spec.substring(('package:$packageName/').length);
        } else if (spec.startsWith('./') || spec.startsWith('../')) {
          final dir = PathUtils.dirname(rel);
          resolved = PathUtils.toPosix(PathUtils.join(dir, spec));
        }
        if (resolved != null) {
          imported.add(resolved);
        }
      }
    }
  }

  final unused = files.where((f) => !imported.contains(f)).toList();
  return unused;
}

// ─────────────────────────────────────────────────────────────
// ARGUMENTS

class _Args {
  final String? project;
  final String? out;
  final String? temp;
  final bool dryRun;
  final bool force;
  final bool withPubspec;
  final bool unused;

  _Args({
    required this.project,
    required this.out,
    required this.temp,
    required this.dryRun,
    required this.force,
    required this.withPubspec,
    required this.unused,
  });

  static _Args parse(List<String> args) {
    String? project;
    String? out;
    String? temp;
    bool dry = false;
    bool force = false;
    bool withPubspec = true;
    bool unused = false;

    for (int i = 0; i < args.length; i++) {
      final a = args[i];
      switch (a) {
        case '--project':
          if (i + 1 < args.length) project = args[++i];
          break;
        case '--out':
          if (i + 1 < args.length) out = args[++i];
          break;
        case '--temp':
          if (i + 1 < args.length) temp = args[++i];
          break;
        case '--dry-run':
          dry = true;
          break;
        case '--force':
          force = true;
          break;
        case '--with-pubspec':
          withPubspec = true;
          break;
        case '-unused':
        case '--unused':
          unused = true;
          break;
        case '-h':
        case '--help':
          _printUsage();
          exit(0);
        default:
          if (!a.startsWith('-') && project == null) {
            project = a;
          } else {
            stderr.writeln('Unknown argument: $a');
            _printUsage();
            exit(64);
          }
      }
    }

    return _Args(
      project: project,
      out: out,
      temp: temp,
      dryRun: dry,
      force: force,
      withPubspec: withPubspec,
      unused: unused,
    );
  }
}

void _printUsage() {
  stdout.writeln('Fusionneur CLI — Hash-guarded fusion (Storage-based paths)');
  stdout.writeln('Usage:');
  stdout.writeln(
      '  dart run bin/cli.dart [--project <path>] [--out <path>] [--temp <path>] [--dry-run] [--force] [--with-pubspec]');
  stdout.writeln('  dart run bin/cli.dart -unused   (liste les fichiers inutilisés)');
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run bin/cli.dart');
  stdout.writeln('  dart run bin/cli.dart --with-pubspec');
  stdout.writeln('  dart run bin/cli.dart --project C:/dev/my_app --dry-run');
  stdout.writeln('  dart run bin/cli.dart --force');
  stdout.writeln('  dart run bin/cli.dart -unused');
}

// ─────────────────────────────────────────────────────────────
// HELPERS

String _basename(String path) {
  final p = path.replaceAll('\\', '/');
  final i = p.lastIndexOf('/');
  return i >= 0 ? p.substring(i + 1) : p;
}

Future<String?> _tryReadPubspecName(String projectRoot) async {
  try {
    final pubspec = File(PathUtils.join(projectRoot, 'pubspec.yaml'));
    if (!await pubspec.exists()) return null;
    final content = await pubspec.readAsLines();
    final re = RegExp(r'^\s*name\s*:\s*([a-zA-Z0-9_]+)\s*$');
    for (final line in content) {
      final m = re.firstMatch(line);
      if (m != null) return m.group(1);
    }
  } catch (_) {}
  return null;
}

String _slug(String s) {
  final p = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]+'), '-');
  return p.replaceAll(RegExp(r'-{2,}'), '-').replaceAll(RegExp(r'^-|-$'), '');
}

Future<int> _nextSequence({
  required Storage storage,
  required String projectSlug,
  required String appName,
  required String presetName,
}) async {
  final dir = storage.projectExportsDir(projectSlug);
  final app = _slug(appName);
  final preset = _slug(presetName.isEmpty ? 'default' : presetName);
  final re = RegExp('^$app-$preset-(\\d+)\\.md\$');

  int maxN = 0;
  try {
    final entries =
    dir.existsSync() ? dir.listSync() : const <FileSystemEntity>[];
    for (final e in entries) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.isEmpty
          ? e.path.split(Platform.pathSeparator).last
          : e.uri.pathSegments.last;
      final m = re.firstMatch(name);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > maxN) maxN = n;
      }
    }
  } catch (_) {}
  return maxN + 1;
}
