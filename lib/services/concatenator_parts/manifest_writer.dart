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
    final b = StringBuffer();

    // Section header (marker court, improbable dans du Dart/JSON)
    b.writeln('::FUSION::SECTION:MANIFEST');
    b.writeln('${info.formatVersion} — Concatenated file for project: ${info.projectName}'
        '${info.presetName != null ? ' (preset: ${info.presetName})' : ''}');
    b.writeln();

    // How to navigate — prescriptif pour IA et humain
    b.writeln('HOW TO NAVIGATE THIS FILE');
    b.writeln('- Use the JSON Index to locate a file by "fileName" or "fileNumber".');
    b.writeln('- Line ranges (startLine/endLine) are provided in JSON Index for each file.');
    b.writeln('- Imports and reverse imports are listed in JSON Index (imports/importedBy).');
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
    b.writeln('Each code block is introduced by a FILE banner, for example:');
    b.writeln('  ---- FILE 136748 - lib/foo.dart ----');
    b.writeln('  ```dart');
    b.writeln('  // file content...');
    b.writeln('  ```');
    b.writeln('  ---- END FILE 136748 ----');
    b.writeln();

    return b.toString();
  }
}
