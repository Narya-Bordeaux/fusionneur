// lib/pages/entry_mode/widgets/selection_preview_list.dart
// Liste des fichiers sélectionnés pour la preview du mode Entrypoint.
// Affiche le nombre de fichiers, l’état de chargement et les éventuelles erreurs.

import 'package:flutter/material.dart';

class SelectionPreviewList extends StatelessWidget {
  final List<String> files;
  final bool isLoading;
  final String? errorMessage;

  const SelectionPreviewList({
    super.key,
    required this.files,
    this.isLoading = false,
    this.errorMessage,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fichiers sélectionnés',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${files.length} fichier${files.length > 1 ? "s" : ""})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                files[index],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
