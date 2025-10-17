// lib/pages/home/services/unused_run_service.dart
//
// Service pour générer un fichier de fusion avec uniquement les fichiers unused.

import 'package:fusionneur/services/hash/hash_guard_service.dart';
import 'package:fusionneur/services/concatenator.dart';
import 'package:fusionneur/services/storage.dart';
import 'package:fusionneur/core/utils/utils.dart';

import 'package:fusionneur/services/file_scanner.dart';
import 'package:fusionneur/services/import_graph.dart';
import 'package:fusionneur/services/concatenator_parts/unused_tagger.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart';

class UnusedRunService {
  /// Exécute une fusion "unused" et retourne le chemin du fichier généré.
  static Future<String?> run({
    required String projectRoot,
    required String projectSlug,
    required String packageName,
  }) async {
    // 1) Scanner tous les fichiers du projet
    final scanner = FileScanner();
    final allFiles = await scanner.listFiles(
      projectRoot: projectRoot,
      subDir: 'lib',
    );

    // ⚠️ Correction : ne plus transformer deux fois
    final normalizedFiles = allFiles; // déjà relatifs et POSIX
    print('[UnusedRunService] total files: ${normalizedFiles.length}');
    print('[UnusedRunService] first files: ${normalizedFiles.take(5).toList()}');

    // 2) Construire les graphes d’import/export
    final graph = ImportGraph();
    final importsMap = await graph.computeImports(
      projectRoot: projectRoot,
      files: normalizedFiles,
      packageName: packageName,
    );
    final exportsMap = await graph.computeExports(
      projectRoot: projectRoot,
      files: normalizedFiles,
      packageName: packageName,
    );

    // 3) Détecter les unused
    final tagger = UnusedTagger();
    final unusedFiles = await tagger.computeUnused(
      files: normalizedFiles,
      importsMap: importsMap,
      exportsMap: exportsMap,
      projectRoot: projectRoot,
    );

    print('[UnusedRunService] unused files: ${unusedFiles.length}');
    print('[UnusedRunService] first unused: ${unusedFiles.take(5).toList()}');

    if (unusedFiles.isEmpty) return null;

    // 4) Dossier cible
    final exportDir = Storage.I.projectUnusedExportsDir(projectSlug);

    // 5) Nom du fichier
    final fileName =
        '${packageName}-unused-${_timestampForFs(DateTime.now())}.md';
    final outPath = PathUtils.join(exportDir.path, fileName);
    final tmpPath = '$outPath.tmp';

    // 6) Options de concaténation
    final options = ConcatenationOptions(
      selectionSpec: SelectionSpec(includeDirs: const [],includeFiles: unusedFiles.toList()),
    );

    // 7) HashGuardService
    final guard = HashGuardService();
    final res = await guard.guardAndMaybeCommitFusion(
      projectRoot: projectRoot,
      finalPath: outPath,
      tempPath: tmpPath,
      options: options,
      force: true,
      dryRun: false,
    );

    return res.finalPath;
  }
}

String _ts2(int n) => (n < 10) ? '0$n' : '$n';
String _timestampForFs(DateTime dt) =>
    '${dt.year}${_ts2(dt.month)}${_ts2(dt.day)}_${_ts2(dt.hour)}${_ts2(dt.minute)}${_ts2(dt.second)}';
