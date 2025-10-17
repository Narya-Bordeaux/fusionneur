import 'package:fusionneur/core/tree_order.dart';
import 'package:fusionneur/core/utils/path_utils.dart';

/// Politique d'ordonnancement passée au FileOrderer.
/// - explicitOrder : un ordre imposé (liste de chemins POSIX relatifs). Les chemins
///   présents seront sortis d'abord dans cet ordre, s'ils existent dans [candidates].
/// - fallbackTree : si true, les chemins restants sont ordonnés en TREE order (défaut).
class FileOrderingPolicy {
  final List<String>? explicitOrder;
  final bool fallbackTree;

  const FileOrderingPolicy({
    this.explicitOrder,
    this.fallbackTree = true,
  });
}

/// Service d'ordonnancement : produit la liste finale ordonnée.
/// Stratégie :
/// 1) Si explicitOrder est fourni, on sélectionne d'abord l'intersection
///    explicitOrder ∩ candidates, dans l'ordre donné.
/// 2) Les restants (candidates \ explicitOrder) sont triés selon fallback :
///    - TREE order si fallbackTree == true
///    - sinon tri alpha simple (sécurité)
class FileOrderer {
  final TreeOrder _treeOrder;

  FileOrderer({TreeOrder? treeOrder}) : _treeOrder = treeOrder ?? TreeOrder();

  List<String> order({
    required List<String> candidates,
    FileOrderingPolicy policy = const FileOrderingPolicy(),
  }) {
    if (candidates.isEmpty) return const <String>[];

    // Normalise en POSIX pour cohérence
    final posix = candidates.map(PathUtils.toPosix).toList();
    final set = posix.toSet();

    final out = <String>[];

    // 1) Respecter l'ordre explicite si fourni (intersection)
    final explicit = policy.explicitOrder?.map(PathUtils.toPosix).toList();
    if (explicit != null && explicit.isNotEmpty) {
      for (final p in explicit) {
        if (set.contains(p) && !out.contains(p)) {
          out.add(p);
        }
      }
    }

    // 2) Ajouter les restants selon fallback
    final remaining = posix.where((p) => !out.contains(p)).toList();
    if (remaining.isEmpty) return out;

    if (policy.fallbackTree) {
      final treeSorted = _treeOrder.sortAsTree(remaining);
      out.addAll(treeSorted);
    } else {
      remaining.sort();
      out.addAll(remaining);
    }

    return out;
  }
}
