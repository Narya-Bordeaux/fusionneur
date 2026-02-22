// Construit l'index provisoire (FusionIndex) avec start/end = -1.

import 'package:fusionneur/core/json_models.dart';
import 'package:fusionneur/core/utils/path_utils.dart';

class IndexProvisionalBuilder {
  const IndexProvisionalBuilder();

  /// Construit un FusionIndex provisoire :
  /// - numérotation déjà fournie (path -> N)
  /// - imports / importedBy stringifiés en "N,path"
  /// - unusedPaths marqués (bool unused)
  FusionIndex build({
    required List<String> ordered,
    required Map<String, int> numbering,
    required Map<String, Set<String>> importsMap,
    required Map<String, Set<String>> importedByMap,
    required Set<String> unusedPaths,
  }) {
    final entries = <FusionFileEntry>[];
    for (final path in ordered) {
      final number = numbering[path]!;
      final name = PathUtils.basename(path);

      final imports = _stringifyLinks(importsMap[path], numbering);
      final importedBy = _stringifyLinks(importedByMap[path], numbering);

      final entry = FusionFileEntry(
        fileNumber: number,
        fileName: name,
        filePath: path,
        startLine: -1,
        endLine: -1,
        imports: imports,
        importedBy: importedBy,
        unused: unusedPaths.contains(path),
      );

      entries.add(entry);
    }

    entries.sort((a, b) => a.fileNumber.compareTo(b.fileNumber));
    return FusionIndex(entries);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers internes

  List<String> _stringifyLinks(Set<String>? targets, Map<String, int> numbering) {
    if (targets == null || targets.isEmpty) return const <String>[];
    final list = targets.toList()..sort();
    return list
        .map((p) => '${numbering[p] ?? -1},$p')
        .where((s) => !s.startsWith('-1,')) // ignore si inconnu
        .toList();
  }
}
