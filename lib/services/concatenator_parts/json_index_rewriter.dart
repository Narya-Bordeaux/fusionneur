import 'dart:convert';
import 'dart:io';

import 'package:fusionneur/core/constants.dart';
import 'package:fusionneur/core/json_models.dart';

/// Relit le fichier concaténé et remplace le **dernier** bloc délimité
/// (entre BEGIN/END) par l'index JSON fourni.
/// Séparé pour laisser Concatenator en orchestrateur pur.
class JsonIndexRewriter {
  const JsonIndexRewriter();

  /// Remplace le **dernier** bloc JSON délimité du fichier [filePath].
  /// - Cherche la dernière occurrence de `----- BEGIN JSON INDEX -----`
  /// - Puis la première occurrence de `----- END JSON INDEX -----` après celle-ci
  /// - Insère le JSON sérialisé (pretty par défaut) entre ces deux lignes.
  Future<void> replaceLastDelimitedBlock({
    required String filePath,
    required FusionIndex index,
    bool pretty = true,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('Output file not found: $filePath');
    }

    final lines = await file.readAsLines();

    final beginIdx = _findLastIndex(lines, SectionDelimiters.jsonBegin);
    final endIdx = _findIndexAfter(lines, SectionDelimiters.jsonEnd, from: beginIdx + 1);

    if (beginIdx < 0 || endIdx < 0 || endIdx <= beginIdx) {
      throw StateError('JSON delimiters not found or malformed (beginIdx=$beginIdx, endIdx=$endIdx).');
    }

    final json = index.toJsonString(pretty: pretty);
    final jsonLines = LineSplitter.split(json).toList();

    final newLines = <String>[
      ...lines.sublist(0, beginIdx + 1), // garde la ligne BEGIN
      ...jsonLines,                      // insère le JSON
      ...lines.sublist(endIdx),          // garde END et le reste du fichier
    ];

    await file.writeAsString(newLines.join('\n'));
  }

  // --- Helpers privés ---

  int _findLastIndex(List<String> lines, String marker) {
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].trim() == marker) return i;
    }
    return -1;
  }

  int _findIndexAfter(List<String> lines, String marker, {required int from}) {
    for (int i = from; i < lines.length; i++) {
      if (lines[i].trim() == marker) return i;
    }
    return -1;
  }
}
