// lib/pages/entry_mode/widgets/selection_preview_list.dart
// Liste des fichiers sélectionnés pour la preview du mode Entrypoint.
// Affiche le nombre de fichiers, l'état de chargement et les éventuelles erreurs.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fusionneur/core/utils/utils.dart';

class SelectionPreviewList extends StatelessWidget {
  final List<String> files;
  final String? projectRoot;  // Dossier racine pour résoudre les chemins relatifs
  final bool isLoading;
  final String? errorMessage;

  const SelectionPreviewList({
    super.key,
    required this.files,
    this.projectRoot,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Calcule la taille totale des fichiers en octets
  int _calculateTotalSize() {
    if (projectRoot == null) return 0;

    int total = 0;
    for (final filePath in files) {
      try {
        // Reconstituer le chemin absolu (les chemins dans files sont relatifs)
        final absolutePath = filePath.startsWith('/') || filePath.contains(':')
            ? filePath  // Déjà absolu
            : PathUtils.join(projectRoot!, filePath);  // Relatif, on utilise join

        final file = File(absolutePath);
        if (file.existsSync()) {
          total += file.lengthSync();
        }
      } catch (_) {
        // Ignorer les erreurs (fichier inaccessible, etc.)
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // ──────────────────────────────────────────────
    // Cas 1 : chargement en cours
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ──────────────────────────────────────────────
    // Cas 2 : erreur
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    // ──────────────────────────────────────────────
    // Cas 3 : aucun fichier sélectionné
    if (files.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Aucun fichier sélectionné.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // ──────────────────────────────────────────────
    // Cas 4 : affichage normal
    final totalSize = _calculateTotalSize();
    final sizeFormatted = BytesUtils.prettyBytes(totalSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne de résumé : X fichiers Y Ko
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            '${files.length} fichier${files.length > 1 ? "s" : ""} • $sizeFormatted',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Liste scrollable des fichiers
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Scrollbar(
              thumbVisibility: true,  // Scrollbar toujours visible sur Windows
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    files[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
