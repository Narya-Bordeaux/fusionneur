import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_preset.dart';

/// Accès en lecture aux presets stockés (Hive).
class PresetReadService {
  static const String _boxName = 'presets';

  static Future<List<HivePreset>> listByProject(String projectId) async {
    final box = await Hive.openBox<HivePreset>(_boxName);
    return box.values.where((p) => p.projectId == projectId).toList();
  }

  static Future<bool> anyForProject(String projectId) async {
    final box = await Hive.openBox<HivePreset>(_boxName);
    return box.values.any((p) => p.projectId == projectId);
  }

  /// Récupère un preset complet par son id (sans supposer que la clé Hive == id).
  static Future<HivePreset?> getById(String id) async {
    final box = await Hive.openBox<HivePreset>(_boxName);
    try {
      return box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
