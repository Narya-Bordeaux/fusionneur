import 'package:flutter/material.dart';

class PresetPreviewPane extends StatelessWidget {
  final int includedCount;
  final List<String> includedSample;

  const PresetPreviewPane({
    super.key,
    required this.includedCount,
    required this.includedSample,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aperçu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Fichiers inclus : $includedCount'),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              ...includedSample.take(20).map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file, size: 18),
                title: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (includedCount > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${includedCount - 20} autres…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
