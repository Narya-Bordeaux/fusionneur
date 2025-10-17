import 'dart:io';

/// Utilitaire pour ouvrir un fichier avec l’application par défaut du système.
/// - Windows : utilise `cmd /c`
/// - macOS   : utilise `open`
/// - Linux   : utilise `xdg-open`
class FileOpener {
  static Future<void> open(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path]);
      }
    } catch (_) {
      // On ignore les erreurs silencieusement
    }
  }
}
