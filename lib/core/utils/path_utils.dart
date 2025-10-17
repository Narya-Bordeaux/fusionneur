// Utilitaires de chemin (purs + garde-fous).
// - Normalisation POSIX
// - Relatif au projet
// - basename / dirname / join
// - Validation d'existence de fichiers/répertoires (PathValidator)

import 'dart:io';

class PathUtils {
  /// Normalise un chemin (abs ou relatif) en POSIX: remplace '\' par '/'.
  static String toPosix(String path) {
    return path.replaceAll('\\', '/');
  }

  /// Normalise complètement un chemin :
  /// - remplace '\' par '/'
  /// - convertit en minuscules (pour neutraliser C:/ vs c:/ sur Windows)
  /// - supprime les '/' de fin inutiles sauf si c’est la racine
  static String normalize(String path) {
    var p = toPosix(path).trim();
    if (p.isEmpty) return p;
    // sous Windows : uniformiser la casse
    p = p.toLowerCase();
    // éviter les doublons de slashs à la fin
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  /// Retourne un chemin **relatif** à projectRoot (les deux peuvent être abs/rel).
  /// Sortie POSIX. Si `absPath` ne commence pas par `projectRoot`, renvoie `absPath` normalisé.
  static String toProjectRelative(String projectRoot, String absPath) {
    final root = _ensureTrailingSlash(toPosix(projectRoot));
    final abs = toPosix(absPath);
    if (abs.startsWith(root)) {
      return abs.substring(root.length);
    }
    return abs; // cas dégradé : renvoie le chemin tel quel (normalisé POSIX)
  }

  /// Assure un trailing slash ('/') en fin de chaîne.
  static String _ensureTrailingSlash(String p) => p.endsWith('/') ? p : '$p/';

  /// Renvoie le basename (dernier segment) d’un chemin POSIX/Windows.
  static String basename(String path) {
    final p = toPosix(path);
    final idx = p.lastIndexOf('/');
    return idx >= 0 ? p.substring(idx + 1) : p;
  }

  /// Renvoie le dirname (sans le dernier segment). Si pas de '/', retourne ''.
  static String dirname(String path) {
    final p = toPosix(path);
    final idx = p.lastIndexOf('/');
    if (idx <= 0) return '';
    return p.substring(0, idx);
  }

  /// Jointure POSIX naïve (sans remonter '..').
  static String join(String a, String b) {
    if (a.isEmpty) return toPosix(b);
    if (b.isEmpty) return toPosix(a);
    final ap = toPosix(a);
    final bp = toPosix(b);
    if (ap.endsWith('/')) return '$ap$bp';
    return '$ap/$bp';
  }

  /// Vérifie si [path] est bien sous [root].
  /// - Normalise les deux chemins (POSIX + lowercase)
  /// - Tolère les différences de casse et de slash final
  static bool isUnder(String root, String path) {
    final r = _ensureTrailingSlash(toPosix(root)).toLowerCase();
    final p = toPosix(path).toLowerCase();
    return p.startsWith(r);
  }

}

/// Petits garde-fous pour valider l’existence de fichiers/répertoires.
class PathValidator {
  /// Vérifie qu’un répertoire existe (throw si vide/introuvable) et retourne son chemin POSIX.
  static String ensureDirExists(String dirPath, {String label = 'Directory'}) {
    final p = PathUtils.toPosix(dirPath);
    if (p.trim().isEmpty) {
      throw ArgumentError('$label path is empty.');
    }
    if (!Directory(p).existsSync()) {
      throw Exception('$label does not exist: $p');
    }
    return p;
  }

  /// Vérifie qu’un fichier existe (throw si vide/introuvable) et retourne son chemin POSIX.
  static String ensureFileExists(String filePath, {String label = 'File'}) {
    final p = PathUtils.toPosix(filePath);
    if (p.trim().isEmpty) {
      throw ArgumentError('$label path is empty.');
    }
    if (!File(p).existsSync()) {
      throw Exception('$label does not exist: $p');
    }
    return p;
  }

  /// Alias historique pour compatibilité : on valide un répertoire.
  static String ensureExists(String dirPath, {String label = 'Directory'}) =>
      ensureDirExists(dirPath, label: label);
}