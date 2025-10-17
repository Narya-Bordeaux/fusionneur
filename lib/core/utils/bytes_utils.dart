// lib/core/utils/bytes_utils.dart
//
// Utilitaires pour l'affichage lisible des tailles de fichiers.

class BytesUtils {
  /// Convertit un nombre d’octets en chaîne lisible (KB, MB, GB...).
  static String prettyBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    final frac = value < 10 ? 1 : 0;
    return '${value.toStringAsFixed(frac)} ${units[unitIndex]}';
  }
}