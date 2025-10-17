import 'dart:io';

import 'package:fusionneur/core/utils/utils.dart'; // PathUtils + PubspecUtils
import 'package:fusionneur/data/hive/boxes.dart';
import 'package:fusionneur/data/hive/models/hive_project.dart';
import 'package:fusionneur/data/repositories/project_repository.dart';
import 'package:fusionneur/services/storage.dart';

class HiveProjectRepository implements ProjectRepository {
  @override
  Future<List<HiveProject>> getAll() async {
    final items = Boxes.projects.values.toList(growable: false);
    items.sort((a, b) => a.packageName.toLowerCase().compareTo(b.packageName.toLowerCase()));
    return items;
  }

  @override
  Future<HiveProject?> findById(String id) async {
    try {
      return Boxes.projects.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HiveProject?> findByRootPath(String rootPath) async {
    final posix = PathUtils.toPosix(rootPath);
    try {
      return Boxes.projects.values
          .firstWhere((p) => PathUtils.toPosix(p.rootPath) == posix);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HiveProject> addFromRoot(String absRootPath) async {
    final root = PathUtils.toPosix(absRootPath);
    final dir = Directory(root);
    if (!await dir.exists()) {
      throw ArgumentError('Dossier introuvable: $root');
    }

    final existing = await findByRootPath(root);
    if (existing != null) return existing;

    // Lecture du packageName depuis pubspec.yaml
    final packageName =
        await PubspecUtils.tryReadName(root) ?? PathUtils.basename(root).toLowerCase();

    // Nom d’affichage : packageName si dispo, sinon basename du dossier
    final id = 'proj_${DateTime.now().microsecondsSinceEpoch}';

    final project = HiveProject(
      id: id,
      rootPath: root,
      packageName: packageName,
    );

    await Boxes.projects.put(project.id, project);

    try {
      if (!Storage.isInitialized) {
        await Storage.init();
      }
      Storage.I.ensureProjectDirs(project.slug);
    } catch (e) {
      stderr.writeln('[HiveProjectRepository] Storage init failed: $e');
    }

    return project;
  }

  @override
  Future<bool> deleteById(String id) async {
    final proj = await findById(id);
    if (proj == null) return false;
    await proj.delete();
    return true;
  }

  /// Migration : s'assure que tous les projets existants ont leurs dossiers Storage.
  Future<void> migrateStorageForExistingProjects() async {
    if (!Storage.isInitialized) {
      await Storage.init();
    }

    for (final proj in Boxes.projects.values) {
      try {
        Storage.I.ensureProjectDirs(proj.slug);
      } catch (e) {
        stderr.writeln(
            '[HiveProjectRepository] Storage migration failed for ${proj.slug}: $e');
      }
    }
  }

  // Helpers

  Future<HiveProject?> findByPackageName(String packageName) async {
    try {
      return Boxes.projects.values.firstWhere((p) => p.packageName == packageName);
    } catch (_) {
      return null;
    }
  }
}
