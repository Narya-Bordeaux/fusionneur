// Remplit startLine/endLine pour chaque fichier et réécrit le JSON index final.

import 'dart:io';

import 'package:fusionneur/core/constants.dart';     // FileBanner, CodeFence, SectionDelimiters...
import 'package:fusionneur/core/json_models.dart';    // FusionIndex, FusionFileEntry
import 'package:fusionneur/services/concatenator_parts/json_index_rewriter.dart';

/// Petite classe simple pour stocker start/end (1-indexed, inclusifs).
class _StartEnd {
  final int start;
  final int end;
  const _StartEnd(this.start, this.end);
}

/// Service responsable de la "pass 2" :
/// - rescanner le fichier fusionné,
/// - remplir startLine/endLine,
/// - régénérer les tags,
/// - préserver le flag ::FUSION::unused,
/// - et réécrire le DERNIER bloc JSON via JsonIndexRewriter.
class JsonIndexFinalizer {
  final JsonIndexRewriter _rewriter;

  const JsonIndexFinalizer({JsonIndexRewriter rewriter = const JsonIndexRewriter()})
      : _rewriter = rewriter;

  Future<void> finalize({
    required String outputFilePath,
    required FusionIndex provisionalIndex,
    required Set<String> unusedPaths,
    bool pretty = true,
  }) async {
    // 1) Lire toutes les lignes du fichier concaténé
    final file = File(outputFilePath);
    final lines = await file.readAsLines();

    // 2) Scanner les positions de chaque bloc (bannière -> fence close)
    final positions = <int, _StartEnd>{};
    int i = 0; // index 0-based
    while (i < lines.length) {
      final line = lines[i];
      final m = FileBanner.regex.firstMatch(line);
      if (m != null) {
        final n = int.parse(m.group(1)!);
        final startLine = i + 1; // 1-indexed = ligne de la bannière

        // Avancer jusqu'à la bannière explicite de fin pour le même N :
        // "---- END FILE {N} ----"
        int j = i + 1;
        while (j < lines.length) {
          final endMatch = FileEndBanner.regex.firstMatch(lines[j]);
          if (endMatch != null) {
            final endN = int.parse(endMatch.group(1)!);
            if (endN == n) {
              break; // fin de ce bloc trouvée
            }
          }
          j++;
        }
        final endLine = (j < lines.length) ? j + 1 : lines.length;
        
        positions[n] = _StartEnd(startLine, endLine);
        i = j + 1;
        continue;
      }
      i++;
    }

    // 3) Reconstruire l'index final avec start/end remplis + tags régénérés
    final updatedEntries = provisionalIndex.entries.map((e) {
      final pos = positions[e.fileNumber];
      var updated = (pos == null)
          ? e
          : e.copyWith(startLine: pos.start, endLine: pos.end).regenerateTags();

      // Préserver/rajouter le flag ::FUSION::unused + bool si nécessaire
      final mustFlag = unusedPaths.contains(updated.filePath);
      if (mustFlag) {
        updated = updated.copyWith(
          fusionTags: _withUnusedFlag(updated.fusionTags),
          unused: true,
        );
      }
      return updated;
    }).toList()
      ..sort((a, b) => a.fileNumber.compareTo(b.fileNumber));

    final updatedIndex = FusionIndex(updatedEntries);

    // 4) Remplacer le DERNIER bloc délimité par l'index final
    await _rewriter.replaceLastDelimitedBlock(
      filePath: outputFilePath,
      index: updatedIndex,
      pretty: pretty,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers

  List<String> _withUnusedFlag(List<String> tags) {
    final flag = FusionTags.flag(FusionTags.unused); // "::FUSION::unused"
    if (tags.contains(flag)) return tags;
    return [...tags, flag];
  }
}
