import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_run.dart' as run_model;

/// Petit repository pour la box 'runs'.
class RunRepository {
  const RunRepository._();

  static Future<Box<run_model.HiveRun>> openBox() async {
    const name = 'runs';
    if (Hive.isBoxOpen(name)) return Hive.box<run_model.HiveRun>(name);
    return Hive.openBox<run_model.HiveRun>(name);
  }

  static Future<List<run_model.HiveRun>> findByProjectPreset({
    required String projectId,
    required String presetId,
  }) async {
    final box = await openBox();
    return box.values
        .where((r) => r.projectId == projectId && r.presetId == presetId)
        .toList();
  }

  static Future<run_model.HiveRun?> findLastByProjectPreset({
    required String projectId,
    required String presetId,
  }) async {
    final list = await findByProjectPreset(projectId: projectId, presetId: presetId);
    if (list.isEmpty) return null;
    list.sort((a, b) => b.indexInPreset.compareTo(a.indexInPreset));
    return list.first;
  }

  static Future<bool> existsHash({
    required String projectId,
    required String presetId,
    required String hash,
  }) async {
    final list = await findByProjectPreset(projectId: projectId, presetId: presetId);
    return list.any((r) => r.outputHash == hash);
  }

  static Future<void> put(run_model.HiveRun run) async {
    final box = await openBox();
    print('[RunRepository] Putting run id=${run.id} in box=${box.name}');
    await box.put(run.id, run);
  }
}
