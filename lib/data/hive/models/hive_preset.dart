import 'package:hive/hive.dart';

import 'hive_selection_spec.dart';
import 'hive_file_ordering_policy.dart';
import 'hive_filter_options.dart';

part 'hive_preset.g.dart';

/// Modèle Hive d'un preset de fusion.
/// - Préfixe `Hive*` pour éviter la confusion avec les services runtime.
/// - typeId=2 conservé (stabilité des adapters).
@HiveType(typeId: 2)
class HivePreset extends HiveObject {
  /// Identifiant unique du preset.
  @HiveField(0)
  final String id;

  /// Projet auquel ce preset appartient.
  @HiveField(1)
  final String projectId;

  /// Nom lisible (affiché en UI).
  @HiveField(2)
  final String name;

  /// Spécification de sélection (patterns, racines, etc.) côté Hive.
  @HiveField(3)
  final HiveSelectionSpec hiveSelectionSpec;

  /// Politique d'ordre des fichiers côté Hive.
  @HiveField(4)
  final HiveFileOrderingPolicy hiveFileOrderingPolicy;

  /// Options de filtre (exclusions glob, onlyDart, …).
  @HiveField(5)
  final HiveFilterOptions hiveFilterOptions;

  /// Marqueur "favori" pour mise en avant en UI.
  @HiveField(6)
  final bool isFavorite;

  /// Marqueur "par défaut" (un preset courant par projet).
  @HiveField(7)
  final bool isDefault;

  /// Marqueur "archivé" (caché en UI sans supprimer).
  @HiveField(8)
  final bool isArchived;

  HivePreset({
    required this.id,
    required this.projectId,
    required this.name,
    required this.hiveSelectionSpec,
    required this.hiveFileOrderingPolicy,
    required this.hiveFilterOptions,
    this.isFavorite = false,
    this.isDefault = false,
    this.isArchived = false,
  });

  /// Copie immuable pratique pour petites mises à jour.
  HivePreset copyWith({
    String? id,
    String? projectId,
    String? name,
    HiveSelectionSpec? hiveSelectionSpec,
    HiveFileOrderingPolicy? hiveFileOrderingPolicy,
    HiveFilterOptions? hiveFilterOptions,
    bool? isFavorite,
    bool? isDefault,
    bool? isArchived,
  }) {
    return HivePreset(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      hiveSelectionSpec: hiveSelectionSpec ?? this.hiveSelectionSpec,
      hiveFileOrderingPolicy:
      hiveFileOrderingPolicy ?? this.hiveFileOrderingPolicy,
      hiveFilterOptions: hiveFilterOptions ?? this.hiveFilterOptions,
      isFavorite: isFavorite ?? this.isFavorite,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
