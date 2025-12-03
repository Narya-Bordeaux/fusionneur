/// Délimiteurs de sections (ASCII only)
class SectionDelimiters {
  // Début/fin de l'index JSON
  static const String jsonBegin = '----- BEGIN JSON INDEX -----';
  static const String jsonEnd = '----- END JSON INDEX -----';
}

/// Bannières de fichiers concaténés
class FileBanner {
  // Modèle : "---- FILE {N} - {path} ----"
  static const String prefix = '---- FILE ';
  static const String separator = ' - '; // ASCII, pas d’em-dash
  static const String suffix = ' ----';

  /// Construit la bannière d’un fichier.
  static String build(int fileNumber, String posixPath) {
    return '$prefix$fileNumber$separator$posixPath$suffix';
  }

  /// Regex pour détecter une bannière et extraire (N, path).
  /// ^---- FILE (\d+) - (.+) ----$
  static final RegExp regex = RegExp(r'^---- FILE (\d+) - (.+) ----$');

}

/// Bannières explicites de fin de fichier concaténé
class FileEndBanner {
  // Modèle : "---- END FILE {N} ----"
  static const String prefix = '---- END FILE ';
  static const String suffix = ' ----';

  /// Construit la bannière de fin : "---- END FILE {N} ----"
  static String build(int fileNumber) => '$prefix$fileNumber$suffix';

  /// Regex pour détecter une fin et extraire (N).
  /// ^---- END FILE (\d+) ----$
  static final RegExp regex = RegExp(r'^---- END FILE (\d+) ----$');
}


/// Fences de code (markdown)
class CodeFence {
  // Fermeture STRICTE : exactement "```" (utilisée par le finalizer)
  static const String close = '```';
}


/// Tags de recherche (préfixe sentinelle)
class FusionTags {
  static const String sentinel = '::FUSION::';

  // Canaux “adressables”
  static const String json = 'json';
  static const String import = 'import';
  static const String imported = 'imported';
  static const String code = 'code';

  // Canal “flag” (sans valeur après ':') — ex: ::FUSION::unused
  static const String unused = 'unused';

  /// Construit un tag par nom de fichier : ::FUSION::json:foo.dart
  static String byName(String channel, String fileName) =>
      '$sentinel$channel:$fileName';

  /// Construit un tag par numéro : ::FUSION::json:17,
  /// (la virgule évite les faux positifs 17 vs 117)
  static String byNumber(String channel, int fileNumber) =>
      '$sentinel$channel:$fileNumber,';

  /// Construit un flag simple : ::FUSION::<nom>  (ex: ::FUSION::unused)
  static String flag(String name) => '$sentinel$name';
}

/// Règles d’exclusion par défaut (fichiers générés)
class DefaultExclusions {
  // Motifs style glob (interpretable par notre filtre)
  static const List<String> globs = <String>[
    'lib/**/*.g.dart',
    'lib/**/*.freezed.dart',
  ];
}

/// Constantes liées au manifest
class ManifestText {
  // Titre MANIFEST (le bloc complet est construit ailleurs)
  static const String title = 'MANIFEST:';
}

/// Stratégies d’ordre (pour numérotation)
enum NumberingStrategy {
  sortedAlpha, // tri alpha (chemins POSIX), stable et reproductible
  // dfs, // options futures
  // bfs,
}

/// Clés JSON normalisées (évite les typos)
class JsonKeys {
  static const String fileNumber = 'fileNumber';
  static const String fileName = 'fileName';
  static const String filePath = 'filePath';
  static const String startLine = 'startLine';
  static const String endLine = 'endLine';
  static const String imports = 'imports';
  static const String importedBy = 'importedBy';
  static const String fusionTags = 'fusionTags';
}
