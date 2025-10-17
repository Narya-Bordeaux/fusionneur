import 'package:flutter/material.dart';

class PresetHeaderForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  const PresetHeaderForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Form(
        key: formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du preset',
                  hintText: 'ex: default_lib',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nom requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Text('Favori'),
                const SizedBox(width: 8),
                Switch(
                  value: isFavorite,
                  onChanged: onFavoriteChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
