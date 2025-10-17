import 'dart:io';
import 'package:path/path.dart' as p;

/// Type de nœud dans l’arborescence scannée.
enum FsNodeKind { dir, file, pseudo }

/// Nœud de l’arbre de fichiers (indépendant de l’UI).
class FsNode {
  final String name;          // affiché (basename)
  final String relPath;       // chemin relatif au projectRoot ('.' pour la racine)
  final FsNodeKind kind;      // dir/file/pseudo
  final List<FsNode> children;

  const FsNode({
    required this.name,
    required this.relPath,
    required this.kind,
    this.children = const <FsNode>[],
  });

  bool get isDir => kind == FsNodeKind.dir || kind == FsNodeKind.pseudo;
  bool get isFile => kind == FsNodeKind.file;

  FsNode copyWith({
    String? name,
    String? relPath,
    FsNodeKind? kind,
    List<FsNode>? children,
  }) {
    return FsNode(
      name: name ?? this.name,
      relPath: relPath ?? this.relPath,
      kind: kind ?? this.kind,
      children: children ?? this.children,
    );
  }
}

/// Service de scan de projet (filesystem → arborescence neutre FsNode).
class ProjectTreeService {
  /// Dossiers à ignorer partout.
  static const Set<String> _ignoredDirs = {
    'build',
    '.dart_tool',
    '.git',
    '.idea',
    '.vscode',
    '.fvm',
    '.gradle',
  };

  /// Fichiers "racine" souvent utiles dans un preset.
  static const Set<String> _interestingRootFiles = {
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    'analysis_options.yaml',
  };

  /// Fichiers de configuration groupés dans un pseudo-dossier "Config".
  static const List<String> _configFiles = [
    'pubspec.yaml',
    'android/app/src/main/AndroidManifest.xml',
    'ios/Runner/Info.plist',
    'web/index.html',
  ];

  /// Scanne le projet et renvoie une racine FsNode (dir) :
  /// - children: pseudo "Config" (si fichiers présents) + dossiers + fichiers racine.
  static Future<FsNode> scanProjectTree(String projectRoot) async {
    final rootDir = Directory(projectRoot);
    if (!rootDir.existsSync()) {
      throw ArgumentError('Project root does not exist: $projectRoot');
    }

    // 1) Pseudo-dossier Config
    final configChildren = <FsNode>[];
    for (final rel in _configFiles) {
      final abs = p.normalize(p.join(projectRoot, rel));
      final f = File(abs);
      if (f.existsSync()) {
        configChildren.add(FsNode(
          name: p.basename(rel),
          relPath: rel.replaceAll('\\', '/'),
          kind: FsNodeKind.file,
        ));
      }
    }
    final configNode = configChildren.isEmpty
        ? null
        : FsNode(
      name: 'Config',
      relPath: 'config', // chemin logique (pas réel)
      kind: FsNodeKind.pseudo,
      children: configChildren,
    );

    // 2) Dossiers & fichiers de la racine
    final rootChildren = <FsNode>[];

    // Fichiers racine intéressants
    for (final name in _interestingRootFiles) {
      final abs = p.join(projectRoot, name);
      if (File(abs).existsSync()) {
        rootChildren.add(FsNode(
          name: name,
          relPath: name,
          kind: FsNodeKind.file,
        ));
      }
    }

    // Dossiers de la racine (lib/, test/, l10n/, etc.)
    final dirList = rootDir
        .listSync(followLinks: false)
        .whereType<Directory>()
        .where((d) => !_ignoredDirs.contains(p.basename(d.path)))
        .toList()
      ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
        p.basename(b.path).toLowerCase(),
      ));

    for (final d in dirList) {
      final rel = p.relative(d.path, from: projectRoot).replaceAll('\\', '/');
      final node = await _scanDirRecursive(projectRoot, rel);
      rootChildren.add(node);
    }

    // Fichiers racine supplémentaires (non listés dans _interestingRootFiles)
    final fileList = rootDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => !_interestingRootFiles.contains(p.basename(f.path)))
        .toList()
      ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
        p.basename(b.path).toLowerCase(),
      ));
    for (final f in fileList) {
      final rel = p.relative(f.path, from: projectRoot).replaceAll('\\', '/');
      rootChildren.add(FsNode(
        name: p.basename(rel),
        relPath: rel,
        kind: FsNodeKind.file,
      ));
    }

    // Insérer Config en tête si présent
    if (configNode != null) {
      rootChildren.insert(0, configNode);
    }

    return FsNode(
      name: p.basename(projectRoot),
      relPath: '.',
      kind: FsNodeKind.dir,
      children: rootChildren,
    );
  }

  /// Scan récursif d’un dossier (relatif à projectRoot) → FsNode(dir).
  static Future<FsNode> _scanDirRecursive(
      String projectRoot,
      String relDir,
      ) async {
    final absDir = p.normalize(p.join(projectRoot, relDir));
    final dir = Directory(absDir);
    final entries = <FsNode>[];

    final list = dir.listSync(recursive: false, followLinks: false).toList();

    // Dossiers
    final dirs = list
        .whereType<Directory>()
        .where((d) => !_ignoredDirs.contains(p.basename(d.path)))
        .toList()
      ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
        p.basename(b.path).toLowerCase(),
      ));

    for (final d in dirs) {
      final childRel = p
          .relative(d.path, from: projectRoot)
          .replaceAll('\\', '/'); // sous-dossier
      final child = await _scanDirRecursive(projectRoot, childRel);
      entries.add(child);
    }

    // Fichiers
    final files = list.whereType<File>().toList()
      ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
        p.basename(b.path).toLowerCase(),
      ));

    for (final f in files) {
      final childRel =
      p.relative(f.path, from: projectRoot).replaceAll('\\', '/');
      entries.add(FsNode(
        name: p.basename(childRel),
        relPath: childRel,
        kind: FsNodeKind.file,
      ));
    }

    return FsNode(
      name: p.basename(relDir),
      relPath: relDir,
      kind: FsNodeKind.dir,
      children: entries,
    );
  }
}
