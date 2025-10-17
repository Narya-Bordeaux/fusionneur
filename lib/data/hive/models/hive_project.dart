import 'package:hive/hive.dart';

part 'hive_project.g.dart';

/// Modèle Hive d'un projet indexé/fusionnable.
/// - Préfixe `Hive*` pour éviter toute confusion avec les services runtime.
/// - typeId=1 (laisser stable une fois publié).
@HiveType(typeId: 1)
class HiveProject extends HiveObject {
  /// Identifiant unique du projet (UUID ou autre clé stable).
  @HiveField(0)
  final String id;

  /// Nom lisible du projet (affichage).
  @HiveField(1)
  final String packageName;

  /// Dossier racine du projet (chemin absolu).
  @HiveField(2)
  final String rootPath;


  /// Slug du projet (pour dossiers/affichage court).
  @HiveField(3)
  final String slug;

  /// Dates de création / mise à jour (métadonnées générales).
  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  /// Projet archivé (caché en UI sans supprimer).
  @HiveField(6)
  final bool isArchived;

  /// Dernier run connu (facultatif).
  @HiveField(7)
  final String? lastRunId;

  /// Dernier preset utilisé (facultatif).
  @HiveField(8)
  final String? lastPresetId;

  /// Chemin du dernier export généré (facultatif).
  @HiveField(9)
  final String? lastExportPath;

  /// Date du dernier export (facultatif).
  @HiveField(10)
  final DateTime? lastExportAt;

  /// Compteur total des runs (utile pour stats UI).
  @HiveField(11)
  final int totalRuns;

  HiveProject({
    required this.id,
    required this.packageName,
    required this.rootPath,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.lastRunId,
    this.lastPresetId,
    this.lastExportPath,
    this.lastExportAt,
    this.totalRuns = 0,
  })  : slug = slug ?? _slugify(packageName),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Copie immuable pratique pour petites mises à jour.
  HiveProject copyWith({
    String? id,
    String? packageName,
    String? rootPath,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? lastRunId,
    String? lastPresetId,
    String? lastExportPath,
    DateTime? lastExportAt,
    int? totalRuns,
  }) {
    return HiveProject(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      rootPath: rootPath ?? this.rootPath,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      lastRunId: lastRunId ?? this.lastRunId,
      lastPresetId: lastPresetId ?? this.lastPresetId,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      lastExportAt: lastExportAt ?? this.lastExportAt,
      totalRuns: totalRuns ?? this.totalRuns,
    );
  }
}

/// Très simple slugification "safe" pour noms de dossiers/affichage.
/// (Évite une dépendance externe ; à remplacer par ton utilitaire si besoin.)
String _slugify(String value) {
  final lower = value.toLowerCase();
  final replaced = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-') // non-alphanum -> tiret
      .replaceAll(RegExp(r'-+'), '-')         // tirets multiples -> un seul
      .replaceAll(RegExp(r'^-|-$'), '');      // pas de tiret en bord
  return replaced.isEmpty ? 'project' : replaced;
}
