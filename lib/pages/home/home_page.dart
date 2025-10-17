import 'dart:io';
import 'package:flutter/material.dart';

import 'package:fusionneur/core/utils/utils.dart';
import 'package:fusionneur/data/repositories/preset_repository.dart';

import 'package:fusionneur/pages/admin/hive_debug_page.dart';
import 'package:fusionneur/pages/home/widgets/unused_mode_button.dart';


import 'package:fusionneur/services/project_add_service.dart';

import 'package:fusionneur/pages/home/models/project_info.dart';
import 'package:fusionneur/pages/home/models/preset_summary.dart';
import 'package:fusionneur/pages/home/widgets/project_picker_row.dart';
import 'package:fusionneur/pages/home/widgets/preset_picker_row.dart';
import 'package:fusionneur/pages/home/widgets/primary_action_section.dart';
import 'package:fusionneur/pages/home/widgets/recent_runs_section.dart';
import 'package:fusionneur/pages/home/widgets/entry_mode_button.dart';

import 'package:fusionneur/pages/home/services/project_service.dart';
import 'package:fusionneur/pages/home/services/preset_service.dart';
import 'package:fusionneur/pages/home/services/preset_ui_actions.dart';
import 'package:fusionneur/pages/home/services/fusion_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProjectAddService _projectAddService = const ProjectAddService();
  final ProjectService _projectService = ProjectService();
  final FusionService _fusionService = FusionService();

  List<ProjectInfo> _projects = [];
  ProjectInfo? _selectedProject;

  bool _loadingPresets = false;
  List<PresetSummary> _presets = [];
  bool _favoritesOnly = false;
  PresetSummary? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final list = await _projectService.loadAll();
    if (!mounted) return;
    setState(() => _projects = list);
  }

  List<PresetSummary> _filteredPresetsFrom(List<PresetSummary> all) {
    final visible = all.where((p) => !p.isArchived).toList();
    if (_favoritesOnly) {
      return visible.where((p) => p.isFavorite || p.isDefault).toList();
    }
    return visible;
  }

  Future<void> _onDeletePreset(PresetSummary preset) async {
    final fullPreset = await PresetRepository.findById(preset.id);
    if (fullPreset == null) return;

    final deleted = await PresetUiActions.confirmAndDelete(context, fullPreset);

    if (deleted && mounted && _selectedProject != null) {
      await _loadPresetsFor(_selectedProject!);
    }
  }

  Future<void> _onDeleteProject(ProjectInfo project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet ?'),
        content: Text('Voulez-vous supprimer "${project.packageName}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;

    // Supprimer d'abord les presets liés
    final presets = await PresetService.findByProject(project.id);
    for (final p in presets) {
      await PresetService.delete(p.id);
    }

    await _projectService.deleteProject(project.id);
    await _loadProjects();
  }

  Future<void> _loadPresetsFor(ProjectInfo project) async {
    setState(() {
      _loadingPresets = true;
      _presets = [];
      _selectedPreset = null;
    });

    final summaries = await PresetService.summariesByProject(project.id);

    PresetSummary? defaultSel;
    try {
      defaultSel = summaries.firstWhere((p) => p.isFavorite);
    } catch (_) {
      defaultSel = summaries.isNotEmpty ? summaries.first : null;
    }

    if (!mounted) return;
    setState(() {
      _loadingPresets = false;
      _presets = summaries;
      _selectedPreset = defaultSel;
    });
  }

  void _onProjectChanged(ProjectInfo? p) {
    setState(() {
      _selectedProject = p;
      _selectedPreset = null;
      _presets = [];
    });
    if (p != null) _loadPresetsFor(p);
  }

  Future<void> _onAddProject() async {
    final hiveProject = await _projectAddService.pickAndAddProject();
    if (hiveProject == null) return;

    final added = ProjectInfo(
      id: hiveProject.id,
      packageName: hiveProject.packageName,
      rootPath: hiveProject.rootPath,
    );

    setState(() {
      _projects = [
        ..._projects.where((p) => p.id != added.id),
        added,
      ]..sort((a, b) =>
          a.packageName.toLowerCase().compareTo(b.packageName.toLowerCase()));
      _selectedProject = added;
    });

    await _loadPresetsFor(added);
  }

  Future<void> _onCreatePreset() async {
    final project = _selectedProject;
    if (project == null) return;

    await PresetUiActions.createPreset(context, project.rootPath);
    await _loadPresetsFor(project);
  }

  Future<void> _onMerge() async {
    final project = _selectedProject;
    final presetSummary = _selectedPreset;
    if (project == null || presetSummary == null) return;

    final fusedPath = await _fusionService.runFusion(
      projectId: project.id,
      projectRoot: project.rootPath,
      presetId: presetSummary.id,
    );
    if (fusedPath == null) return;
    await _openFile(fusedPath);
  }

  @override
  Widget build(BuildContext context) {
    final project = _selectedProject;
    final visiblePresets = _filteredPresetsFrom(_presets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fusionneur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: "Hive Debug",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HiveDebugPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (project != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: EntryModeButton(
                        projectRoot: project.rootPath,
                        packageName: project.packageName,
                        projectId: project.id,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UnusedModeButton(
                        projectRoot: project.rootPath,
                        packageName: project.packageName,
                        projectId: project.id,
                      ),
                    ),
                  ],
                ),
              ),

            ProjectPickerRow(
              projects: _projects,
              selected: _selectedProject,
              onChanged: _onProjectChanged,
              onAddProject: _onAddProject,
              onDeleteProject: _onDeleteProject,
            ),
            const SizedBox(height: 16),
            if (_loadingPresets)
              const Center(child: CircularProgressIndicator())
            else
              PresetPickerRow(
                presets: visiblePresets,
                selected: _selectedPreset,
                favoritesOnly: _favoritesOnly,
                onFavoritesToggle: (v) => setState(() => _favoritesOnly = v),
                onSelected: (p) => setState(() => _selectedPreset = p),
                onCreatePreset: _onCreatePreset,
                onDeletePreset: _onDeletePreset,
              ),
            const SizedBox(height: 16),
            PrimaryActionSection(
              enabled: project != null && _selectedPreset != null,
              projectName: project?.packageName,
              presetName: _selectedPreset?.name,
              onMerge: _onMerge,
            ),
            const SizedBox(height: 24),
            RecentRunsSection(
              projectId: project?.id,
              prettyBytes: BytesUtils.prettyBytes,
            ),
          ],
        ),
      ),
    );
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
    } catch (_) {}
  }
}
