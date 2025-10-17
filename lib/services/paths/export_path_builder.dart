// Utilitaires de chemins pour les exports (partagés CLI/UI).

import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:fusionneur/data/hive/models/hive_preset.dart';

/// Retourne le dossier racine des exports (par défaut ~/.fusionneur/exports).
/// - Linux/macOS: $HOME/.fusionneur/exports
/// - Windows: %USERPROFILE%\.fusionneur\exports
/// - Surcharge possible via variable d'env "FUSIONNEUR_EXPORTS_HOME".
String exportsHome() {
  // Permettre une surcharge par variable d'environnement (optionnel, non obligatoire).
  final override = Platform.environment['FUSIONNEUR_EXPORTS_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return p.normalize(override);
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
  return p.join(home, '.fusionneur', 'exports');
}

/// Construit un sous-dossier d'export unique pour (projet, preset, timestamp[, seq]).
/// Exemple: ~/.fusionneur/exports/<projectId>/20250828_163012-default_lib-p01
///
/// [projectId] : identifiant interne du projet.
/// [preset]    : modèle preset (pour slugifier son nom).
/// [now]       : pour tests / déterminisme ; sinon DateTime.now().
/// [seq]       : séquence optionnelle (>=1) apposée en suffixe (-pNN).
///
/// La fonction **ne crée pas** le dossier ; elle retourne le chemin.
String buildExportDir({
  required String projectId,
  required HivePreset hivepreset,
  DateTime? now,
  int? seq,
}) {
  final base = exportsHome();
  final ts = timestampForFs(now ?? DateTime.now()); // YYYYMMDD_HHMMSS
  final presetSlug = slugify(hivepreset.name);
  final seqPart = (seq != null && seq > 0) ? '-p${seq.toString().padLeft(2, '0')}' : '';
  // ~/.fusionneur/exports/<projectId>/<YYYYMMDD_HHMMSS>-<presetSlug>-pNN
  return p.join(base, projectId, '$ts-$presetSlug$seqPart');
}

/// Construit le chemin du fichier de sortie dans [exportDir].
/// Par défaut, nom = "fusion.md". Tu peux fournir [fileName] si tu préfères.
///
/// La fonction **ne crée pas** le fichier ; elle retourne le chemin.
String buildOutputFilePath({
  required String exportDir,
  String fileName = 'fusion.md',
}) {
  final safe = sanitizeFilename(fileName);
  return p.join(exportDir, safe);
}

/// Propose un nom de fichier lisible et stable.
/// Exemple: <projectSlug>__<presetSlug>__<YYYYMMDD_HHMMSS>[_3].md
/// - Si [withSeq] est vrai et [seq] >=1, ajoute "_<seq>".
/// - [ext] par défaut "md".
String suggestExportFilename({
  required String projectId,
  required HivePreset hivepreset,
  DateTime? now,
  bool withSeq = false,
  int? seq,
  String ext = 'md',
}) {
  final ts = timestampForFs(now ?? DateTime.now());
  final projectSlug = slugify(projectId); // projectId déjà court → slug
  final presetSlug = slugify(hivepreset.name);
  final seqSuffix = (withSeq && seq != null && seq > 0) ? '_$seq' : '';
  final name = '${projectSlug}__${presetSlug}__${ts}$seqSuffix.$ext';
  return sanitizeFilename(name);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers

/// Formate un timestamp pour le système de fichiers : "YYYYMMDD_HHMMSS".
String timestampForFs(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final y = dt.year.toString().padLeft(4, '0');
  final m = two(dt.month);
  final d = two(dt.day);
  final h = two(dt.hour);
  final min = two(dt.minute);
  final s = two(dt.second);
  return '${y}${m}${d}_${h}${min}${s}';

}

/// Slugifie une chaîne pour utilisation dans des chemins.
/// - minuscules
/// - remplace tout caractère non [a-z0-9]+ par '-'
/// - compresse les tirets en un seul
/// - tronque à 64 chars max (précaution)
String slugify(String input) {
  final lower = input.toLowerCase();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final compressed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
  final trimmed = compressed.replaceAll(RegExp(r'^-+|-+$'), '');
  return (trimmed.length > 64) ? trimmed.substring(0, 64) : trimmed;
}

/// Nettoie un nom de fichier (garde l'extension s'il y en a une).
String sanitizeFilename(String name) {
  // Sépare extension si présente
  final ext = p.extension(name);
  final base = ext.isEmpty ? name : name.substring(0, name.length - ext.length);

  // Sanitize base et extension (extension: lettres/chiffres + point)
  final safeBase = slugify(base);
  final safeExt = ext.replaceAll(RegExp(r'[^.a-zA-Z0-9]'), '');

  return safeExt.isEmpty ? safeBase : '$safeBase$safeExt';
}
