import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:fusionneur/data/hive/models/hive_selection_spec.dart';

/// État de sélection tri‐état pour un nœud d’arbre.
enum SelectionState { included, excluded, partial }

/// Modèle de nœud (UI only).
class PresetTreeNode {
  final String name;               // basename
  final String path;               // chemin complet
  final bool isDir;                // dossier ou fichier
  final List<PresetTreeNode> children;
  bool expanded;                   // état d’expansion UI
  SelectionState selection;        // tri-état

  PresetTreeNode({
    required this.name,
    required this.path,
    required this.isDir,
    required this.children,
    this.expanded = false,
    this.selection = SelectionState.excluded,
  });
}

/// Contrôleur UI de la page d’édition de preset.
/// - Scanne le disque à partir de projectRoot.
/// - Gère filtres (query, exclusions) + sélection tri-état.
/// - Aucune dépendance à Hive/DB.
class PresetSelectionController extends ChangeNotifier {
  /// Racine du projet sur le disque (argument public).
  final String projectRoot;

  // Compat ascendante : certains anciens appels utilisaient `root:` au lieu de `projectRoot:`.
  PresetSelectionController({String? projectRoot, String? root})
      : projectRoot = projectRoot ?? root ?? (throw ArgumentError('projectRoot/root requis'));

  // --- État filtres ---
  String _query = '';
  bool _excludeGenerated = true;
  bool _excludeI18n = false;

  // --- Arbre interne (complet) ---
  PresetTreeNode? _root;

  // ---------------------------------------------------------------------------
  // Accesseurs (état)
  // ---------------------------------------------------------------------------

  String get query => _query;
  bool get excludeGenerated => _excludeGenerated;
  bool get excludeI18n => _excludeI18n;

  /// Nœuds visibles à la racine (après filtres + recherche).
  List<PresetTreeNode> get visibleNodes {
    if (_root == null) return const [];
    final list = <PresetTreeNode>[];
    for (final child in _root!.children) {
      final filtered = _filteredClone(child);
      if (filtered != null) list.add(filtered);
    }
    return list;
  }

  /// Compteurs (hors _query ; respectent les flags d’exclusion).
  int get totalCount => _root == null ? 0 : _countFilesFiltered(_root!);
  int get includedCount => _root == null ? 0 : _countIncludedFiltered(_root!);

  // ---------------------------------------------------------------------------
  // Cycle de vie
  // ---------------------------------------------------------------------------

