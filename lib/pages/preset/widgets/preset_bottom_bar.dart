import 'package:flutter/material.dart';

class PresetBottomBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  /// Active/désactive le bouton "Enregistrer".
  /// - true (défaut) : bouton cliquable
  /// - false : bouton grisé (onPressed = null)
  final bool enabled;

  const PresetBottomBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: enabled ? onSave : null,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
