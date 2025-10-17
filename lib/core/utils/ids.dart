/// Utilitaires pour composer des identifiants stables et lisibles.
class IdUtils {
  /// Compose un identifiant simple de type "<a>__<b>__<c>".
  static String compose(List<String> parts) {
    return parts.join('__');
  }

  /// Compose un identifiant de run standard : "<projectId>__<presetId>__<index>".
  static String runId(String projectId, String presetId, int index) {
    return compose([projectId, presetId, index.toString()]);
  }
}
