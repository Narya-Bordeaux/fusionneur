// Construit l'index provisoire (FusionIndex) avec start/end = -1.

import 'package:fusionneur/core/constants.dart';
import 'package:fusionneur/core/json_models.dart';
import 'package:fusionneur/core/utils/path_utils.dart';

class IndexProvisionalBuilder {
  const IndexProvisionalBuilder();

  /// Construit un FusionIndex provisoire :
  /// - numérotation déjà fournie (path -> N)
  /// - imports / importedBy stringifiés en "N,path"
  /// - unusedPaths tagués (::FUSION::unused + bool)
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

      // Entrée avec tags auto + bool 'unused'
      final baseEntry = FusionFileEntry.withAutoTags(
        fileNumber: number,
        fileName: name,
        filePath: path,
        startLine: -1,
        endLine: -1,
        imports: imports,
        importedBy: importedBy,
        unused: unusedPaths.contains(path),
      );

      // Ajout du flag ::FUSION::unused si nécessaire (et sans doublon)
      final entry = unusedPaths.contains(path)
          ? baseEntry.copyWith(
        fusionTags: _withUnusedFlag(baseEntry.fusionTags),
        unused: true,
      )
          : baseEntry;

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

  List<String> _withUnusedFlag(List<String> tags) {
    final flag = FusionTags.flag(FusionTags.unused); // "::FUSION::unused"
    if (tags.contains(flag)) return tags;
    return [...tags, flag];
  }
}
