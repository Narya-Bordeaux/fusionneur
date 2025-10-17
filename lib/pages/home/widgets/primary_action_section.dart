import 'package:flutter/material.dart';

class PrimaryActionSection extends StatelessWidget {
  final bool enabled;
  final String? projectName;
  final String? presetName;
  final VoidCallback onMerge;

  const PrimaryActionSection({
    super.key,
    required this.enabled,
    required this.projectName,
    required this.presetName,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    final label = (projectName == null || presetName == null)
        ? 'Fusionner'
        : 'Fusionner — $projectName · $presetName';

    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.green.withOpacity(0.06) : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: enabled ? onMerge : null,
            icon: const Icon(Icons.merge_type),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}