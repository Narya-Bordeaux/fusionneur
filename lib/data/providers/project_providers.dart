// lib/data/providers/project_providers.dart
//
// Providers Riverpod pour exposer un ProjectRepository et l'état des projets.
// Implémentation par défaut : HiveProjectRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:fusionneur/data/repositories/project_repository.dart';
import 'package:fusionneur/data/repositories/hive_project_repository.dart';
import 'package:fusionneur/data/hive/models/hive_project.dart';

/// Provider qui fournit l'implémentation concrète du dépôt projets (Hive).
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return HiveProjectRepository();
});

/// Liste des projets (async) — l’UI s’abonne et se reconstruit quand ça change.
final projectsProvider = FutureProvider<List<HiveProject>>((ref) async {
  final repo = ref.read(projectRepositoryProvider);
  return repo.getAll();
});

/// ID du projet sélectionné (UI state simple).
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

/// Projet sélectionné (dérivé de la liste + l’ID sélectionné).
final selectedProjectProvider = Provider<HiveProject?>((ref) {
  final selectedId = ref.watch(selectedProjectIdProvider);
  final projectsAsync = ref.watch(projectsProvider);

  return projectsAsync.maybeWhen(
    data: (list) {
      if (selectedId == null) return null;
      try {
        return list.firstWhere((p) => p.id == selectedId);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});
