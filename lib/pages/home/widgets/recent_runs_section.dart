import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:hive/hive.dart';

import 'package:fusionneur/pages/home/models/fusion_record.dart';
import 'package:fusionneur/pages/home/widgets/recent_merges_list.dart';
import 'package:fusionneur/data/hive/models/hive_run.dart' as run_model;

/// Section autonome qui affiche les fusions (HiveRun) pour un projet donné.
/// NOTE: s'appuie sur Hive "core" (Box.watch) pour réagir aux changements.
class RecentRunsSection extends StatefulWidget {
  final String? projectId;
  final String Function(int) prettyBytes;

  const RecentRunsSection({
    super.key,
    required this.projectId,
    required this.prettyBytes,
  });

  @override
  State<RecentRunsSection> createState() => _RecentRunsSectionState();
}

enum _SortMode {
  byDateDesc, // le plus récent en premier
  byNameAsc,  // tri alphabétique sur le nom de fichier
}

class _RecentRunsSectionState extends State<RecentRunsSection> {
  Box<run_model.HiveRun>? _box;

  // Tri par défaut : date décroissante (ce que tu souhaites)
  _SortMode _sortMode = _SortMode.byDateDesc;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    const boxName = 'runs';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<run_model.HiveRun>(boxName)
        : await Hive.openBox<run_model.HiveRun>(boxName);
    print('[RecentRunsSection] Box opened: ${box.name}, entries=${box.length}');
    if (!mounted) return;
    setState(() => _box = box);
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.projectId;

    // Pas de projet sélectionné -> liste vide
    if (pid == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          RecentMergesList(
            title: 'Dernières fusions',
            records: const <FusionRecord>[],
            prettyBytes: widget.prettyBytes,
            onOpen: (_) {},
          ),
        ],
      );
    }

    final box = _box;
    if (box == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Réagit aux mutations de la box via watch()
    return StreamBuilder<BoxEvent>(
      stream: box.watch(),
      builder: (context, snapshot) {
        var records = _buildRecordsForProject(box, pid); // mapping HiveRun -> FusionRecord
        records = _applySort(records);                   // tri selon _sortMode
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            RecentMergesList(
              title: 'Dernières fusions',
              records: records,
              prettyBytes: widget.prettyBytes,
              onOpen: _openFile,
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UI header : petit sélecteur de tri

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('Historique', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          DropdownButton<_SortMode>(
            value: _sortMode,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: _SortMode.byDateDesc,
                child: Text('Trier par date (récent → ancien)'),
              ),
              DropdownMenuItem(
                value: _SortMode.byNameAsc,
                child: Text('Trier par nom (A → Z)'),
              ),
            ],
            onChanged: (m) {
              if (m == null) return;
              setState(() => _sortMode = m);
            },
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Construction des records à partir des HiveRun
  // (structure d’origine conservée : stat du fichier pour la date affichée)

  List<FusionRecord> _buildRecordsForProject(
      Box<run_model.HiveRun> box,
      String projectId,
      ) {
    final runs = box.values
        .where((r) => r.projectId == projectId)
        .toList()
      ..sort((a, b) {
        // Tri d'origine interne côté HiveRun :
        // ordre décroissant par indexInPreset, puis par nom de fichier
        final byIndex = b.indexInPreset.compareTo(a.indexInPreset);
        if (byIndex != 0) return byIndex;
        return p.basename(b.outputPath).compareTo(p.basename(a.outputPath));
      }); // :contentReference[oaicite:2]{index=2}

    final mapped = <FusionRecord>[];
    for (final r in runs) {
      final path = r.outputPath;
      final file = File(path);
      if (!file.existsSync()) continue; // ignorer les fichiers supprimés à la main

      final stat = file.statSync();
      final fileName = p.basename(path);

      mapped.add(
        FusionRecord(
          id: r.id,
          dateTime: stat.modified, // Date/heure du fichier actuel (mtime) :contentReference[oaicite:3]{index=3}
          presetId: r.presetId,
          presetName: _extractPresetFromFileName(
            fileName: fileName,
            projectLabelOrId: _extractProjectLabelFromFileName(fileName),
          ),
          filePath: path,
          sizeBytes: stat.size,
        ),
      );
    }
    return mapped;
  }

  // Tri appliqué au *résultat affiché*
  List<FusionRecord> _applySort(List<FusionRecord> records) {
    final out = List<FusionRecord>.from(records);
    switch (_sortMode) {
      case _SortMode.byDateDesc:
        out.sort((a, b) {
          final byDate = b.dateTime.compareTo(a.dateTime);
          if (byDate != 0) return byDate;
          return p.basename(b.filePath).compareTo(p.basename(a.filePath));
        });
        break;
      case _SortMode.byNameAsc:
        out.sort((a, b) {
          final byName =
          p.basename(a.filePath).compareTo(p.basename(b.filePath));
          if (byName != 0) return byName;
          return b.dateTime.compareTo(a.dateTime);
        });
        break;
    }
    return out;
  }

  /// Extrait le "project label" (préfixe) depuis "<project>-<preset>-<n>.md".
  String _extractProjectLabelFromFileName(String fileName) {
    var base = fileName;
    if (base.toLowerCase().endsWith('.md')) {
      base = base.substring(0, base.length - 3);
    }
    final firstDash = base.indexOf('-');
    if (firstDash <= 0) return base;
    return base.substring(0, firstDash);
  }

  /// Extrait le preset depuis "<project>-<preset>-<n>.md".
  String _extractPresetFromFileName({
    required String fileName,
    required String projectLabelOrId,
  }) {
    var base = fileName;
    if (base.toLowerCase().endsWith('.md')) {
      base = base.substring(0, base.length - 3);
    }
    // retire le prefix "<project>-"
    final prefix = '$projectLabelOrId-';
    if (base.startsWith(prefix)) {
      base = base.substring(prefix.length);
    }
    // retire le suffix "-<n>"
    final lastDash = base.lastIndexOf('-');
    if (lastDash > 0) {
      base = base.substring(0, lastDash);
    }
    return base.isEmpty ? 'preset' : base;
  }

  static Future<void> _openFile(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path]);
      }
    } catch (_) {
      // on ignore ici; l'appelant peut gérer une snackbar si besoin
    }
  }
}
