// Service unique qui produit le fichier concaténé en 2 passes.

import 'dart:io';

import 'package:fusionneur/core/constants.dart';
import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:fusionneur/core/json_models.dart';
import 'package:fusionneur/core/glob_matcher.dart';

import 'package:fusionneur/services/file_scanner.dart';
import 'package:fusionneur/services/file_filter.dart';


// Parts factorisés pour l'orchestration des sections
import 'package:fusionneur/services/concatenator_parts/manifest_writer.dart';
import 'package:fusionneur/services/concatenator_parts/json_index_writer.dart';
import 'package:fusionneur/services/concatenator_parts/file_orderer.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart';
import 'package:fusionneur/services/concatenator_parts/numbering_service.dart';
import 'package:fusionneur/services/concatenator_parts/unused_tagger.dart';
import 'package:fusionneur/services/concatenator_parts/section_markers_writer.dart';
import 'package:fusionneur/services/concatenator_parts/code_section_writer.dart';
import 'package:fusionneur/services/concatenator_parts/json_index_finalizer.dart';
import 'package:fusionneur/services/concatenator_parts/import_graph_utils.dart';
import 'package:fusionneur/services/concatenator_parts/index_provisional_builder.dart';

class ConcatenationOptions {
  final String subDir; // legacy (peut être ignoré si selectionSpec est fourni)
  final bool onlyDart;
  final List<String>? excludePatterns;
  final NumberingStrategy numbering;

  /// Hook pour calculer les imports internes.
  final Future<Map<String, Set<String>>> Function(List<String> files)? computeImports;

  /// Hook pour calculer les exports (barrels).
  final Future<Map<String, Set<String>>> Function(List<String> files)? computeExports;

  /// Politique d’ordre (TREE par défaut).
  final FileOrderingPolicy fileOrderingPolicy;

  /// Sélection déclarative (multi-dossiers/fichiers, exclusions).
  final SelectionSpec selectionSpec;

  const ConcatenationOptions({
    this.subDir = 'lib',
    this.onlyDart = false,
    this.excludePatterns,
    this.numbering = NumberingStrategy.sortedAlpha,
    this.computeImports,
    this.computeExports,
    this.fileOrderingPolicy = const FileOrderingPolicy(
      explicitOrder: null,
      fallbackTree: true,
    ),
    this.selectionSpec = const SelectionSpec(includeDirs: ['lib']),
  });
}

/// Service unique qui produit le fichier concaténé.
/// Effectue deux passes internes: écriture provisoire puis mise à jour du JSON index.
class Concatenator {
  final FileScanner _scanner;

  // Writers factorisés
  final ManifestWriter _manifestWriter;
  final JsonIndexWriter _jsonIndexWriter;

  // Service d’ordonnancement (TREE par défaut)
  final FileOrderer _fileOrderer;

  // Orchestration des sections
  final SectionMarkersWriter _sectionMarkersWriter;
  final CodeSectionWriter _codeSectionWriter;

  // Pass 2 factorisée
  final JsonIndexFinalizer _jsonIndexFinalizer;

  Concatenator({
    FileScanner? scanner,
    FileFilter? filter,
    ManifestWriter? manifestWriter,
    JsonIndexWriter? jsonIndexWriter,
    FileOrderer? fileOrderer,
    SectionMarkersWriter? sectionMarkersWriter,
    CodeSectionWriter? codeSectionWriter,
    JsonIndexFinalizer? jsonIndexFinalizer,
  })  : _scanner = scanner ?? FileScanner(),
        _manifestWriter = manifestWriter ?? const ManifestWriter(),
        _jsonIndexWriter = jsonIndexWriter ?? const JsonIndexWriter(),
        _fileOrderer = fileOrderer ?? FileOrderer(),
        _sectionMarkersWriter = sectionMarkersWriter ?? const SectionMarkersWriter(),
        _codeSectionWriter = codeSectionWriter ?? const CodeSectionWriter(),
        _jsonIndexFinalizer = jsonIndexFinalizer ?? const JsonIndexFinalizer();

