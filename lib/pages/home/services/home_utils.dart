// lib/pages/home/services/home_utils.dart
//
// Petites fonctions utilitaires pour HomePage.

class HomeUtils {
  /// Format lisible des tailles en octets.
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
