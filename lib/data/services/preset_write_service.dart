import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_preset.dart';

/// Écritures sur la box de presets (suppression, cascade par projet).
class PresetWriteService {
  static const String _boxName = 'presets';

  /// Supprime un preset par son id logique (même si la clé Hive ne correspond pas).
  static Future<bool> deleteById(String id) async {
    final box = await Hive.openBox<HivePreset>(_boxName);
    dynamic keyToDelete;
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is HivePreset && value.id == id) {
        keyToDelete = key;
        break;
      }
    }
    if (keyToDelete != null) {
      await box.delete(keyToDelete);
      return true;
    }
    return false;
  }

  /// Supprime tous les presets d'un projet et renvoie le nombre supprimé.
  static Future<int> deleteAllForProject(String projectId) async {
    final box = await Hive.openBox<HivePreset>(_boxName);
    final keys = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is HivePreset && value.projectId == projectId) {
        keys.add(key);
      }
    }
    await box.deleteAll(keys);
    return keys.length;
  }
}
