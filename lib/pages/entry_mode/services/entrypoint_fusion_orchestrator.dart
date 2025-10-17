// lib/services/entrypoint_fusion_orchestrator.dart
//
// Orchestrateur "Entrypoint Fusion":
// - Recalcule la sélection effective à partir d'un entrypoint:
//     * fermeture transitive des imports internes
//     * + (optionnel) importeurs directs (non récursif)
// - Calcule la map d'import (ImportGraph) pour réutilisation en aval.
// - Retourne un "plan de run" (sélection + imports) pour que la couche
//   suivante génère et persiste la fusion.
//
// ⚠️ Aucun accès disque ici: pas d'écriture de fichier. On reste pur.
// ⚠️ Ne dépend PAS des services de la feature UI (pages/entry_mode/...).
//    (On duplique une petite BFS pour rester indépendant.)

import 'dart:collection';

import 'package:fusionneur/core/utils/utils.dart'; // PathUtils.normalize
import 'package:fusionneur/services/import_graph.dart';
import 'package:fusionneur/services/concatenator_parts/import_graph_utils.dart';

/// Plan prêt à consommer par la couche de génération finale.
/// - selectedFiles: liste POSIX relative au projet, dédupliquée et triée.
/// - importsMap   : map file -> {deps}, POSIX relatives au projet.
class EntrypointRunPlan {
  final List<String> selectedFiles;
  final Map<String, Set<String>> importsMap;

  const EntrypointRunPlan({
    required this.selectedFiles,
    required this.importsMap,
  });

  @override
  String toString() =>
      'EntrypointRunPlan(files: ${selectedFiles.length}, imports: ${importsMap.length})';
}

/// Orchestrateur: prépare la sélection et la map d'import.
/// Étape suivante: transformer ce plan en ConcatenationOptions,
/// puis déléguer à Concatenator/HashGuardService.
class EntrypointFusionOrchestrator {
  const EntrypointFusionOrchestrator();

  /// Calcule le plan et le retourne. Ne fait pas d’E/S.
  ///
  /// [projectRoot]  : chemin absolu du projet (FS)
  /// [packageName]  : nom du package pour résoudre `package:<name>/...`
  /// [candidateFiles]: périmètre des fichiers éligibles (POSIX relatifs)
  /// [entryFile]    : fichier d'entrée (POSIX relatif, doit appartenir au périmètre)
  /// [includeImportedByOnce]: si vrai, ajoute les parents directs (non récursif)
  Future<EntrypointRunPlan> run({
    required String projectRoot,
    required String packageName,
    required List<String> candidateFiles,
    required String entryFile,
    required String projectId,
    bool includeImportedByOnce = false,
  }) async {
    // 1️⃣ Normalisation POSIX complète (neutralise Windows)
    final normalizedRoot = PathUtils.normalize(projectRoot);
    final inScope = candidateFiles.map(PathUtils.normalize).toSet();
    final entry = PathUtils.normalize(entryFile);

    // Vérifie que l’entrée est bien dans le périmètre
    if (!inScope.contains(entry)) {
      print('[EntryFusion] Entrypoint "$entry" hors périmètre.');
      return const EntrypointRunPlan(
        selectedFiles: <String>[],
        importsMap: <String, Set<String>>{},
      );
    }

    // 2️⃣ Calcule la map des imports internes (file -> deps)
    final importsMap = await ImportGraph().computeImports(
      projectRoot: normalizedRoot,
      files: inScope.toList(),
      packageName: packageName,
    );

    // 3️⃣ Fermeture transitive des imports depuis l'entrypoint
    final selected = _collectTransitiveImports(
      entry: entry,
      importsMap: importsMap,
      inScope: inScope,
    );

    // 4️⃣ Option: ajouter les importeurs directs (non récursif)
    if (includeImportedByOnce) {
      final importedByMap = const ImportGraphUtils().reverseEdges(
        files: inScope.toList(),
        importsMap: importsMap,
      );
      final parents = importedByMap[entry];
      if (parents != null && parents.isNotEmpty) {
        selected.addAll(parents.where(inScope.contains));
      }
      print('[EntryFusion] Parents ajoutés: ${parents?.length ?? 0}');
    }

    // 5️⃣ Tri alpha pour stabilité
    final ordered = selected.toList()..sort();

    return EntrypointRunPlan(
      selectedFiles: ordered,
      importsMap: importsMap,
    );
  }

  // ──────────────────────────────────────────────
  // Internes

  /// BFS simple: fermeture transitive des imports depuis [entry], bornée à [inScope].
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
        final normalizedDep = PathUtils.normalize(dep);
        if (!inScope.contains(normalizedDep)) continue;
        if (visited.add(normalizedDep)) {
          queue.add(normalizedDep);
        }
      }
    }
    return visited;
  }
}
