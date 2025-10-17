import 'package:fusionneur/core/utils/path_utils.dart';

/// Produit un ordre "TREE": dossiers A→Z, puis fichiers A→Z, en profondeur.
class TreeOrder {
  /// [paths] : chemins POSIX relatifs (ex: 'lib/feat/a.dart').
  List<String> sortAsTree(List<String> paths) {
    final posix = paths.map(PathUtils.toPosix).toList();

    final dirNodes = <String, _DirNode>{};
    _DirNode _node(String dir) => dirNodes.putIfAbsent(dir, () => _DirNode(dir));

    for (final p in posix) {
      final dir = PathUtils.dirname(p); // '' si racine
      final fileName = PathUtils.basename(p);
      _node(dir).files.add(fileName);

      // relier dir à ses parents jusqu’à la racine
      var d = dir;
      while (d.isNotEmpty) {
        _node(d);
        final parent = PathUtils.dirname(d);
        _node(parent).dirs.add(d);
        if (parent == d) break;
        d = parent;
      }
      if (dir.isNotEmpty) {
        final parent = PathUtils.dirname(dir);
        _node(parent).dirs.add(dir);
      }
    }

    for (final n in dirNodes.values) {
      n.dirs = n.dirs.toSet().toList()..sort();
      n.files = n.files.toSet().toList()..sort();
    }

    final out = <String>[];
    void dfs(String dir) {
      final n = dirNodes[dir];
      if (n == null) return;
      for (final d in n.dirs) {
        dfs(d);
      }
      for (final f in n.files) {
        out.add(dir.isEmpty ? f : '$dir/$f');
      }
    }

    dfs('');
    return out;
  }
}

class _DirNode {
  final String dir;
  List<String> dirs = <String>[];
  List<String> files = <String>[];
  _DirNode(this.dir);
}
