import 'dart:collection';
import 'dart:convert';

import 'package:fusionneur/core/constants.dart';

/// Représente une référence "N,path" présente dans imports/importedBy.
/// Exemple: "12,lib/features/foo.dart"
class _LinkRef {
  final int number;     // N (fileNumber de l'autre fichier)
  final String path;    // chemin POSIX relatif
  final String name;    // basename (ex: foo.dart)

  _LinkRef(this.number, this.path, this.name);

  /// Parse une chaîne "N,path" en _LinkRef. Retourne null si format invalide.
  static _LinkRef? parse(String s) {
    final comma = s.indexOf(',');
    if (comma <= 0 || comma >= s.length - 1) return null;
    final nStr = s.substring(0, comma).trim();
    final p = s.substring(comma + 1).trim();
    final n = int.tryParse(nStr);
    if (n == null || p.isEmpty) return null;
    final lastSlash = p.lastIndexOf('/');
    final fileName = lastSlash >= 0 ? p.substring(lastSlash + 1) : p;
    return _LinkRef(n, p, fileName);
    // NB: on ne tente pas de normaliser davantage ici (déjà POSIX dans nos conventions).
  }
}

/// Représente une entrée dans l’index JSON du fichier fusionné.
class FusionFileEntry {
  final int fileNumber;
  final String fileName;
  final String filePath;
  final int startLine; // -1 pendant la pass 1
  final int endLine;   // -1 pendant la pass 1
  final List<String> imports;     // éléments "N,path"
  final List<String> importedBy;  // éléments "N,path"
  final List<String> fusionTags;  // tags ::FUSION::... (générés + conservés)
  final bool unused;              // drapeau bool complémentaire au tag ::FUSION::unused

  const FusionFileEntry({
    required this.fileNumber,
    required this.fileName,
    required this.filePath,
    this.startLine = -1,
    this.endLine = -1,
    this.imports = const [],
    this.importedBy = const [],
    this.fusionTags = const [],
    this.unused = false,
  });

  /// Construit une entrée en générant automatiquement les fusionTags
  /// à partir de fileNumber/fileName et des imports/importedBy.
  factory FusionFileEntry.withAutoTags({
    required int fileNumber,
    required String fileName,
    required String filePath,
    int startLine = -1,
    int endLine = -1,
    List<String> imports = const [],
    List<String> importedBy = const [],
    bool unused = false,
  }) {
    final entry = FusionFileEntry(
      fileNumber: fileNumber,
      fileName: fileName,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      imports: List.unmodifiable(imports),
      importedBy: List.unmodifiable(importedBy),
      fusionTags: const [],
      unused: unused,
    );
    return entry._withGeneratedTags(preserveExisting: false);
  }

  /// Recalcule les tags à partir des données **en préservant** ceux déjà présents.
  /// (Ex.: conserve ::FUSION::unused si déjà injecté en amont.)
  FusionFileEntry _withGeneratedTags({bool preserveExisting = true}) {
    final set = LinkedHashSet<String>();

    if (preserveExisting && fusionTags.isNotEmpty) {
      set.addAll(fusionTags);
    }

    // Tags JSON pour CE fichier
    set.add(FusionTags.byName(FusionTags.json, fileName));
    set.add(FusionTags.byNumber(FusionTags.json, fileNumber));

    // Tags IMPORT (pour chaque fichier que CE fichier importe)
    for (final s in imports) {
      final ref = _LinkRef.parse(s);
      if (ref == null) continue;
      set.add(FusionTags.byName(FusionTags.import, ref.name));
      set.add(FusionTags.byNumber(FusionTags.import, ref.number));
    }

    // Tags IMPORTED (pour chaque fichier qui importe CE fichier)
    for (final s in importedBy) {
      final ref = _LinkRef.parse(s);
      if (ref == null) continue;
      set.add(FusionTags.byName(FusionTags.imported, ref.name));
      set.add(FusionTags.byNumber(FusionTags.imported, ref.number));
    }

    // (Le flag ::FUSION::unused est géré par l'orchestrateur ; s'il était
    // déjà présent, il est conservé ci-dessus via preserveExisting=true.)

    return copyWith(fusionTags: List.unmodifiable(set));
  }

  /// Copie immuable (utile pour injecter startLine/endLine en pass 2, etc.).
  FusionFileEntry copyWith({
    int? fileNumber,
    String? fileName,
    String? filePath,
    int? startLine,
    int? endLine,
    List<String>? imports,
    List<String>? importedBy,
    List<String>? fusionTags,
    bool? unused,
  }) {
    return FusionFileEntry(
      fileNumber: fileNumber ?? this.fileNumber,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      imports: imports != null ? List.unmodifiable(imports) : this.imports,
      importedBy:
      importedBy != null ? List.unmodifiable(importedBy) : this.importedBy,
      fusionTags:
      fusionTags != null ? List.unmodifiable(fusionTags) : this.fusionTags,
      unused: unused ?? this.unused,
    );
  }

  Map<String, dynamic> toJson() => {
    JsonKeys.fileNumber: fileNumber,
    JsonKeys.fileName: fileName,
    JsonKeys.filePath: filePath,
    JsonKeys.startLine: startLine,
    JsonKeys.endLine: endLine,
    JsonKeys.imports: imports,
    JsonKeys.importedBy: importedBy,
    JsonKeys.fusionTags: fusionTags,
    JsonKeys.unused: unused,
  };

  factory FusionFileEntry.fromJson(Map<String, dynamic> json) {
    final imports =
    List<String>.from(json[JsonKeys.imports] as List? ?? const <String>[]);
    final importedBy =
    List<String>.from(json[JsonKeys.importedBy] as List? ?? const <String>[]);
    final fusionTags =
    List<String>.from(json[JsonKeys.fusionTags] as List? ?? const <String>[]);

    return FusionFileEntry(
      fileNumber: json[JsonKeys.fileNumber] as int,
      fileName: json[JsonKeys.fileName] as String,
      filePath: json[JsonKeys.filePath] as String,
      startLine: (json[JsonKeys.startLine] as num?)?.toInt() ?? -1,
      endLine: (json[JsonKeys.endLine] as num?)?.toInt() ?? -1,
      imports: List.unmodifiable(imports),
      importedBy: List.unmodifiable(importedBy),
      fusionTags: List.unmodifiable(fusionTags),
      unused: (json[JsonKeys.unused] as bool?) ?? false,
    );
  }

  /// Utilitaire: renvoie une version avec tags régénérés (et conservés).
  FusionFileEntry regenerateTags() => _withGeneratedTags(preserveExisting: true);
}

/// Conteneur pour l’index JSON complet (liste d’entrées).
class FusionIndex {
  final List<FusionFileEntry> entries;

  const FusionIndex(this.entries);

  String toJsonString({bool pretty = true}) {
    final jsonList = entries.map((e) => e.toJson()).toList();
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(jsonList)
        : jsonEncode(jsonList);
  }

  factory FusionIndex.fromJsonString(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return FusionIndex(
      list
          .map((e) => FusionFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Renvoie un nouvel index où toutes les entrées ont les tags (re)générés.
  FusionIndex regenerateAllTags() {
    return FusionIndex(entries.map((e) => e.regenerateTags()).toList());
  }
}
