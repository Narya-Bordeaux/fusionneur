import 'dart:io';

import 'package:fusionneur/services/concatenator.dart';           // ConcatenationOptions
import 'package:fusionneur/services/hash/hash_guard_service.dart'; // HashGuardService
import 'package:fusionneur/services/import_graph.dart';            // ImportGraph
import 'package:fusionneur/core/utils/utils.dart';                 // PathUtils + PubspecUtils

import 'package:fusionneur/data/hive/models/hive_preset.dart';

/// Résultat synthétique de la génération.
class FusionGenerationResult {
  /// Hash du contenu final (après éventuel commit).
  final String hash;

  /// Nombre de blocs de code (~ paires de fences ```).
  final int fileCount;

  const FusionGenerationResult({
    required this.hash,
    required this.fileCount,
  });
}

class FusionGenerator {
  const FusionGenerator();

  /// Lance une génération pour [projectRoot] avec [preset], en écrivant le résultat
  /// dans [finalPath] (fichier cible) en passant par [tempPath] (fichier temporaire).
  ///
  /// Retourne le hash final et une estimation du nombre de blocs de code concaténés.
  Future<FusionGenerationResult> generate({
    required String projectRoot,
    required HivePreset preset,
    required String finalPath,
    required String tempPath,
  }) async {
    // 0) Récupération du packageName (pour résoudre package:<name>/...)
    final packageName =
        await PubspecUtils.tryReadName(projectRoot) ??
            PathUtils.basename(projectRoot);

    final guard = HashGuardService();

    final res = await guard.guardAndMaybeCommitFusion(
      projectRoot: projectRoot,
      finalPath: finalPath,
      tempPath: tempPath,
      options: ConcatenationOptions(
        // Sélection/filtres issus du preset Hive → modèle runtime
        selectionSpec: preset.hiveSelectionSpec.toRuntime(),
        onlyDart: preset.hiveFilterOptions.onlyDart,
        excludePatterns: preset.hiveFilterOptions.excludePatterns,

        // 🔌 Branchement des graphes d'import/export pour l'INDEX JSON & `unused`
        computeImports: (files) {
          return ImportGraph().computeImports(
            projectRoot: projectRoot,
            files: files,
            packageName: packageName,
          );
        },
        computeExports: (files) {
          return ImportGraph().computeExports(
            projectRoot: projectRoot,
            files: files,
            packageName: packageName,
          );
        },
      ),
      // Ici on force le run (le guard décidera de committer ou non selon les hash).
      force: true,
      dryRun: false,
    );

    // Estimation du nombre de blocs de code (utile pour feedback UI)
    final content = await File(finalPath).readAsString();
    final fileCount = _countCodeBlocks(content);

    return FusionGenerationResult(
      hash: res.currentHash,
      fileCount: fileCount,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  /// Compte approximatif des blocs de code markdown (paires de fences ```).
  static int _countCodeBlocks(String content) {
    final re = RegExp(r'^```', multiLine: true);
    final fences = re.allMatches(content).length;
    return fences ~/ 2;
  }
}
