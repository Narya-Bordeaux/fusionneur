import 'dart:io';
import 'package:fusionneur/services/fusion/run_repository.dart';
import 'package:fusionneur/core/utils/utils.dart'; // PathUtils

/// Service pour gérer la déduplication des exports.
/// Vérifie si un hash est déjà présent pour (projectId, presetId).
/// Si oui, supprime le fichier fraîchement généré et retourne true.
class DedupService {
  const DedupService._();

  static Future<bool> handleDuplicateIfAny({
    required String projectId,
    required String presetId,
    required String newHash,
    required String outPath,
  }) async {
    final exists = await RunRepository.existsHash(
      projectId: projectId,
      presetId: presetId,
      hash: newHash,
    );

    if (exists) {
      try {
        final posixPath = PathUtils.toPosix(outPath);
        final f = File(posixPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {
        // Tolérance silencieuse : la suppression n'est pas critique
      }
      return true;
    }
    return false;
  }
}
