import 'package:hive/hive.dart';

part 'hive_run.g.dart';

/// Enum du statut d'un run.
@HiveType(typeId: 30)
enum RunStatus {
  @HiveField(0)
  success,

  @HiveField(1)
  failed,

  @HiveField(2)
  running,
}

/// Modèle Hive d'un "run" de fusion.
/// - Nommage préfixé `Hive*` pour éviter toute confusion avec les services runtime.
/// - Compatibilité : on **conserve typeId=3**
@HiveType(typeId: 3)
class HiveRun extends HiveObject {
  /// Identifiant unique du run (clé lisible ou UUID).
  @HiveField(0)
  final String id;

  /// Projet concerné (clé interne stable).
  @HiveField(1)
  final String projectId;

  /// Preset utilisé (obligatoire).
  @HiveField(2)
  final String presetId;

  /// Position de ce run dans la séquence des runs pour **ce preset**.
  @HiveField(3)
  final int indexInPreset;

  /// Chemin du fichier fusionné généré.
  @HiveField(4)
  final String outputPath;

  /// Hash du contenu généré (intégrité / déduplication).
  @HiveField(5)
  final String outputHash;

  /// Nombre de fichiers source inclus dans la fusion (estimation utile pour l’UI).
  @HiveField(6)
  final int fileCount;

  /// Statut du run.
  @HiveField(7)
  final RunStatus status;

  /// Notes libres (facultatif).
  @HiveField(8)
  final String? notes;

  HiveRun({
    required this.id,
    required this.projectId,
    required this.presetId,
    required this.indexInPreset,
    required this.outputPath,
    required this.outputHash,
    required this.fileCount,
    required this.status,
    this.notes,
  });

  /// Copie immuable pratique pour petites mises à jour.
  /// Astuce : paramètres `?` pour permettre d'omettre les champs non modifiés,
  /// tout en conservant des champs *modèle* non-nullables (ex: `presetId`).
  HiveRun copyWith({
    String? id,
    String? projectId,
    String? presetId,
    int? indexInPreset,
    String? outputPath,
    String? outputHash,
    int? fileCount,
    RunStatus? status,
    String? notes,
  }) {
    return HiveRun(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      presetId: presetId ?? this.presetId,
      indexInPreset: indexInPreset ?? this.indexInPreset,
      outputPath: outputPath ?? this.outputPath,
      outputHash: outputHash ?? this.outputHash,
      fileCount: fileCount ?? this.fileCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
