// Utilitaires pour manipuler le graphe des imports.

class ImportGraphUtils {
  const ImportGraphUtils();

  /// Construit la map "importedBy" en inversant les arêtes du graphe d'import.
  /// - [files] : liste ordonnée des fichiers considérés (périmètre).
  /// - [importsMap] : map "file -> set of dependencies within project".
  /// Retour : map "file -> set of files that import this file".
  Map<String, Set<String>> reverseEdges({
    required List<String> files,
    required Map<String, Set<String>> importsMap,
  }) {
    final set = files.toSet();
    final inverted = <String, Set<String>>{};
    for (final f in files) {
      final deps = importsMap[f] ?? const <String>{};
      for (final dep in deps) {
        if (!set.contains(dep)) continue; // ignore hors périmètre
        inverted.putIfAbsent(dep, () => <String>{}).add(f);
      }
    }
    return inverted;
  }
}
