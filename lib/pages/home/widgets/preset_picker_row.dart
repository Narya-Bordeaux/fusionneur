import 'package:flutter/material.dart';
import 'package:fusionneur/pages/home/models/preset_summary.dart';

class PresetPickerRow extends StatelessWidget {
  final List<PresetSummary> presets;
  final PresetSummary? selected;

  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesToggle;

  final ValueChanged<PresetSummary> onSelected;
  final VoidCallback onCreatePreset;

  /// Optionnel : suppression d’un preset (si null, bouton désactivé)
  final Future<void> Function(PresetSummary preset)? onDeletePreset;

  const PresetPickerRow({
    super.key,
    required this.presets,
    required this.selected,
    required this.favoritesOnly,
    required this.onFavoritesToggle,
    required this.onSelected,
    required this.onCreatePreset,
    this.onDeletePreset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dropdown des presets
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Preset',
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PresetSummary>(
                isExpanded: true,
                value: selected,
                items: presets
                    .map(
                      (p) => DropdownMenuItem<PresetSummary>(
                    value: p,
                    child: Row(
                      children: [
                        if (p.isFavorite) const Icon(Icons.star, size: 16),
                        if (p.isFavorite) const SizedBox(width: 6),
                        Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                )
                    .toList(),
                onChanged: (p) {
                  if (p != null) onSelected(p);
                },
                hint: const Text('Choisir un preset'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filtre Favoris
        Tooltip(
          message: 'Afficher uniquement les favoris',
          child: FilterChip(
            label: const Text('Favoris'),
            selected: favoritesOnly,
            onSelected: onFavoritesToggle,
          ),
        ),
        const SizedBox(width: 8),
        // Créer un preset
        Tooltip(
          message: 'Créer un nouveau preset',
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreatePreset,
          ),
        ),
        const SizedBox(width: 4),
        // Supprimer le preset sélectionné
        Tooltip(
          message: selected == null
              ? 'Sélectionnez un preset à supprimer'
              : 'Supprimer le preset sélectionné',
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: (selected != null && onDeletePreset != null)
                ? () => onDeletePreset!(selected!)
                : null,
          ),
        ),
      ],
    );
  }
}
