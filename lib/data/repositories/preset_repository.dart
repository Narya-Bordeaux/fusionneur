import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_preset.dart';

/// Repository centralisant l’accès aux presets (stockés en Hive).
class PresetRepository {
  static const String boxName = 'presets';

  /// Ouvre (ou réutilise) la box Hive des presets.
  static Future<Box<HivePreset>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<HivePreset>(boxName);
    }
    return Hive.openBox<HivePreset>(boxName);
  }

  /// Récupère un preset par son identifiant.
  static Future<HivePreset?> findById(String presetId) async {
    final box = await _openBox();
    return box.get(presetId);
  }

  /// Sauvegarde (ou met à jour) un preset.
  /// - Clé = preset.id (UUID ou identifiant logique).
  static Future<void> put(HivePreset preset) async {
    final box = await _openBox();
    await box.put(preset.id, preset);
  }

  /// Charge tous les presets pour un projet donné.
  static Future<List<HivePreset>> findByProject(String projectId) async {
    final box = await _openBox();
    return box.values.where((p) => p.projectId == projectId).toList();
  }

  /// Supprime un preset.
  static Future<void> delete(String presetId) async {
    final box = await _openBox();
    await box.delete(presetId);
  }
}
