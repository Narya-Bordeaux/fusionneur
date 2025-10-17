import 'package:flutter/material.dart';

/// Stub neutre pour compatibilité d'analyse.
/// (Plus utilisé après refonte de PresetTreePane.)
class TreeNodeTile extends StatelessWidget {
  final String label;
  const TreeNodeTile({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label));
  }
}
