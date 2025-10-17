import 'package:flutter/material.dart';

class PresetToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  final bool excludeGenerated;
  final bool excludeI18n;
  final ValueChanged<bool> onToggleExcludeGenerated;
  final ValueChanged<bool> onToggleExcludeI18n;

  final int includedCount;

  const PresetToolbar({
    super.key,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.excludeGenerated,
    required this.excludeI18n,
    required this.onToggleExcludeGenerated,
    required this.onToggleExcludeI18n,
    required this.includedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Rechercher dans l’arborescence',
              border: const OutlineInputBorder(),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  searchController.clear();
                  onQueryChanged('');
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            onChanged: (v) => onQueryChanged(v.trim()),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Exclure fichiers générés (*.g.dart, *.freezed.dart, etc.)',
          child: FilterChip(
            label: const Text('Sans générés'),
            selected: excludeGenerated,
            onSelected: onToggleExcludeGenerated,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Exclure i18n (*.arb, gen-l10n/*.dart)',
          child: FilterChip(
            label: const Text('Sans i18n'),
            selected: excludeI18n,
            onSelected: onToggleExcludeI18n,
          ),
        ),
        const SizedBox(width: 12),
        Chip(
          avatar: const Icon(Icons.description, size: 16),
          label: Text('$includedCount fichiers inclus'),
        ),
      ],
    );
  }
}
