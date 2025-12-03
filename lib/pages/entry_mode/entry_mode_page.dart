// Page principale pour le mode "Entrypoint Fusion".
// - Compose plusieurs sous-widgets : EntryFilePicker, EntryModeOptionsForm, SelectionPreviewList.
// - Pilote le EntryModeController via Riverpod.
// - Boutons Preview et Run reliés aux méthodes du controller.
// - Correction : génère candidateFiles via FileScanner (plutôt que paramètre externe).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fusionneur/pages/entry_mode/controllers/entry_mode_controller.dart';
import 'package:fusionneur/pages/entry_mode/widgets/entry_file_picker.dart';
import 'package:fusionneur/pages/entry_mode/widgets/entry_mode_options_form.dart';
import 'package:fusionneur/pages/entry_mode/widgets/selection_preview_list.dart';

import 'package:fusionneur/services/file_scanner.dart';

class EntryModePage extends ConsumerWidget {
  final String projectRoot;   // dossier du projet
  final String packageName;   // nom du package
  final String projectId;     // identifiant interne du projet

  const EntryModePage({
    super.key,
    required this.projectRoot,
    required this.packageName,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entryModeControllerProvider);
    final controller = ref.read(entryModeControllerProvider.notifier);

    Future<List<String>> scanCandidates() async {
      final scanner = FileScanner();
      return scanner.listFiles(
        projectRoot: projectRoot,
        subDir: 'lib',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrypoint Fusion"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de fichier d'entrée
            EntryFilePicker(
              entryFile: state.entryFile,
              projectRoot: projectRoot,
              onChanged: (file) => controller.setEntryFile(file),
            ),

            const SizedBox(height: 16),

            // Formulaire d'options (imports, sens de parcours, etc.)
            EntryModeOptionsForm(
              options: state.options,
              onChanged: (newOptions) => controller.updateOptions(newOptions),
            ),

            const SizedBox(height: 16),

            // Boutons Preview / Run
            Row(
              children: [
                ElevatedButton(
                  onPressed: state.canPreview
                      ? () async {
                    final candidates = await scanCandidates();
                    await controller.loadPreview(
                      projectId: projectId,
                      projectRoot: projectRoot,
                      packageName: packageName,
                      candidateFiles: candidates,
                    );
                  }
                      : null,
                  child: state.isLoadingPreview
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Preview"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: state.canRun
                      ? () async {
                    final candidates = await scanCandidates();
                    await controller.runFusion(
                      projectRoot: projectRoot,
                      packageName: packageName,
                      candidateFiles: candidates,
                      projectId: projectId,
                    );
                  }
                      : null,
                  child: state.isRunning
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Run Fusion"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Liste des fichiers sélectionnés pour la fusion
            Expanded(
              child: SelectionPreviewList(
                files: state.previewFiles,
                projectRoot: projectRoot,  // Ajout du projectRoot pour calculer les tailles
                isLoading: state.isLoadingPreview,
                errorMessage: state.hasError ? state.errorMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
