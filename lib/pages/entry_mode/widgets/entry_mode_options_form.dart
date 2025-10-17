// lib/pages/entry_mode/widgets/entry_mode_options_form.dart
// Formulaire d’options pour le mode Entrypoint.
// Permet de choisir les options de parcours et de nettoyage (fichiers générés, i18n).

import 'package:flutter/material.dart';
import 'package:fusionneur/pages/entry_mode/models/entry_mode_options.dart';


class EntryModeOptionsForm extends StatelessWidget {
  final EntryModeOptions options;
  final ValueChanged<EntryModeOptions> onChanged;

  const EntryModeOptionsForm({
    super.key,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options de fusion',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // ──────────────────────────────────────────────
            // Inclure fichiers qui importent ce fichier
            CheckboxListTile(
              title: const Text(
                  'Inclure les fichiers qui importent ce fichier (imported-by 1 niveau)'),
              value: options.includeImportedByOnce,
              onChanged: (v) {
                if (v == null) return;
                onChanged(options.copyWith(includeImportedByOnce: v));
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const Divider(height: 16),

            // ──────────────────────────────────────────────
            // Exclure fichiers générés (*.g.dart)
            CheckboxListTile(
              title: const Text('Exclure fichiers générés (*.g.dart)'),
              value: options.excludeGenerated,
              onChanged: (v) {
                if (v == null) return;
                onChanged(options.copyWith(excludeGenerated: v));
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // ──────────────────────────────────────────────
            // Exclure fichiers de localisation (*.arb)
            CheckboxListTile(
              title: const Text('Exclure fichiers de localisation (*.arb)'),
              value: options.excludeI18n,
              onChanged: (v) {
                if (v == null) return;
                onChanged(options.copyWith(excludeI18n: v));
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }
}
