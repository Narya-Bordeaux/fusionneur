import 'package:fusionneur/pages/entry_mode/services/entrypoint_fusion_orchestrator.dart';

/// Contexte d'exécution transmis au writer.
/// (Informations nécessaires à l'écriture et à l'historisation.)
class EntryRunContext {
  final String projectRoot;   // Racine absolue du projet (FS).
  final String packageName;   // Nom du package (pubspec.yaml).
  final String projectId;     // Identifiant logique du projet (Hive ou autre).
  final String entryFile;     // Fichier d'entrée (POSIX relatif).

  const EntryRunContext({
    required this.projectRoot,
    required this.packageName,
    required this.projectId,
    required this.entryFile,
  });
}

/// Résultat standardisé de l'exécution complète.
class EntryRunResult {
  final bool success;
  final String? outputFilePath;
  final String? runId;
  final String? message;

  const EntryRunResult({
    required this.success,
    this.outputFilePath,
    this.runId,
    this.message,
  });

  factory EntryRunResult.success({
    required String outputFilePath,
    String? runId,
    String? message,
  }) =>
      EntryRunResult(
        success: true,
        outputFilePath: outputFilePath,
        runId: runId,
        message: message,
      );

  factory EntryRunResult.failure(String message) =>
      EntryRunResult(success: false, message: message);
}

/// Signature du writer injecté.
typedef EntryRunWriter = Future<EntryRunResult> Function(
    EntrypointRunPlan plan,
    EntryRunContext context,
    );

/// Exécuteur: combine l'orchestrateur et un writer pour produire un run complet.
class EntrypointRunExecutor {
  final EntrypointFusionOrchestrator _orchestrator;
  final EntryRunWriter _writer;

  const EntrypointRunExecutor({
    EntrypointFusionOrchestrator orchestrator =
    const EntrypointFusionOrchestrator(),
    required EntryRunWriter writer,
  })  : _orchestrator = orchestrator,
        _writer = writer;

  Future<EntryRunResult> run({
    required String projectRoot,
    required String packageName,
    required List<String> candidateFiles,
    required String entryFile,
    required String projectId,
    bool includeImportedByOnce = false,
  }) async {
    try {
      final plan = await _orchestrator.run(
        projectRoot: projectRoot,
        packageName: packageName,
        candidateFiles: candidateFiles,
        entryFile: entryFile,
        projectId: projectId,
        includeImportedByOnce: includeImportedByOnce,
      );

      if (plan.selectedFiles.isEmpty) {
        return EntryRunResult.failure(
          "No files selected (entrypoint out-of-scope or empty plan).",
        );
      }

      final ctx = EntryRunContext(
        projectRoot: projectRoot,
        packageName: packageName,
        projectId: projectId,
        entryFile: entryFile,
      );

      return await _writer(plan, ctx);
    } catch (e) {
      return EntryRunResult.failure("Entrypoint run failed: $e");
    }
  }
}
