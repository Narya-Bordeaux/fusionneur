import 'package:flutter/material.dart';

import 'package:fusionneur/pages/preset/widgets/preset_header_form.dart';
import 'package:fusionneur/pages/preset/widgets/preset_toolbar.dart';
import 'package:fusionneur/pages/preset/widgets/preset_tree_pane.dart';
import 'package:fusionneur/pages/preset/widgets/preset_bottom_bar.dart';

import 'package:fusionneur/data/providers/preset_selection_controller.dart';

/// Page d’édition de preset (UI pure).
/// - Remonte au parent une spécification (name/favorite/includedPaths) via onSave.
/// - Aucune persistance ici.
class PresetEditorPage extends StatefulWidget {
  final String projectRoot;

  final void Function() onCancel;

  final void Function({
  required String name,
  required bool favorite,
  required List<String> includedPaths,
  }) onSave;

  final String initialName;
  final bool initialFavorite;

  const PresetEditorPage({
    super.key,
    required this.projectRoot,
    required this.onCancel,
    required this.onSave,
    this.initialName = '',
    this.initialFavorite = false,
  });

  @override
  State<PresetEditorPage> createState() => _PresetEditorPageState();
}

class _PresetEditorPageState extends State<PresetEditorPage> {
  late final PresetSelectionController _controller;

  // --- Form header
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isFavorite = false;

  // --- Toolbar
  late final TextEditingController _searchController;

  bool _initialized = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _isFavorite = widget.initialFavorite;

    _searchController = TextEditingController(text: '');

    _controller = PresetSelectionController(projectRoot: widget.projectRoot);

    // Sync query UI -> controller
    _searchController.addListener(() {
      _controller.setQuery(_searchController.text);
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleCancel() => widget.onCancel();

  void _handleSave() {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    final included = _controller.buildIncludedPaths();
    widget.onSave(
      name: _nameController.text.trim(),
      favorite: _isFavorite,
      includedPaths: included,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Édition de preset')),
      body: _buildBody(),
      bottomNavigationBar: PresetBottomBar(
        onCancel: _handleCancel,
        onSave: _handleSave,
      ),
    );
  }

  Widget _buildBody() {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erreur lors du chargement : $_initError',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final includedCount = _controller.includedCount;

        return Column(
          children: [
            // Header form
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: PresetHeaderForm(
                formKey: _formKey,
                nameController: _nameController,
                isFavorite: _isFavorite,
                onFavoriteChanged: (v) => setState(() => _isFavorite = v),
              ),
            ),

            // Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PresetToolbar(
                searchController: _searchController,
                query: _controller.query,
                onQueryChanged: (q) => _controller.setQuery(q),
                excludeGenerated: _controller.excludeGenerated,
                excludeI18n: _controller.excludeI18n,
                onToggleExcludeGenerated: (v) => _controller.toggleExcludeGenerated(),
                onToggleExcludeI18n: (v) => _controller.toggleExcludeI18n(),
                includedCount: includedCount,
              ),
            ),

            // Arbre pleine largeur
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: PresetTreePane(
                  nodes: _controller.visibleNodes,
                  onToggleNode: (n) => _controller.toggleNode(n),
                  onExpandNode: (n) => _controller.expandNode(n),
                  onCollapseNode: (n) => _controller.collapseNode(n),
                  highlight: _controller.query,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
