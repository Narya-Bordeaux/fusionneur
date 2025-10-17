import 'package:hive/hive.dart';
import 'package:fusionneur/data/hive/models/hive_run.dart' as run_model;

/// Service de séquence des runs (par couple {projectId, presetId}).
class RunSequenceService {
  const RunSequenceService._();

  /// Retourne n = max(indexInPreset) + 1 (ou 1 si aucun).
  static Future<int> nextIndex({
    required String projectId,
    required String presetId,
  }) async {
    final box = await _openRunsBox();
    final list = box.values.where((r) =>
    r.projectId == projectId && r.presetId == presetId);
    if (list.isEmpty) return 1;
    final maxIdx = list
        .map((r) => r.indexInPreset)
        .fold<int>(1, (prev, curr) => curr > prev ? curr : prev);
    return maxIdx + 1;
  }

  static Future<Box<run_model.HiveRun>> _openRunsBox() async {
    const name = 'runs';
    if (Hive.isBoxOpen(name)) return Hive.box<run_model.HiveRun>(name);
    return Hive.openBox<run_model.HiveRun>(name);
  }
}