  /// Scan disque + construction de l’arbre (isolate via compute).
  Future<void> initialize() async {
    final rootNode = await compute<String, PresetTreeNode>(
      _buildTreeSync,
      projectRoot,
    );
    _root = rootNode;

    // Par défaut, rien n’est inclus.
    _applySelectionState(_root!, SelectionState.excluded);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions UI (filtres)
  // ---------------------------------------------------------------------------

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void toggleExcludeGenerated() {
    _excludeGenerated = !_excludeGenerated;
    notifyListeners();
  }

  void toggleExcludeI18n() {
    _excludeI18n = !_excludeI18n;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _excludeGenerated = true;
    _excludeI18n = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Actions UI (sélection & expansion) — sur le **nœud original**
  // ---------------------------------------------------------------------------

  void expandNode(PresetTreeNode node) {
    final orig = _findByPath(_root, node.path);
    if (orig == null || !orig.isDir) return;
    orig.expanded = true;
    notifyListeners();
  }

  void collapseNode(PresetTreeNode node) {
    final orig = _findByPath(_root, node.path);
    if (orig == null || !orig.isDir) return;
    orig.expanded = false;
    notifyListeners();
  }

  void toggleNode(PresetTreeNode node) {
    final orig = _findByPath(_root, node.path);
    if (orig == null) return;

    if (orig.isDir) {
      final target = (orig.selection == SelectionState.included || orig.selection == SelectionState.partial)
          ? SelectionState.excluded
          : SelectionState.included;
      _applySelectionState(orig, target);
      _bubbleUpSelection(orig);
    } else {
      orig.selection = (orig.selection == SelectionState.included)
          ? SelectionState.excluded
          : SelectionState.included;
      _bubbleUpSelection(orig);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Extraction (pour onSave)
  // ---------------------------------------------------------------------------

  /// Ancienne méthode : retourne une liste statique de fichiers inclus.
  /// Conservée pour l’aperçu uniquement.
  List<String> buildIncludedPaths() {
    final result = <String>[];
    if (_root == null) return result;
    _collectIncludedFiltered(_root!, result);
    return result;
  }

  /// Nouvelle méthode : construit un HiveSelectionSpec dynamique.
  HiveSelectionSpec buildSelectionSpec() {
    final includeDirs = <String>[];
    final excludeDirs = <String>[];
    final includeFiles = <String>[];
    final excludeFiles = <String>[];

    if (_root != null) {
      _collectSelectionSpec(_root!, null, includeDirs, excludeDirs, includeFiles, excludeFiles);
    }

    return HiveSelectionSpec(
      includeDirs: includeDirs,
      excludeDirs: excludeDirs,
      includeFiles: includeFiles,
      excludeFiles: excludeFiles,
    );
  }

  void _collectSelectionSpec(
      PresetTreeNode node,
      SelectionState? parentState,
      List<String> includeDirs,
      List<String> excludeDirs,
      List<String> includeFiles,
      List<String> excludeFiles,
      ) {
    if (_shouldHide(node)) return;

    if (node.isDir) {
      if (node.selection == SelectionState.included && parentState != SelectionState.included) {
        includeDirs.add(node.path);
      }
      if (node.selection == SelectionState.excluded && parentState == SelectionState.included) {
        excludeDirs.add(node.path);
      }
      for (final c in node.children) {
        _collectSelectionSpec(c, node.selection, includeDirs, excludeDirs, includeFiles, excludeFiles);
      }
    } else {
      if (node.selection == SelectionState.included && parentState == SelectionState.excluded) {
        includeFiles.add(node.path);
      }
      if (node.selection == SelectionState.excluded && parentState == SelectionState.included) {
        excludeFiles.add(node.path);
      }
    }
  }

  /// Échantillon pour l’aperçu.
  List<String> sampleIncluded({int max = 20}) {
    final all = buildIncludedPaths();
    if (all.length <= max) return all;
    return all.sublist(0, max);
  }

  // ---------------------------------------------------------------------------
  // Filtrage / comptage (clones pour l’affichage)
  // ---------------------------------------------------------------------------

  PresetTreeNode? _filteredClone(PresetTreeNode node) {
    if (_shouldHide(node)) return null;

    final matchesQuery =
        _query.isEmpty || _stringMatch(node.name, _query) || _stringMatch(node.path, _query);

    if (!node.isDir) {
      return matchesQuery
          ? PresetTreeNode(
        name: node.name,
        path: node.path,
        isDir: false,
        children: const [],
        expanded: node.expanded,
        selection: node.selection,
      )
          : null;
    }

    final filteredChildren = <PresetTreeNode>[];
    for (final c in node.children) {
      final fc = _filteredClone(c);
      if (fc != null) filteredChildren.add(fc);
    }

    if (matchesQuery || filteredChildren.isNotEmpty) {
      return PresetTreeNode(
        name: node.name,
        path: node.path,
        isDir: true,
        children: filteredChildren,
        expanded: node.expanded,
        selection: node.selection,
      );
    }
    return null;
  }

  int _countFilesFiltered(PresetTreeNode node) {
    if (_shouldHide(node)) return 0;
    if (!node.isDir) return 1;
    var sum = 0;
    for (final c in node.children) {
      sum += _countFilesFiltered(c);
    }
    return sum;
  }

  int _countIncludedFiltered(PresetTreeNode node) {
    if (_shouldHide(node)) return 0;
    if (!node.isDir) return node.selection == SelectionState.included ? 1 : 0;
    var sum = 0;
    for (final c in node.children) {
      sum += _countIncludedFiltered(c);
    }
    return sum;
  }

  void _collectIncludedFiltered(PresetTreeNode node, List<String> out) {
    if (_shouldHide(node)) return;
    if (!node.isDir) {
      if (node.selection == SelectionState.included) out.add(node.path);
      return;
    }
    for (final c in node.children) {
      _collectIncludedFiltered(c, out);
    }
  }

  // ---------------------------------------------------------------------------
  // Sélection tri-état (calcul parent)
  // ---------------------------------------------------------------------------

  void _applySelectionState(PresetTreeNode node, SelectionState state) {
    node.selection = state;
    if (node.isDir) {
      for (final c in node.children) {
        _applySelectionState(c, state);
      }
    }
  }

  void _bubbleUpSelection(PresetTreeNode node) {
    final parents = _findParents(_root, node.path);
    for (var i = parents.length - 1; i >= 0; i--) {
      final p = parents[i];
      if (!p.isDir) continue;
      var hasInc = false;
      var hasExc = false;
      for (final c in p.children) {
        if (c.selection == SelectionState.partial) {
          hasInc = true;
          hasExc = true;
          break;
        }
        if (c.selection == SelectionState.included) hasInc = true;
        if (c.selection == SelectionState.excluded) hasExc = true;
        if (hasInc && hasExc) break;
      }
      p.selection = (hasInc && hasExc)
          ? SelectionState.partial
          : (hasInc ? SelectionState.included : SelectionState.excluded);
    }
  }

  List<PresetTreeNode> _findParents(PresetTreeNode? root, String childPath) {
    final stack = <PresetTreeNode>[];
    bool dfs(PresetTreeNode n) {
      if (n.path == childPath) return true;
      if (!n.isDir) return false;
      for (final c in n.children) {
        stack.add(n);
        final found = dfs(c);
        if (found) return true;
        stack.removeLast();
      }
      return false;
    }

    if (root == null) return const [];
    dfs(root);
    return List<PresetTreeNode>.from(stack);
  }

  PresetTreeNode? _findByPath(PresetTreeNode? root, String targetPath) {
    if (root == null) return null;
    if (root.path == targetPath) return root;
    if (!root.isDir) return null;
    for (final c in root.children) {
      final r = _findByPath(c, targetPath);
      if (r != null) return r;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _shouldHide(PresetTreeNode node) {
    if (_root != null && identical(node, _root)) return false;

    final name = node.name.toLowerCase();
    final pathLower = node.path.replaceAll('\\', '/').toLowerCase();

    if (_excludeGenerated) {
      if (node.isDir && (name == 'build' || name == '.dart_tool' || name == '.git' || name == '.idea')) {
        return true;
      }
      if (!node.isDir &&
          (name.endsWith('.g.dart') ||
              name.endsWith('.freezed.dart') ||
              name.endsWith('.gen.dart') ||
              name.endsWith('.mocks.dart'))) {
        return true;
      }
    }

    if (_excludeI18n) {
      if (node.isDir) {
        if (name == 'l10n' || name == 'i18n' || name == 'translations' || name == 'gen_l10n') {
          return true;
        }
        if (pathLower.contains('/.dart_tool/flutter_gen/gen_l10n')) {
          return true;
        }
      } else {
        if (name.endsWith('.arb') || name.endsWith('.po') || name.endsWith('.mo')) {
          return true;
        }
        if (_isL10nGeneratedDart(pathLower, name)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isL10nGeneratedDart(String pathLower, String nameLower) {
    if (nameLower == 'app_localizations.dart') return true;
    if (nameLower.startsWith('app_localizations_') && nameLower.endsWith('.dart')) return true;
    if (pathLower.contains('/.dart_tool/flutter_gen/gen_l10n/')) return true;
    if ((nameLower == 'l10n.dart' || nameLower == 's.dart') && pathLower.contains('/generated/')) {
      return true;
    }
    if (nameLower.startsWith('messages_') && nameLower.endsWith('.dart') && pathLower.contains('/intl/')) {
      return true;
    }
    if (pathLower.contains('/gen_l10n/') && nameLower.endsWith('.dart')) return true;
    return false;
  }

  bool _stringMatch(String haystack, String needle) {
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }

  static String _basename(String path) {
    final norm = path.replaceAll('\\', '/');
    final idx = norm.lastIndexOf('/');
    return idx >= 0 ? norm.substring(idx + 1) : norm;
  }

  // ---------------------------------------------------------------------------
  // Construction d’arbre (compute)
  // ---------------------------------------------------------------------------

  static PresetTreeNode _buildTreeSync(String projectRoot) {
    final rootDir = Directory(projectRoot);
    final children = <PresetTreeNode>[];

    if (!rootDir.existsSync()) {
      return PresetTreeNode(
        name: _basename(projectRoot),
        path: projectRoot,
        isDir: true,
        children: const [],
        expanded: true,
        selection: SelectionState.excluded,
      );
    }

    final entities = rootDir.listSync(recursive: false, followLinks: false);
    final dirs = <Directory>[];
    final files = <File>[];

    for (final e in entities) {
      if (e is Directory) {
        dirs.add(e);
      } else if (e is File) {
        files.add(e);
      }
    }

    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    for (final d in dirs) {
      children.add(_dirNode(d));
    }
    for (final f in files) {
      children.add(_fileNode(f));
    }

    return PresetTreeNode(
      name: _basename(projectRoot),
      path: projectRoot,
      isDir: true,
      children: children,
      expanded: true,
      selection: SelectionState.excluded,
    );
  }

  static PresetTreeNode _dirNode(Directory d) {
    final entries = d.listSync(recursive: false, followLinks: false);
    final dirs = <Directory>[];
    final files = <File>[];

    for (final e in entries) {
      if (e is Directory) {
        dirs.add(e);
      } else if (e is File) {
        files.add(e);
      }
    }

    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    final children = <PresetTreeNode>[];
    for (final sd in dirs) {
      children.add(_dirNode(sd));
    }
    for (final f in files) {
      children.add(_fileNode(f));
    }

    return PresetTreeNode(
      name: _basename(d.path),
      path: d.path,
      isDir: true,
      children: children,
      expanded: false,
      selection: SelectionState.excluded,
    );
  }

  static PresetTreeNode _fileNode(File f) {
    return PresetTreeNode(
      name: _basename(f.path),
      path: f.path,
      isDir: false,
      children: const [],
      expanded: false,
      selection: SelectionState.excluded,
    );
  }
}
