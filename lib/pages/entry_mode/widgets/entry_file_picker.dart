// Widget de sélection du fichier d'entrée pour le mode Entry Fusion.
// - Affiche un bouton pour ouvrir le FilePicker sur le dossier du projet.
// - Affiche le chemin sélectionné ou un message si aucun.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fusionneur/core/utils/path_utils.dart';

class EntryFilePicker extends StatelessWidget {
  final String? entryFile;         // Chemin actuellement sélectionné (peut être null)
  final String projectRoot;        // Dossier de base pour le FilePicker
  final void Function(String) onChanged;

  const EntryFilePicker({
    super.key,
    required this.entryFile,
    required this.projectRoot,
    required this.onChanged,
  });

  Future<void> _pickFile(BuildContext context) async {
    // Convertir en chemin natif pour que FilePicker puisse l'interpréter correctement
    final nativePath = PathUtils.toNative(projectRoot);

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choisir un fichier Dart',
      type: FileType.custom,
      allowedExtensions: ['dart'],
      initialDirectory: nativePath, // Chemin natif (backslash sur Windows)
    );

    if (result != null && result.files.single.path != null) {
      onChanged(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickFile(context),
          icon: const Icon(Icons.folder_open),
          label: const Text("Choisir un fichier d’entrée"),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: entryFile == null
              ? const Text("Aucun fichier sélectionné.")
              : Text(
            entryFile!,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
