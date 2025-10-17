import 'dart:io';

import 'package:fusionneur/services/concatenator_parts/file_selection.dart';

Future<void> main(List<String> args) async {
  // 1) Définir la racine du projet à tester (ex. le projet fusionneur lui-même).
  final projectRoot = Directory.current.path;

  // 2) Construire un SelectionSpec de test
  final spec = SelectionSpec(
    includeDirs: ['lib/services'],          // inclure tout lib/services
    excludeDirs: ['lib/services/fusion'],    // mais exclure le sous-dossier fusion
    includeFiles: ['bin/cli.dart'],         // ajouter ce fichier explicitement
    excludeFiles: ['lib/services/file_scanner.dart'], // exclure un fichier précis
  );

  // 3) Appeler le resolver
  final resolver = FileSelectionResolver();
  final files = await resolver.resolve(
    projectRoot: projectRoot,
    spec: spec,
  );

  // 4) Afficher le résultat
  print('--- Files selected (${files.length}) ---');
  for (final f in files) {
    print(f);
  }
}
