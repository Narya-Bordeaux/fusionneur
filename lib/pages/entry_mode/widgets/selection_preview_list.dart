// lib/pages/entry_mode/widgets/selection_preview_list.dart
// Liste des fichiers sélectionnés pour la preview du mode Entrypoint.
// Affiche le nombre de fichiers, l'état de chargement et les éventuelles erreurs.

import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusionneur/core/utils/utils.dart';

class SelectionPreviewList extends StatefulWidget {
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

  @override
  State<SelectionPreviewList> createState() => _SelectionPreviewListState();
}

class _SelectionPreviewListState extends State<SelectionPreviewList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Calcule la taille totale des fichiers en octets
  int _calculateTotalSize() {
    if (widget.projectRoot == null) return 0;

    int total = 0;
    for (final filePath in widget.files) {
      try {
        // Reconstituer le chemin absolu (les chemins dans files sont relatifs)
        final absolutePath = filePath.startsWith('/') || filePath.contains(':')
            ? filePath  // Déjà absolu
            : PathUtils.join(widget.projectRoot!, filePath);  // Relatif, on utilise join

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
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ──────────────────────────────────────────────
    // Cas 2 : erreur
    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          widget.errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    // ──────────────────────────────────────────────
    // Cas 3 : aucun fichier sélectionné
    if (widget.files.isEmpty) {
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
            '${widget.files.length} fichier${widget.files.length > 1 ? "s" : ""} • $sizeFormatted',
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
            child: ScrollConfiguration(
              // Active le drag-scroll sur Windows desktop
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: true,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: Scrollbar(
                controller: _scrollController,  // Contrôleur explicite
                thumbVisibility: true,  // Scrollbar toujours visible
                child: ListView.builder(
                  controller: _scrollController,  // Même contrôleur pour la ListView
                  itemCount: widget.files.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      widget.files[index],
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
        ),
      ],
    );
  }
}
