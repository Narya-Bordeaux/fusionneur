// Writer pour EntryMode (fusion par point d'entrée).
// - Utilise le pipeline HashGuardService + Concatenator (comme la fusion classique).
// - Construit un ConcatenationOptions basé uniquement sur les fichiers sélectionnés.
// - Produit un fichier nommé <nomFichierEntree>_<horodatage>.md
// - Pas d’entrée dans Hive (mode à part).

import 'package:fusionneur/services/concatenator.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart';
import 'package:fusionneur/services/hash/hash_guard_service.dart';
import 'package:fusionneur/services/storage.dart';

import 'package:fusionneur/pages/entry_mode/services/entrypoint_fusion_orchestrator.dart';
import 'package:fusionneur/pages/entry_mode/services/entrypoint_run_executor.dart';

/// Writer concret pour EntryMode.
/// - Exécute une concaténation HashGuardée.
/// - Stocke le résultat dans Storage → exports/<packageName>/entrypoint/
Future<EntryRunResult> entryModeDirectWriter(
    EntrypointRunPlan plan,
    EntryRunContext context,
    ) async {
  try {
    // Choisir le slug lisible : packageName (si dispo) sinon projectId
    final slug = (context.packageName.isNotEmpty)
        ? context.packageName
        : context.projectId;

    // Dossier d’exports EntryMode via Storage
    final dir = Storage.I.projectEntrypointExportsDir(slug);

    // Nom de fichier basé sur le nom de l’entrypoint + horodatage
    final entryBase = context.entryFile.split('/').last.split('.').first;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final fileName = '${entryBase}_$timestamp.md';
    final outPath = '${dir.path}/$fileName';
    final tmpPath = '$outPath.tmp';

    // Options de concaténation (mêmes conventions que l’UI classique)
    final options = ConcatenationOptions(
      selectionSpec: SelectionSpec(
        includeFiles: plan.selectedFiles,
      ),
      computeImports: (files) async => plan.importsMap,
    );

    // Exécution via HashGuardService
    final guard = HashGuardService();
    final res = await guard.guardAndMaybeCommitFusion(
      projectRoot: context.projectRoot,
      finalPath: outPath,
      tempPath: tmpPath,
      options: options,
      force: true, // on force le run (pas de déduplication Hive ici)
      dryRun: false,
    );

    // Succès
    return EntryRunResult.success(
      outputFilePath: res.finalPath,
      runId: fileName,
      message: "EntryMode fusion complete",
    );
  } catch (e) {
    return EntryRunResult.failure("EntryMode write failed: $e");
  }
}
