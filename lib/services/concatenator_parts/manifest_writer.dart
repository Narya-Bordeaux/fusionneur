// Génère le bloc MANIFEST placé en tête du fichier fusionné.

/// Simple carrier des infos contextuelles affichables en tête.
/// (Adapter au besoin : rien d'obligatoire n'est utilisé pour le hash.)
class ManifestInfo {
  final String projectName;   // nom logique du projet (affichage)
  final String? presetName;   // preset utilisé (facultatif)
  final String formatVersion; // ex: "Fusion v3"
  const ManifestInfo({
    required this.projectName,
    required this.formatVersion,
    this.presetName,
  });
}

class ManifestWriter {
  const ManifestWriter();

  /// Écrit le MANIFEST dans [out].
  /// - On n'imprime **aucune** donnée volatile (pas de date, pas de durée) pour préserver le déterminisme.
  /// - Les markers ::FUSION::SECTION:* servent de délimiteurs courts, sûrs, et faciles à rechercher.
  void writeTo(StringSink out, ManifestInfo info) {
    final manifest = _buildManifestText(info);
    out.writeln(manifest);
  }

  /// Construit le texte du MANIFEST.
  String _buildManifestText(ManifestInfo info) {
    // On garde tout en anglais (règle : code/texte généré en anglais, commentaires en français).
    // NB: les tags sont alignés sur le README du format. (cf. ::FUSION::code/json/import/imported)
    final b = StringBuffer();

    // Section header (marker court, improbable dans du Dart/JSON)
    b.writeln('::FUSION::SECTION:MANIFEST');
    b.writeln('${info.formatVersion} — Concatenated file for project: ${info.projectName}'
        '${info.presetName != null ? ' (preset: ${info.presetName})' : ''}');
    b.writeln();

    // How to navigate — prescriptif pour IA et humain
    b.writeln('HOW TO NAVIGATE THIS FILE');
    b.writeln('- Use the JSON Index to locate a file by "fileName" or "fileNumber".');
    b.writeln('- Jump directly to a code block by searching its tag: ::FUSION::code:<fileName>');
    b.writeln('- Or search by number: ::FUSION::code:<N,>  (comma avoids false positives: "17," ≠ "171,").');
    b.writeln('- Line ranges (startLine/endLine) are provided in JSON Index for each file.');
    b.writeln('- When multiple files share the same name, prefer number tags (::FUSION::code:<N,>) to disambiguate.');
    b.writeln('- Imports and reverse imports are listed in JSON Index, with ready-to-search tags.');
    b.writeln();

    // Tag cheat-sheet
    b.writeln('TAGS CHEAT-SHEET (copy & search):');
    b.writeln('- JSON by name → ::FUSION::json:<fileName>');
    b.writeln('- JSON by num  → ::FUSION::json:<N,>');
    b.writeln('- IMPORT by name → ::FUSION::import:<fileName>');
    b.writeln('- IMPORT by num  → ::FUSION::import:<N,>');
    b.writeln('- IMPORTED by name → ::FUSION::imported:<fileName>');
    b.writeln('- IMPORTED by num  → ::FUSION::imported:<N,>');
    b.writeln('- CODE by name → ::FUSION::code:<fileName>');
    b.writeln('- CODE by num  → ::FUSION::code:<N,>');
    b.writeln();

    // Conventions (rappel concis)
    b.writeln('CONVENTIONS');
    b.writeln('- POSIX relative paths from project root.');
    b.writeln('- Lines are 1-indexed and count ALL lines (manifest, delimiters, JSON, banners, fences, code).');
    b.writeln('- Source code blocks are unmodified (no reformat, no lint).');
    b.writeln();

    // Annoncer explicitement les 2 autres grandes sections avec markers courts
    b.writeln('::FUSION::SECTION:JSON_INDEX');
    b.writeln('The JSON Index is delimited by:');
    b.writeln('  ----- BEGIN JSON INDEX -----');
    b.writeln('  [ { ... }, { ... } ]');
    b.writeln('  ----- END JSON INDEX -----');
    b.writeln();

    b.writeln('::FUSION::SECTION:CODE');
    b.writeln('Each code block is introduced by a FILE banner and a tag line, for example the foo.dart wich is n°136748:');
    b.writeln('  ---- FILE 136748 - lib/foo.dart ----');
    b.writeln('  ::FUSION::code:foo.dart ::FUSION::code:136748, ::FUSION::json:foo.dart');
    b.writeln('  ```dart');
    b.writeln('  // file content...');
    b.writeln('  ```');
    b.writeln('  ---- END FILE 136748 ----');
    b.writeln();

    return b.toString();
  }
}