  /// Génère le fichier concaténé en 2 passes :
  /// - sélection + filter + order + numéroter
  /// - écrire MANIFEST + JSON provisoire + blocs code
  /// - rescanner les bannières pour start/end, réécrire JSON index (dernier bloc)
  Future<void> writeConcatenatedFile({
    required String projectRoot,
    required String outputFilePath,
    ConcatenationOptions options = const ConcatenationOptions(),
  }) async {
    // 1) Sélection déclarative (multi-dossiers, fichiers, exclusions)
    final selected = await FileSelectionResolver(scanner: _scanner).resolve(
      projectRoot: projectRoot,
      spec: options.selectionSpec,
    );
    if (selected.isEmpty) {
      throw StateError('No files selected (selectionSpec resulted in empty list).');
    }

    // 2) Filtre (patterns + onlyDart)
    final filter = FileFilter(
      // si excludePatterns est null, on laisse le matcher à null
      excludeMatcher: options.excludePatterns != null
          ? GlobMatcher(excludePatterns: options.excludePatterns)
          : null,
      // respecter l’option pour ne PAS exclure pubspec.yaml quand onlyDart=false
      onlyDart: options.onlyDart,
    );

    final filtered = filter.apply(selected);
    if (filtered.isEmpty) {
      throw StateError('No files to concatenate after filtering.');
    }

    // 3) Ordonnancement (ordre explicite optionnel + fallback TREE)
    final ordered = _fileOrderer.order(
      candidates: filtered,
      policy: options.fileOrderingPolicy,
    );

    // 4) Numérotation selon l'ordre retenu
    final numbering = const NumberingService().build(ordered);

    // === ImportGraph hook BEGIN ===
    final importsMap = await options.computeImports?.call(ordered) ?? <String, Set<String>>{};
    final exportsMap = await options.computeExports?.call(ordered) ?? <String, Set<String>>{};

    // inversion du graphe pour obtenir importedBy
    final importedByMap = const ImportGraphUtils()
        .reverseEdges(files: ordered, importsMap: importsMap);

    // 🔹 calcul des fichiers inutilisés (pour tag ::FUSION::unused + bool unused)
    final unused = await UnusedTagger().computeUnused(
      files: ordered,
      importsMap: importsMap,
      exportsMap: exportsMap,
      projectRoot: projectRoot,
    );
    // === ImportGraph hook END ===

    // 5) Construire l'index provisoire (start/end = -1) via service dédié
    final provisionalIndex = const IndexProvisionalBuilder().build(
      ordered: ordered,
      numbering: numbering,
      importsMap: importsMap,
      importedByMap: importedByMap,
      unusedPaths: unused,
    );

    // 6) PASS 1: écrire le fichier provisoire
    await _writeProvisional(
      projectRoot: projectRoot,
      outputFilePath: outputFilePath,
      index: provisionalIndex,
      files: ordered,
      numbering: numbering,
    );

    // 7) PASS 2: relire, remplir start/end, réécrire JSON (dernier bloc)
    await _jsonIndexFinalizer.finalize(
      outputFilePath: outputFilePath,
      provisionalIndex: provisionalIndex,
      unusedPaths: unused, // préserver le flag si regenerateTags réécrit les tags
      pretty: true,
    );
  }

  /// Écrit MANIFEST + JSON provisoire + CODE SECTION (déléguée).
  Future<void> _writeProvisional({
    required String projectRoot,
    required String outputFilePath,
    required FusionIndex index,
    required List<String> files,
    required Map<String, int> numbering,
  }) async {
    final out = File(outputFilePath);
    final sink = out.openWrite();

    // MANIFEST (anglais ; généré par ManifestWriter, sans données volatiles)
    final info = ManifestInfo(
      projectName: PathUtils.basename(projectRoot),
      formatVersion: 'Fusion v3',
    );
    _manifestWriter.writeTo(sink, info);

    // SECTION marker réel du JSON index
    _sectionMarkersWriter.writeJsonIndexMarker(sink);

    // JSON index (provisoire)
    sink.writeln(SectionDelimiters.jsonBegin);
    _jsonIndexWriter.writeDelimitedToSink(
      sink: sink,
      index: index,
      pretty: true,
    );
    sink.writeln(SectionDelimiters.jsonEnd);
    sink.writeln(); // ligne vide de séparation

    // SECTION marker réel de la CODE SECTION
    _sectionMarkersWriter.writeCodeSectionMarker(sink);

    // CODE SECTION (bannières + tag line + fences + contenu)
    await _codeSectionWriter.write(
      out: sink,
      projectRoot: projectRoot,
      orderedFiles: files,
      numbering: numbering,
    );

    await sink.flush();
    await sink.close();
  }
}
