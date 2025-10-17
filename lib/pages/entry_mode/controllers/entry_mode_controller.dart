// Contrôleur Riverpod pour la feature "Entrypoint Fusion".
// - State: EntryModeState (entryFile, options, preview, status, error).
// - Actions: setEntryFile, updateOptions, loadPreview, runFusion.
// - Services appelés:
//    * EntrypointFusionOrchestrator (plan complet) pour Preview et Run.
//    * EntrypointRunExecutor (writer injecté) pour exécuter la fusion.
//
// Writer injecté: entryModeDirectWriter (pas de Hive, pas de HashGuard).

import 'package:flutter_riverpod/legacy.dart';
import 'package:fusionneur/core/glob_matcher.dart';
import 'package:fusionneur/pages/entry_mode/models/entry_mode_state.dart';
import 'package:fusionneur/pages/entry_mode/models/entry_mode_options.dart';
import 'package:fusionneur/pages/entry_mode/services/entrypoint_fusion_orchestrator.dart';
import 'package:fusionneur/pages/entry_mode/services/entrypoint_run_executor.dart';
import 'package:fusionneur/pages/entry_mode/services/entrypoint_run_writer_adapter.dart';
import 'package:fusionneur/core/utils/utils.dart';
import 'package:fusionneur/services/file_filter.dart';


/// Provider exposé à l’UI (StateNotifierProvider).
final entryModeControllerProvider =
StateNotifierProvider<EntryModeController, EntryModeState>((ref) {
  // ✅ Writer neutre, juste pour initialiser (aucune écriture)
  final stubWriter = (plan, ctx) async => EntryRunResult.success(
    outputFilePath: '',
    message: 'Stub writer: aucune écriture effectuée.',
  );

  return EntryModeController(
    EntrypointRunExecutor(writer: stubWriter),
  );
});


class EntryModeController extends StateNotifier<EntryModeState> {
  final EntrypointRunExecutor executor;

  EntryModeController(this.executor) : super(EntryModeState.initial());

  // ──────────────────────────────────────────────
  // Mutations basiques

  void setEntryFile(String? filePath) {
    // Normalisation du chemin dès la sélection
    final normalized = filePath != null ? PathUtils.normalize(filePath) : null;
    final newState = state.withEntry(normalized);
    state = newState.copyWith(
      canPreview: _canPreview(newState),
      canRun: _canRun(newState),
    );
  }

  void updateOptions(EntryModeOptions newOptions) {
    final newState = state.copyWith(options: newOptions);
    state = newState.copyWith(
      options: newOptions,
      canPreview: _canPreview(newState),
      canRun: _canRun(newState),
    );
  }

  // ──────────────────────────────────────────────
  // Preview

  Future<void> loadPreview({
    required String projectRoot,
    required String packageName,
    required List<String> candidateFiles,
    required String projectId,
  }) async {
    if (!state.canPreview) return;
    state = state.onPreviewStart();

    try {
      final normalizedRoot = PathUtils.normalize(projectRoot);
      final normalizedEntry = PathUtils.normalize(state.entryFile!);

      // Vérifie que le fichier sélectionné appartient bien au projet
      if (!PathUtils.isUnder(normalizedRoot, normalizedEntry)) {
        state = state.onError('Entrypoint out-of-scope or invalid path');
        return;
      }

      final entryRel =
      PathUtils.toProjectRelative(normalizedRoot, normalizedEntry);
      final entryPosix = PathUtils.toPosix(entryRel);

      final normalizedCandidates = <String>[
        for (final f in candidateFiles)
          PathUtils.toPosix(
            PathUtils.toProjectRelative(
              normalizedRoot,
              PathUtils.normalize(f),
            ),
          ),
      ];

      final orchestrator = const EntrypointFusionOrchestrator();
      final plan = await orchestrator.run(
        projectRoot: normalizedRoot,
        packageName: packageName,
        candidateFiles: normalizedCandidates,
        entryFile: entryPosix,
        projectId: projectId,
        includeImportedByOnce: state.options.includeImportedByOnce,
      );

      if (plan.selectedFiles.isEmpty) {
        state = state.onError('No files selected (empty plan)');
        return;
      }

      // ──────────────────────────────────────────────
      // Application des filtres de nettoyage pour la preview
      final excludePatterns = <String>[
        if (state.options.excludeGenerated) '**/*.g.dart',
        if (state.options.excludeI18n) ...[
          '**/*.arb',
          '**/l10n/app_localizations*.dart',
        ],
      ];

      final fileFilter = FileFilter(
        excludeMatcher: GlobMatcher(excludePatterns: excludePatterns),
        onlyDart: true,
      );

      final filteredFiles = fileFilter.apply(plan.selectedFiles);

      if (filteredFiles.isEmpty) {
        state = state.onError('Aucun fichier après filtrage (plan vide)');
        return;
      }

      state = state.onPreviewSuccess(filteredFiles);
    } catch (e) {
      state = state.onError('Preview failed: $e');
    }
  }

  // ──────────────────────────────────────────────
// Run

  Future<void> runFusion({
    required String projectRoot,
    required String packageName,
    required List<String> candidateFiles,
    required String projectId,
  }) async {
    if (!state.canRun) return;
    state = state.onRunStart();

    try {
      final normalizedRoot = PathUtils.normalize(projectRoot);
      final normalizedEntry = PathUtils.normalize(state.entryFile!);

      if (!PathUtils.isUnder(normalizedRoot, normalizedEntry)) {
        state = state.onError('Entrypoint out-of-scope or invalid path');
        return;
      }

      final entryRel =
      PathUtils.toProjectRelative(normalizedRoot, normalizedEntry);
      final entryPosix = PathUtils.toPosix(entryRel);

      final normalizedCandidates = <String>[
        for (final f in candidateFiles)
          PathUtils.toPosix(
            PathUtils.toProjectRelative(
              normalizedRoot,
              PathUtils.normalize(f),
            ),
          ),
      ];

      // ✅ Construit le vrai writer à partir des options utilisateur
      final writer =
      buildEntrypointRunWriterAdapter(entryOptions: state.options);

      // ✅ Utilise ce writer pour exécuter la fusion
      final tempExecutor = EntrypointRunExecutor(writer: writer);

      final result = await tempExecutor.run(
        projectRoot: normalizedRoot,
        packageName: packageName,
        candidateFiles: normalizedCandidates,
        entryFile: entryPosix,
        projectId: projectId,
        includeImportedByOnce: state.options.includeImportedByOnce,
      );

      if (result.success) {
        print('>>> EntryMode SUCCESS');
        print('RunId   : ${result.runId}');
        print('Output  : ${result.outputFilePath}');
        print('Message : ${result.message}');

        state = state.onRunDone();
      } else {
        print('>>> EntryMode FAILURE: ${result.message}');
        state =
            state.onError(result.message ?? 'Fusion failed (unknown error)');
      }
    } catch (e) {
      state = state.onError('Fusion failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Helpers privés

  bool _canPreview(EntryModeState s) {
    return s.entryFile != null && s.entryFile!.isNotEmpty;
  }

  bool _canRun(EntryModeState s) => _canPreview(s);
}
