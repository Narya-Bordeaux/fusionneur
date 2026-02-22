// Écrit la CODE SECTION (bannières, fences, contenu).

import 'dart:io';

import 'package:fusionneur/core/constants.dart'; // pour FileBanner
import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:fusionneur/services/concatenator_parts/code_fence_resolver.dart';

class CodeSectionWriter {
  final CodeFenceResolver fenceResolver;

  const CodeSectionWriter({
    this.fenceResolver = const CodeFenceResolver(),
  });

  /// Écrit la CODE SECTION complète.
  ///
  /// - [out] : StringSink d'écriture (ex: IOSink de File.openWrite()).
  /// - [projectRoot] : racine du projet (pour lire les fichiers).
  /// - [orderedFiles] : chemins relatifs POSIX des fichiers, dans l'ordre final.
  /// - [numbering] : map path -> numéro 1..N.
  Future<void> write({
    required StringSink out,
    required String projectRoot,
    required List<String> orderedFiles,
    required Map<String, int> numbering,
  }) async {
    for (final path in orderedFiles) {
      final n = numbering[path]!;
      final fileName = PathUtils.basename(path);

      // 1) Bannière
      final banner = FileBanner.build(n, path);
      out.writeln(banner);

      // 2) Fence d'ouverture avec langage résolu
      final lang = fenceResolver.languageFor(fileName);
      out.writeln('```$lang');

      // 3) Contenu du fichier
      final abs = PathUtils.join(projectRoot, path);
      final content = await File(abs).readAsString();
      out.write(content);
      if (!content.endsWith('\n')) {
        out.writeln(); // assurer fin de ligne
      }

      // 4) Fence de fermeture, bannière de fin explicite, ligne vide
      out.writeln('```');
      out.writeln(FileEndBanner.build(n));
      out.writeln();
    }

    // Rien à flush/close ici : c'est le propriétaire du sink qui gère la ressource.
  }
}
