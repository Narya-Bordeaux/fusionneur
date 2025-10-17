import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'boxes.dart';
import 'models/hive_file_ordering_policy.dart';
import 'models/hive_filter_options.dart';
import 'models/hive_preset.dart';
import 'models/hive_project.dart';
import 'models/hive_run.dart';
import 'models/hive_selection_spec.dart';

/// Initialise Hive + enregistre les adaptateurs + ouvre les boxes principales.
///
/// - Appelé une seule fois depuis `main.dart`
/// - Utilise le dossier documents (via path_provider)
Future<void> initializeHive() async {
  // Obtenir un chemin persistant (Documents)
  final dir = await getApplicationDocumentsDirectory();
  final hiveDir = Directory('${dir.path}/fusionneur/hive');

  // Initialisation de Hive avec ce chemin
  await Hive.initFlutter(hiveDir.path);

  // Enregistrement des adaptateurs manuels
  Hive.registerAdapter(HiveFileOrderingPolicyAdapter());
  Hive.registerAdapter(HiveFilterOptionsAdapter());
  Hive.registerAdapter(HiveSelectionSpecAdapter());
  Hive.registerAdapter(HivePresetAdapter());
  Hive.registerAdapter(HiveProjectAdapter());
  Hive.registerAdapter(HiveRunAdapter());
  Hive.registerAdapter(RunStatusAdapter());

  // 🔧 Ouverture centralisée des boxes via Boxes
  await Boxes.openAll();

  print('[HiveInit] Registered adapters: HiveRun=${HiveRunAdapter().typeId}');
}
