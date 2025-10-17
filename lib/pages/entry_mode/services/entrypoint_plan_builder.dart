// lib/pages/entry_mode/services/entrypoint_plan_builder.dart
//
// Construit un plan pour l’entrypoint fusion :
// - Fermeture transitive des imports depuis un fichier d’entrée.
// - Optionnel : ajoute les fichiers qui importent directement ce fichier (importedByOnce).
// - Retourne une liste de fichiers sélectionnés + la map d’imports complète.
//
// ⚠️ Ne fait pas d’écriture disque. C’est une étape pure de calcul.

import 'dart:collection';

import 'package:fusionneur/services/import_graph.dart';
import 'package:fusionneur/services/concatenator_parts/import_graph_utils.dart';

/// Données d’entrée pour construire le plan.
class EntrypointPlanOptions {
  final String projectRoot;
  final String packageName;
  final List<String> candidateFiles; // POSIX relatifs
  final String entryFile;            // POSIX relatif
  final bool includeImportedByOnce;

  const EntrypointPlanOptions({
    required this.projectRoot,
    required this.packageName,
    required this.candidateFiles,
    required this.entryFile,
    this.includeImportedByOnce = false,
  });
}

/// Résultat du plan :
/// - selectedFiles : liste des fichiers inclus (triée alpha).
/// - importsMap : graphe file -> deps internes.
class EntrypointPlanResult {
  final List<String> selectedFiles;
  final Map<String, Set<String>> importsMap;

  const EntrypointPlanResult({
    required this.selectedFiles,
    required this.importsMap,
  });
}

class EntrypointPlanBuilder {
  const EntrypointPlanBuilder();

  Future<EntrypointPlanResult> buildPlan(EntrypointPlanOptions opts) async {
    final inScope = opts.candidateFiles.toSet();
    final entry = _toPosix(opts.entryFile);

    if (!inScope.contains(entry)) {
      return const EntrypointPlanResult(
        selectedFiles: <String>[],
        importsMap: <String, Set<String>>{},
      );
    }

    // 1) Graphe des imports directs
    final importsMap = await ImportGraph().computeImports(
      projectRoot: opts.projectRoot,
      files: opts.candidateFiles,
      packageName: opts.packageName,
    );

    // 2) Graphe inverse (importedBy)
    final importedByMap = const ImportGraphUtils().reverseEdges(
      files: opts.candidateFiles,
      importsMap: importsMap,
    );

    // 3) Fermeture transitive des imports depuis l’entrypoint
    final selected = _collectTransitiveImports(
      entry: entry,
      importsMap: importsMap,
      inScope: inScope,
    );

    // 4) Option : ajouter les parents directs (importedByOnce)
    if (opts.includeImportedByOnce) {
      final parents = importedByMap[entry];
      if (parents != null && parents.isNotEmpty) {
        selected.addAll(parents.where(inScope.contains));
      }
    }

    // 5) Liste triée pour stabilité
    final ordered = selected.toList()..sort();

    return EntrypointPlanResult(
      selectedFiles: ordered,
      importsMap: importsMap,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers internes

  Set<String> _collectTransitiveImports({
    required String entry,
    required Map<String, Set<String>> importsMap,
    required Set<String> inScope,
  }) {
    final visited = <String>{};
    final queue = ListQueue<String>();

    visited.add(entry);
    queue.add(entry);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final deps = importsMap[current] ?? const <String>{};
      for (final dep in deps) {
        if (!inScope.contains(dep)) continue;
        if (visited.add(dep)) {
          queue.add(dep);
        }
      }
    }
    return visited;
  }

  String _toPosix(String p) => p.replaceAll('\\', '/');
}
