import 'package:hive/hive.dart';
import 'models/hive_project.dart';
import 'models/hive_preset.dart';
import 'models/hive_run.dart';
import 'models/hive_selection_spec.dart';
import 'models/hive_file_ordering_policy.dart';
import 'models/hive_filter_options.dart';

Future<void> registerHiveAdapters() async {
  Hive.registerAdapter(RunStatusAdapter());
  Hive.registerAdapter(HiveRunAdapter());
  Hive.registerAdapter(HivePresetAdapter());
  Hive.registerAdapter(HiveProjectAdapter());
  Hive.registerAdapter(HiveSelectionSpecAdapter());
  Hive.registerAdapter(HiveFileOrderingPolicyAdapter());
  Hive.registerAdapter(HiveFilterOptionsAdapter());
}
