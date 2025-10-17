import 'package:hive/hive.dart';

import 'models/hive_project.dart';
import 'models/hive_preset.dart';
import 'models/hive_run.dart';

/// Points d'accès centralisés aux boxes Hive.
/// Appeler `Boxes.openAll()` après `Hive.init(...)` et l'enregistrement des adapters.
class Boxes {
  static late Box<HiveProject> projects;
  static late Box<HivePreset> presets;
  static late Box<HiveRun> runs;

  /// Ouvre toutes les boxes typées utilisées par l'app.
  static Future<void> openAll() async {
    print('[Boxes] Opening projects...');
    projects = await Hive.openBox<HiveProject>('projects');
    print('[Boxes] projects OK, entries=${projects.length}');

    print('[Boxes] Opening presets...');
    presets  = await Hive.openBox<HivePreset>('presets');
    print('[Boxes] presets OK, entries=${presets.length}');

    print('[Boxes] Opening runs...');
    runs     = await Hive.openBox<HiveRun>('runs');
    print('[Boxes] runs OK, entries=${runs.length}');

    print('[Boxes] All boxes opened successfully');
  }
}
