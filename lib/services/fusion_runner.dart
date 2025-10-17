import 'dart:io';

import 'package:fusionneur/data/hive/models/hive_preset.dart';
import 'package:fusionneur/data/hive/models/hive_run.dart' as run_model;

import 'package:fusionneur/services/fusion/project_label_resolver.dart';
import 'package:fusionneur/services/fusion/export_naming_strategy.dart';
import 'package:fusionneur/services/fusion/run_sequence_service.dart';
import 'package:fusionneur/services/fusion/fusion_generator.dart';
import 'package:fusionneur/services/fusion/dedup_service.dart';
import 'package:fusionneur/services/fusion/run_repository.dart';

import 'package:fusionneur/core/utils/utils.dart';

/// Résultat minimal pour l'UI.
class FusionResult {
  final String fusedPath;
  final String outputHash;
  final int outputSizeBytes;
  final int fileCount;
  /// true si un fichier identique existait déjà (le nouveau a été supprimé).
  final bool skippedDuplicate;

  const FusionResult({
    required this.fusedPath,
    required this.outputHash,
    required this.outputSizeBytes,
    required this.fileCount,
    this.skippedDuplicate = false,
  });
}

/// Orchestrateur de la fusion côté UI.
/// - Génère le fichier (format Fusion v3), calcule hash & compte blocs,
/// - Déduplique par hash sur {projectId, presetId},
/// - Historise un HiveRun si et seulement si le contenu est nouveau.
class FusionRunner {
  const FusionRunner._();

  /// Sortie: ~/fusionneur/exports/<projectLabel>/<projectLabel>-<presetSlug>-<n>.md
  static Future<FusionResult> run({
    required String projectId,
    required String projectRoot,
    required HivePreset hivePreset,
    String? comment,
  }) async {
    // 0) Validation du chemin racine
    final root = PathValidator.ensureExists(projectRoot);

    // 1) Label projet lisible (pubspec.yaml -> name: ... -> slug ; fallback projectId)
    final projectLabel = ProjectLabelResolver.resolve(
      projectId: projectId,
      projectRoot: root,
    );

    // 2) Calcul de n (indexInPreset) sur {projectId, presetId}
    final presetId = hivePreset.id;
    final nextIndex = await RunSequenceService.nextIndex(
      projectId: projectId,
      presetId: presetId,
    );

    // 3) Chemins: dossier exports/<projectLabel>/ + "<projectLabel>-<presetSlug>-<n>.md"
    final exportDir = ExportNamingStrategy.projectExportDir(projectLabel);
    await exportDir.create(recursive: true);

    final fileName = ExportNamingStrategy.makeFileName(
      projectLabel: projectLabel,
      presetName: hivePreset.name,
      index: nextIndex,
    );
    final paths = ExportNamingStrategy.makePaths(
      exportDir: exportDir,
      fileName: fileName,
    );
    final outPath = paths.outPath;
    final tmpPath = paths.tmpPath;

    // 4) Génération (2 passes via HashGuardService/Concatenator)
    final gen = await FusionGenerator().generate(
      projectRoot: root,
      preset: hivePreset,
      finalPath: outPath,
      tempPath: tmpPath,
    );
    final newHash = gen.hash;

    // Taille du fichier final
    final outFile = File(outPath);
    final sizeBytes = await outFile.length();

    // 5) Déduplication
    final isDuplicate = await DedupService.handleDuplicateIfAny(
      projectId: projectId,
      presetId: presetId,
      newHash: newHash,
      outPath: outPath,
    );
    if (isDuplicate) {
      return FusionResult(
        fusedPath: '',
        outputHash: newHash,
        outputSizeBytes: 0,
        fileCount: 0,
        skippedDuplicate: true,
      );
    }

    // 6) Historisation
    final run = run_model.HiveRun(
      id: _composeRunId(projectId, presetId, nextIndex),
      projectId: projectId,
      presetId: presetId,
      indexInPreset: nextIndex,
      outputPath: outPath,
      outputHash: newHash,
      fileCount: gen.fileCount,
      status: run_model.RunStatus.success,
      notes: comment,
    );
    await RunRepository.put(run);

    // 7) Retour UI
    return FusionResult(
      fusedPath: outPath,
      outputHash: newHash,
      outputSizeBytes: sizeBytes,
      fileCount: gen.fileCount,
      skippedDuplicate: false,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  static String _composeRunId(String projectId, String presetId, int index) {
    return '${projectId}__${presetId}__${index}';
  }
}
