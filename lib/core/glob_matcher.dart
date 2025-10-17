// Service pur pour tester des chemins contre des motifs glob.
// MVP: exclut par défaut *.g.dart et *.arb.
// Peut être étendu avec d’autres motifs fournis par l’utilisateur.

import 'package:fusionneur/core/utils/utils.dart'; // PathUtils

class GlobMatcher {
  final List<String> excludePatterns;
  late final List<RegExp> _excludeRegexes;

  /// Crée un matcher avec motifs d’exclusion.
  /// Par défaut: ['**/*.g.dart', '**/*.arb']
  GlobMatcher({
    List<String>? excludePatterns,
  }) : excludePatterns = excludePatterns ?? const ['**/*.g.dart', '**/*.arb'] {
    _excludeRegexes = this.excludePatterns.map(_globToRegExp).toList();
  }

  /// Retourne true si [path] correspond à un motif d’exclusion.
  bool isExcluded(String path) {
    final posix = PathUtils.toPosix(path);
    return _excludeRegexes.any((re) => re.hasMatch(posix));
  }

  /// Filtre une liste de chemins → retourne uniquement ceux qui ne sont pas exclus.
  List<String> filter(List<String> paths) {
    return paths.where((p) => !isExcluded(p)).toList();
  }

  /// Convertit un glob en RegExp.
  ///
  /// Support minimal :
  /// - `**` = tout, y compris dossiers
  /// - `*`  = tout sauf '/'
  /// - `?`  = un caractère sauf '/'
  static RegExp _globToRegExp(String glob) {
    final posix = PathUtils.toPosix(glob);
    final buffer = StringBuffer('^');

    for (var i = 0; i < posix.length; i++) {
      final c = posix[i];
      if (c == '*') {
        final nextIsStar = (i + 1 < posix.length) && posix[i + 1] == '*';
        if (nextIsStar) {
          buffer.write('.*');
          i++; // consomme le deuxième '*'
        } else {
          buffer.write('[^/]*');
        }
      } else if (c == '?') {
        buffer.write('[^/]');
      } else if ('\\.[]{}()+-^|\$'.contains(c)) {
        buffer.write('\\$c'); // échappe métacaractères regex
      } else {
        buffer.write(c);
      }
    }

    buffer.write(r'$');
    return RegExp(buffer.toString());
  }
}
