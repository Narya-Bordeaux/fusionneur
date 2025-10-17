// Service local à la page EntryMode (Entrypoint Fusion).
// Calcule la liste des fichiers à inclure à partir d'un fichier d'entrée
// et des options (importés transitivement, + éventuellement importeurs directs).
//
// ⚠️ Les chemins retournés sont en POSIX relatifs à la racine projet (lib/xxx.dart).

import 'package:fusionneur/services/import_graph.dart';

/// Données nécessaires au calcul de l'entrée.
class EntrypointSelectionOptions {
  final String projectRoot;
  final String packageName;
  final List<String> candidateFiles; // POSIX relatifs
  final String entryFile; // absolu ou relatif ? on va normaliser
  final bool includeImportedByOnce;

  EntrypointSelectionOptions({
    required this.projectRoot,
    required this.packageName,
    required this.candidateFiles,
    required this.entryFile,
    this.includeImportedByOnce = false,
  });
}

class EntrypointSelection {
  const EntrypointSelection();

  /// Les chemins sont POSIX relatifs (lib/xxx.dart).
  Future<List<String>> select(EntrypointSelectionOptions opts) async {
    final graph = ImportGraph();

    final imports = await graph.computeImports(
      projectRoot: opts.projectRoot,
      files: opts.candidateFiles,
      packageName: opts.packageName,
    );

    final entryFileRelative =
    _toPosix(_toRelativePath(opts.entryFile, opts.projectRoot));

    final Set<String> result = {};

    // Parcours récursif des fichiers importés
    void addTransitive(String file) {
      if (!result.add(file)) return; // déjà vu
      final deps = imports[file];
      if (deps != null) {
        for (final dep in deps) {
          addTransitive(dep);
        }
      }
    }

    addTransitive(entryFileRelative);

    // Ajoute les fichiers qui importent directement le fichier d’entrée (si option activée)
    if (opts.includeImportedByOnce) {
      for (final entry in imports.entries) {
        if (entry.value.contains(entryFileRelative)) {
          result.add(entry.key);
        }
      }
    }

    return result.toList();
  }

  /// Convertit un chemin absolu en chemin relatif à la racine projet.
  String _toRelativePath(String filePath, String root) {
    final normFile = filePath.replaceAll('\\', '/');
    final normRoot = root.replaceAll('\\', '/');
    return normFile.startsWith(normRoot)
        ? normFile.substring(normRoot.length + 1)
        : normFile;
  }

  /// Normalise un chemin vers POSIX (remplace les \ par /)
  String _toPosix(String path) => path.replaceAll('\\', '/');
}
