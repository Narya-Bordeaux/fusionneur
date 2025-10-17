import 'package:flutter/material.dart';
import 'package:fusionneur/pages/home/services/unused_run_service.dart';
import 'package:fusionneur/core/utils/utils.dart';

class UnusedModeButton extends StatelessWidget {
  final String projectRoot;
  final String packageName;
  final String projectId;

  const UnusedModeButton({
    super.key,
    required this.projectRoot,
    required this.packageName,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.delete_sweep),
      label: const Text("Unused Fusion"),
      onPressed: () async {
        final slug = packageName.isNotEmpty ? packageName : projectId;
        final outPath = await UnusedRunService.run(
          projectRoot: projectRoot,
          projectSlug: slug,
          packageName: packageName,
        );

        if (outPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aucun fichier unused trouvé.")),
          );
          return;
        }

        await FileOpener.open(outPath);
      },
    );
  }
}
