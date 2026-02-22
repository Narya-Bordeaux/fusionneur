// Adaptateur pour exécuter la fusion "Entrypoint" avec options de nettoyage
// et gestion de l’ouverture automatique du fichier fusionné.

import 'package:fusionneur/core/glob_matcher.dart';
import 'package:fusionneur/core/utils/file_opener.dart';
import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:path/path.dart' as p;

import 'package:fusionneur/services/concatenator.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart';
import 'package:fusionneur/services/concatenator_parts/manifest_writer.dart';
import 'package:fusionneur/pages/entry_mode/services/entrypoint_run_executor.dart';
import 'package:fusionneur/services/hash/hash_guard_service.dart';
import 'package:fusionneur/services/storage.dart';
import 'package:fusionneur/pages/entry_mode/models/entry_mode_options.dart';

/// Construit un [EntryRunWriter] configuré pour le mode "Entrypoint".
/// Permet de filtrer les fichiers générés (*.g.dart)
/// et les fichiers de localisation (*.arb), comme dans le mode standard.
EntryRunWriter buildEntrypointRunWriterAdapter({
  Concatenator? concatenator,
  EntryModeOptions? entryOptions,
}) {
  final guard = HashGuardService(concatenator: concatenator);

  return (plan, ctx) async {
    // ──────────────────────────────────────────────
    // 1. Préparer les patterns d’exclusion selon les options UI.
    final excludePatterns = <String>[];
    if (entryOptions?.excludeGenerated ?? false) {
      excludePatterns.add('**/*.g.dart');
    }

    if (entryOptions?.excludeI18n ?? false) {
      // Exclut les .arb ET les fichiers Dart générés de localisation
      excludePatterns.addAll([
        '**/*.arb',
        '**/l10n/app_localizations*.dart',
      ]);
    }
    // ──────────────────────────────────────────────
    // 1bis. Construire les libellés d'options actives pour le manifest.
    final activeOptionLabels = <String>[];
    if (entryOptions?.includeImportedByOnce ?? false) {
      activeOptionLabels.add('Include imported-by files (1 level up)');
    }
    if (entryOptions?.excludeGenerated ?? false) {
      activeOptionLabels.add('Exclude generated files (*.g.dart)');
    }
    if (entryOptions?.excludeI18n ?? false) {
      activeOptionLabels.add('Exclude localization files (*.arb, app_localizations*.dart)');
    }

    // ──────────────────────────────────────────────
// 2bis. Appliquer manuellement le filtrage des exclusions
    final matcher = GlobMatcher(excludePatterns: excludePatterns);

    final filteredFiles = plan.selectedFiles.where((path) {
      // Convertit le chemin absolu en chemin relatif au projet
      final rel = PathUtils.toProjectRelative(ctx.projectRoot, path);
      final posix = PathUtils.toPosix(rel);

      // Exclut les fichiers correspondant à un motif
      return !matcher.isExcluded(posix);
    }).toList();

    print('🔍 EXCLUDE PATTERNS: $excludePatterns');
    for (final f in plan.selectedFiles) {
      final rel = PathUtils.toProjectRelative(ctx.projectRoot, f);
      print('📄 FILE: $rel');
    }

    // ──────────────────────────────────────────────
    // 2. Construire les options de concaténation
    //    (neutralise includeDirs par défaut et applique les exclusions).
    final options = ConcatenationOptions(
      selectionSpec: const SelectionSpec(
        includeDirs: [], // ← évite de scanner tout lib/
      ).copyWith(
        includeFiles: filteredFiles,
      ),
      excludePatterns: excludePatterns, // ✅ ici, au bon niveau
      computeImports: (files) async => plan.importsMap,
      manifestInfo: ManifestInfo(
        projectName: ctx.packageName,
        formatVersion: 'Fusion v3',
        entryFile: ctx.entryFile,
        activeOptions: activeOptionLabels,
      ),
    );

    // ──────────────────────────────────────────────
    // 3. Dossier d’exports EntryMode
    final exportDir = Storage.I.projectEntrypointExportsDir(ctx.packageName);
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

    // Nom de fichier = <basename(entryFile)>-YYYYMMDD_HHMMSS.md
    final entryBase = p.basenameWithoutExtension(ctx.entryFile);
    final fileName = '${entryBase}-${_timestampForFs(DateTime.now())}.md';
    final outPath = '${exportDir.path}/$fileName';
    final tmpPath = '$outPath.tmp';

    // ──────────────────────────────────────────────
    // 4. Exécuter la fusion avec HashGuard
    final res = await guard.guardAndMaybeCommitFusion(
      projectRoot: ctx.projectRoot,
      finalPath: outPath,
      tempPath: tmpPath,
      options: options,
      force: true,
      dryRun: false,
    );

    // ──────────────────────────────────────────────
    // 5. Résultat utilisateur
    final msg = switch (res.decision) {
      HashGuardDecision.skippedIdentical => 'Identique : rien écrit.',
      HashGuardDecision.dryRunDifferent => 'Différent (dry-run).',
      HashGuardDecision.committed => 'Fichier écrit.',
    };

    final result = EntryRunResult.success(
      outputFilePath: res.finalPath,
      message: msg,
    );

    // ──────────────────────────────────────────────
    // 6. Ouvre automatiquement le fichier si disponible
    if (result.outputFilePath?.isNotEmpty ?? false) {
      try {
        await FileOpener.open(result.outputFilePath!);
      } catch (e) {
        print('⚠️ Impossible d’ouvrir automatiquement le fichier : $e');
      }
    }

    return result;
  };
}

// Utilitaires internes pour formater les timestamps
String _ts2(int n) => (n < 10) ? '0$n' : '$n';
String _timestampForFs(DateTime dt) =>
    '${dt.year}${_ts2(dt.month)}${_ts2(dt.day)}_${_ts2(dt.hour)}${_ts2(dt.minute)}${_ts2(dt.second)}';
