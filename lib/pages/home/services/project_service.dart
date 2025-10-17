import 'package:fusionneur/data/repositories/hive_project_repository.dart';
import 'package:fusionneur/pages/home/models/project_info.dart';

class ProjectService {
  final HiveProjectRepository _repo = HiveProjectRepository();

  Future<List<ProjectInfo>> loadAll() async {
    final hiveProjects = await _repo.getAll();
    return hiveProjects
        .map((p) => ProjectInfo(
      id: p.id,
      packageName: p.packageName,
      rootPath: p.rootPath,
    ))
        .toList();
  }

  Future<void> deleteProject(String id) async {
    await _repo.deleteById(id);
  }
}
