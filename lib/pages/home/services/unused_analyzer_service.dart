// lib/pages/home/services/unused_analyzer_service.dart
//
// Service pour analyser les fichiers "unused" d’un projet.

import 'package:fusionneur/services/file_scanner.dart';
import 'package:fusionneur/services/import_graph.dart';
import 'package:fusionneur/services/concatenator_parts/unused_tagger.dart';

class UnusedAnalyzerService {
  static Future<List<String>> findUnused({
    required String projectRoot,
    required String packageName,
  }) async {
    // 1) Scanner tous les fichiers sous lib/
    final scanner = FileScanner();
    final files = await scanner.listFiles(
      projectRoot: projectRoot,
      subDir: 'lib',
    );

    // 2) Graphe des imports + exports
    final graph = ImportGraph();
    final importsMap = await graph.computeImports(
      projectRoot: projectRoot,
      files: files,
      packageName: packageName,
    );
    final exportsMap = await graph.computeExports(
      projectRoot: projectRoot,
      files: files,
      packageName: packageName,
    );

    // 3) Tagger unused
    final tagger = UnusedTagger();
    final unusedSet = await tagger.computeUnused(
      files: files,
      importsMap: importsMap,
      exportsMap: exportsMap,
      projectRoot: projectRoot,
    );

    return unusedSet.toList()..sort();
  }
}
