import 'package:flutter/material.dart';
import 'package:fusionneur/data/providers/preset_selection_controller.dart';

/// Pane arborescent simple basé sur [PresetTreeNode].
/// UI pur : pas d'accès disque/DB ici.
class PresetTreePane extends StatelessWidget {
  /// Nœuds racine à afficher (souvent ceux de `controller.visibleNodes`).
  final List<PresetTreeNode> nodes;

  /// Toggle (clic sur la checkbox ou la ligne).
  final void Function(PresetTreeNode node) onToggleNode;

  /// Expansion (ouverture d'un dossier).
  final void Function(PresetTreeNode node) onExpandNode;

  /// Réduction (fermeture d'un dossier).
  final void Function(PresetTreeNode node) onCollapseNode;

  /// Texte de recherche à surligner (facultatif).
  final String? highlight;

  const PresetTreePane({
    super.key,
    required this.nodes,
    required this.onToggleNode,
    required this.onExpandNode,
    required this.onCollapseNode,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) => _NodeTile(
        node: nodes[index],
        depth: 0,
        onToggleNode: onToggleNode,
        onExpandNode: onExpandNode,
        onCollapseNode: onCollapseNode,
        highlight: highlight,
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  final PresetTreeNode node;
  final int depth;
  final void Function(PresetTreeNode) onToggleNode;
  final void Function(PresetTreeNode) onExpandNode;
  final void Function(PresetTreeNode) onCollapseNode;
  final String? highlight;

  const _NodeTile({
    required this.node,
    required this.depth,
    required this.onToggleNode,
    required this.onExpandNode,
    required this.onCollapseNode,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final tri = _triStateValue(node.selection);
    final title = _highlightedText(context, node.name, highlight);

    if (node.isDir) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.only(left: 16.0 + depth * 16.0, right: 8),
          initiallyExpanded: node.expanded,
          onExpansionChanged: (expanded) =>
          expanded ? onExpandNode(node) : onCollapseNode(node),
          title: Row(
            children: [
              Checkbox(
                tristate: true,
                value: tri,
                onChanged: (_) => onToggleNode(node),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.folder),
              const SizedBox(width: 8),
              Flexible(child: title),
            ],
          ),
          children: node.children
              .map((c) => _NodeTile(
            node: c,
            depth: depth + 1,
            onToggleNode: onToggleNode,
            onExpandNode: onExpandNode,
            onCollapseNode: onCollapseNode,
            highlight: highlight,
          ))
              .toList(),
        ),
      );
    } else {
      return ListTile(
        contentPadding:
        EdgeInsets.only(left: 16.0 + depth * 16.0, right: 8, top: 0, bottom: 0),
        leading: Checkbox(
          tristate: false,
          value: tri == true,
          onChanged: (_) => onToggleNode(node),
        ),
        title: Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Flexible(child: title),
          ],
        ),
        onTap: () => onToggleNode(node),
      );
    }
  }

  bool? _triStateValue(SelectionState s) {
    switch (s) {
      case SelectionState.included:
        return true;
      case SelectionState.excluded:
        return false;
      case SelectionState.partial:
        return null;
    }
  }

  Widget _highlightedText(BuildContext context, String text, String? query) {
    if (query == null || query.isEmpty) {
      return Text(text, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text, overflow: TextOverflow.ellipsis);
    }
    final before = text.substring(0, idx);
    final match = text.substring(idx, idx + q.length);
    final after = text.substring(idx + q.length);
    final style = DefaultTextStyle.of(context).style;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: before, style: style),
          TextSpan(text: match, style: style.copyWith(fontWeight: FontWeight.bold)),
          TextSpan(text: after, style: style),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
