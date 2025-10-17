// lib/data/repositories/project_repository.dart

import 'package:fusionneur/data/hive/models/hive_project.dart';

abstract class ProjectRepository {
  Future<List<HiveProject>> getAll();
  Future<HiveProject?> findById(String id);
  Future<HiveProject?> findByRootPath(String rootPath);
  Future<HiveProject> addFromRoot(String absRootPath);
  Future<bool> deleteById(String id);
}
