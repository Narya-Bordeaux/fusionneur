// Service qui génère un fichier fusionné en "silencieux", calcule un hash,
// compare avec le fichier final, puis garde ou supprime en fonction.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fusionneur/core/utils/path_utils.dart';
import 'package:fusionneur/services/concatenator.dart';

/// Décision finale du guard.
enum HashGuardDecision {
  skippedIdentical, // contenu identique : on n'écrit pas le final
  committed,        // on a remplacé/écrit le final avec le .tmp
  dryRunDifferent,  // dry-run : différence détectée, rien écrit
}

/// Résultat structuré pour affichage/CLI.
class HashGuardResult {
  final HashGuardDecision decision;
  final String currentHash;   // hash du fichier .tmp (ou du final si committed)
  final String? previousHash; // hash du final avant remplacement (s'il existait)
  final String tempPath;
  final String finalPath;
  final bool changed;

  const HashGuardResult({
    required this.decision,
    required this.currentHash,
    required this.previousHash,
    required this.tempPath,
    required this.finalPath,
    required this.changed,
  });

  @override
  String toString() =>
      'HashGuardResult(decision=$decision, changed=$changed, current=$currentHash, previous=$previousHash, final=$finalPath, temp=$tempPath)';
}

/// Service de "hash guard" : écrit un fichier temporaire, calcule un hash,
/// compare au fichier final existant, puis garde/supprime selon force/dryRun.
class HashGuardService {
  final Concatenator _concatenator;

  HashGuardService({Concatenator? concatenator})
      : _concatenator = concatenator ?? Concatenator();

  /// Exécute la fusion protégée par hash.
  ///
  /// [projectRoot] : racine du projet à concaténer.
  /// [finalPath]   : chemin du fichier final (ex: ".../fusion.md").
  /// [tempPath]    : chemin temporaire (ex: ".../fusion.tmp.md").
  /// [options]     : mêmes options que pour Concatenator.
  /// [force]       : si true, on écrit même si identique.
  /// [dryRun]      : si true, on ne remplace jamais le final (affiche/retourne juste la décision).
  Future<HashGuardResult> guardAndMaybeCommitFusion({
    required String projectRoot,
    required String finalPath,
    required String tempPath,
    ConcatenationOptions options = const ConcatenationOptions(),
    bool force = false,
    bool dryRun = false,
  }) async {
    // 1) Écrire le fichier temporaire "réel"
    await _ensureDirExists(PathUtils.dirname(tempPath));
    await _concatenator.writeConcatenatedFile(
      projectRoot: projectRoot,
      outputFilePath: tempPath,
      options: options,
    );

    // 2) Calculer le hash du .tmp
    final String tmpHash = await _crc32OfFileHex(tempPath);

    // 3) Lire hash précédent si fichier final existe
    String? prevHash;
    final finalFile = File(finalPath);
    if (await finalFile.exists()) {
      prevHash = await _crc32OfFileHex(finalPath);
    }

    // 4) Décision
    final bool identical = (prevHash != null && prevHash == tmpHash);

    if (identical && !force) {
      // Rien à faire : on supprime le .tmp et on retourne "skipped"
      await _safeDelete(tempPath);
      return HashGuardResult(
        decision: HashGuardDecision.skippedIdentical,
        currentHash: tmpHash,
        previousHash: prevHash,
        tempPath: tempPath,
        finalPath: finalPath,
        changed: false,
      );
    }

    if (dryRun) {
      // Différence détectée mais on n'écrit pas (demande de l'utilisateur)
      await _safeDelete(tempPath);
      return HashGuardResult(
        decision: HashGuardDecision.dryRunDifferent,
        currentHash: tmpHash,
        previousHash: prevHash,
        tempPath: tempPath,
        finalPath: finalPath,
        changed: true,
      );
    }

    // 5) Écriture/replace atomique du final (rename sur même FS)
    await _ensureDirExists(PathUtils.dirname(finalPath));
    // S'il existe déjà, on le remplace en deux temps pour rester clair :
    // - supprimer l'ancien si la plateforme ne remplace pas en place
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await File(tempPath).rename(finalPath);

    return HashGuardResult(
      decision: HashGuardDecision.committed,
      currentHash: tmpHash,
      previousHash: prevHash,
      tempPath: tempPath,
      finalPath: finalPath,
      changed: true,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers système

  Future<void> _ensureDirExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _safeDelete(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CRC32 (sans dépendance) — stable et rapide.
  //
  // NB: On pourrait passer à SHA-256 plus tard si tu ajoutes la dépendance
  // "crypto". Pour l’instant, on privilégie zéro dépendance externe.

  static const int _crc32Polynomial = 0xEDB88320;
  static final List<int> _crc32Table = _buildCrc32Table();

  static List<int> _buildCrc32Table() {
    final table = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = _crc32Polynomial ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  Future<String> _crc32OfFileHex(String path) async {
    final file = File(path);
    final raf = await file.open(mode: FileMode.read);
    try {
      const chunkSize = 1024 * 1024; // 1MB
      int crc = 0xFFFFFFFF;
      final buffer = Uint8List(chunkSize);

      while (true) {
        final read = await raf.readInto(buffer);
        if (read == 0) break;

        for (int i = 0; i < read; i++) {
          final byte = buffer[i];
          crc = _crc32Table[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
        }
      }

      crc = crc ^ 0xFFFFFFFF;
      return _toHex32(crc);
    } finally {
      await raf.close();
    }
  }

  String _toHex32(int value) {
    final s = value.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return s.toLowerCase();
  }
}
