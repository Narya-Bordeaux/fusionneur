// Bouton qui ouvre la page EntryModePage (Entrypoint Fusion).
// - À placer sur la HomePage (visible seulement si un projet est sélectionné).
// - Passe les infos du projet à la page.
//
// Props :
//   - projectRoot : chemin absolu du projet
//   - packageName : nom du package
//   - candidateFiles : liste des fichiers éligibles (POSIX relatifs)
//   - projectId : identifiant logique du projet (Hive ou autre)

import 'package:flutter/material.dart';
import 'package:fusionneur/pages/entry_mode/entry_mode_page.dart';

class EntryModeButton extends StatelessWidget {
  final String projectRoot;
  final String packageName;
  final String projectId;

  const EntryModeButton({
    super.key,
    required this.projectRoot,
    required this.packageName,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.alt_route),
      label: const Text("Entrypoint Fusion"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntryModePage(
              projectRoot: projectRoot,
              packageName: packageName,
              projectId: projectId,
            ),
          ),
        );
      },
    );
  }
}
