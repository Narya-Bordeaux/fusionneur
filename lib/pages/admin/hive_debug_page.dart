// lib/pages/admin/hive_debug_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:fusionneur/data/hive/boxes.dart';

class HiveDebugPage extends StatefulWidget {
  const HiveDebugPage({super.key});

  @override
  State<HiveDebugPage> createState() => _HiveDebugPageState();
}

class _HiveDebugPageState extends State<HiveDebugPage> {
  String? selectedBox;
  String jsonContent = '';

  Box? _getBoxByName(String name) {
    switch (name) {
      case 'projects':
        return Boxes.projects;
      case 'presets':
        return Boxes.presets;
      case 'runs':
        return Boxes.runs;
      default:
        return null;
    }
  }

  Future<void> _loadBox(String boxName) async {
    final box = _getBoxByName(boxName);
    if (box == null) {
      setState(() {
        jsonContent = jsonEncode({"error": "Box inconnue: $boxName"});
      });
      return;
    }

    final List<Map<String, dynamic>> dump = [];
    for (final key in box.keys) {
      final value = box.get(key);

      // Tentative d'encodage "safe"
      dynamic formatted;
      if (value is Map) {
        formatted = value;
      } else if (value is Iterable) {
        formatted = value.map((e) => e.toString()).toList();
      } else {
        // Par défaut : on encode en string (sinon HivePreset/HiveRun cassent)
        formatted = value.toString();
      }

      dump.add({"key": key.toString(), "value": formatted});
    }

    final encoder = const JsonEncoder.withIndent('  ');
    setState(() {
      jsonContent = encoder.convert(dump);
    });
  }

  @override
  Widget build(BuildContext context) {
    final boxNames = ['projects', 'presets', 'runs'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hive Debug"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text("Sélectionner une box Hive"),
              value: selectedBox,
              items: boxNames
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedBox = value);
                _loadBox(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonContent.isEmpty
                      ? "Sélectionnez une box pour afficher son contenu"
                      : jsonContent,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
