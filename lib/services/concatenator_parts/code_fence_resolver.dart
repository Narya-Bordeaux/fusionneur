// Service qui choisit le langage du fence (```<lang>) en fonction du nom de fichier.

class CodeFenceResolver {
  const CodeFenceResolver();

  /// Retourne la chaîne à mettre après ``` pour coloriser (ou "" si aucune).
  /// Exemples:
  ///   - "main.dart"   -> "dart"
  ///   - "intl_fr.arb" -> "arb"
  ///   - "config.yml"  -> "yaml"  (normalisation minimale)
  ///   - "README"      -> ""      (pas d'extension => pas de langue)
  String languageFor(String filePath) {
    if (filePath.isEmpty) return '';

    // On prend la sous-chaîne après le dernier point.
    final idx = filePath.lastIndexOf('.');
    if (idx == -1 || idx == filePath.length - 1) {
      // Pas d'extension cohérente.
      return '';
    }

    // Extension brute en minuscules.
    var ext = filePath.substring(idx + 1).toLowerCase().trim();

    // Normalisations minimales.
    if (ext == 'yml') return 'yaml';

    // Conserver l'extension telle quelle pour aider l'IA (arb, gradle, etc.).
    return ext;
  }
}
