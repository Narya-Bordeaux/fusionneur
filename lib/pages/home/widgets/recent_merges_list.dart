import 'package:flutter/material.dart';
import 'package:fusionneur/pages/home/models/fusion_record.dart';

import 'empty_state.dart';

class RecentMergesList extends StatelessWidget {
  final String title;
  final List<FusionRecord> records;
  final String Function(int) prettyBytes;
  final ValueChanged<String> onOpen;

  const RecentMergesList({
    super.key,
    required this.title,
    required this.records,
    required this.prettyBytes,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (records.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Aucune fusion récente',
        message: 'Lancez une première fusion pour voir l’historique ici.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (_, __) => const Divider(height: 12),
          itemBuilder: (context, index) {
            final r = records[index];
            final subtitle = [
              r.presetName,
              if (r.sizeBytes != null) prettyBytes(r.sizeBytes!),
              if (r.lineCount != null) '${r.lineCount} lines',
            ].join(' · ');

            return ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(
                '${_fmtDateTime(r.dateTime)} — ${r.presetName}',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text('$subtitle\n${r.filePath}'),
              isThreeLine: true,
              trailing: OutlinedButton(
                onPressed: () => onOpen(r.filePath),
                child: const Text('Ouvrir'),
              ),
            );
          },
        ),
      ],
    );
  }

  String _fmtDateTime(DateTime dt) {
    // Format simple FR “YYYY-MM-DD HH:mm” (sans intl pour rester sans dépendance)
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    // NB: ton fuseau est Europe/Paris ; ici on affiche l'heure locale du device.
  }
}
