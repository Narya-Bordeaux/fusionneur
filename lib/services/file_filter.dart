import 'package:fusionneur/core/glob_matcher.dart';
import 'package:fusionneur/core/utils/path_utils.dart';

/// FileFilter (MVP) : applique des exclusions (glob) + option onlyDart.
/// - Entrée : liste de chemins POSIX relatifs (issus du FileScanner)
/// - Sortie : liste filtrée + triée (alpha)
class FileFilter {
  final GlobMatcher excludeMatcher;
  final bool onlyDart;

  /// Par défaut, exclut **/*.g.dart et **/*.arb ; onlyDart = true
  FileFilter({
    GlobMatcher? excludeMatcher,
    this.onlyDart = true,
  }) : excludeMatcher = excludeMatcher ?? GlobMatcher();

  /// Filtre la liste `paths` :
  /// - supprime les chemins exclus par `excludeMatcher`
  /// - si `onlyDart`, garde uniquement les .dart
  /// - renvoie une copie triée alpha
  List<String> apply(List<String> paths) {
    // Normalise au cas où (doit déjà être POSIX, mais pas d’hypothèse forte)
    final posix = paths.map(PathUtils.toPosix).toList();

    final kept = <String>[];
    for (final p in posix) {
      if (onlyDart && !p.endsWith('.dart')) continue;
      if (excludeMatcher.isExcluded(p)) continue;
      kept.add(p);
    }

    kept.sort();
    return kept;
  }
}
