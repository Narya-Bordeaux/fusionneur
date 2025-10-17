import 'package:fusionneur/data/services/preset_read_service.dart';
import 'package:fusionneur/services/fusion_runner.dart';

class FusionService {
  Future<String?> runFusion({
    required String projectId,
    required String projectRoot,
    required String presetId,
  }) async {
    final hivePreset = await PresetReadService.getById(presetId);
    if (hivePreset == null) return null;

    final result = await FusionRunner.run(
      projectId: projectId,
      projectRoot: projectRoot,
      hivePreset: hivePreset,
    );
    if (result.skippedDuplicate) return null;
    return result.fusedPath;
  }
}
