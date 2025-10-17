import 'package:flutter/material.dart';
import 'package:fusionneur/pages/home/models/project_info.dart';

/// Ligne de sélection de projet + actions.
/// UI pure : délègue les actions au parent (HomePage).
class ProjectPickerRow extends StatelessWidget {
  final List<ProjectInfo> projects;
  final ProjectInfo? selected;
  final ValueChanged<ProjectInfo?> onChanged;
  final VoidCallback onAddProject;

  /// Optionnel : suppression du projet sélectionné.
  /// - Si null, le bouton est désactivé.
  /// - Si non null, appelé avec `selected` (doit être non null).
  final Future<void> Function(ProjectInfo project)? onDeleteProject;

  const ProjectPickerRow({
    super.key,
    required this.projects,
    required this.selected,
    required this.onChanged,
    required this.onAddProject,
    this.onDeleteProject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dropdown projets
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Projet',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProjectInfo>(
                value: selected,
                isExpanded: true,
                hint: const Text('Choisir un projet'),
                items: projects
                    .map(
                      (p) => DropdownMenuItem<ProjectInfo>(
                    value: p,
                    child: Text('${p.packageName}   ·   ${p.rootPath}'),
                  ),
                )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Ajouter un projet
        FilledButton.icon(
          onPressed: onAddProject,
          icon: const Icon(Icons.add),
          label: const Text('Add project'),
        ),

        const SizedBox(width: 8),

        // Supprimer le projet sélectionné
        Tooltip(
          message: selected == null
              ? 'Sélectionnez un projet à supprimer'
              : 'Supprimer le projet sélectionné',
          child: IconButton.filledTonal(
            onPressed: (selected != null && onDeleteProject != null)
                ? () => onDeleteProject!(selected!)
                : null,
            icon: const Icon(Icons.delete),
          ),
        ),
      ],
    );
  }
}
