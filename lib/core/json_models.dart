import 'dart:convert';

import 'package:fusionneur/core/constants.dart';

/// Représente une entrée dans l'index JSON du fichier fusionné.
class FusionFileEntry {
  final int fileNumber;
  final String fileName;
  final String filePath;
  final int startLine; // -1 pendant la pass 1
  final int endLine;   // -1 pendant la pass 1
  final List<String> imports;     // éléments "N,path"
  final List<String> importedBy;  // éléments "N,path"
  final bool unused;              // drapeau bool

  const FusionFileEntry({
    required this.fileNumber,
    required this.fileName,
    required this.filePath,
    this.startLine = -1,
    this.endLine = -1,
    this.imports = const [],
    this.importedBy = const [],
    this.unused = false,
  });

  /// Copie immuable (utile pour injecter startLine/endLine en pass 2, etc.).
  FusionFileEntry copyWith({
    int? fileNumber,
    String? fileName,
    String? filePath,
    int? startLine,
    int? endLine,
    List<String>? imports,
    List<String>? importedBy,
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
    JsonKeys.unused: unused,
  };

  factory FusionFileEntry.fromJson(Map<String, dynamic> json) {
    final imports =
    List<String>.from(json[JsonKeys.imports] as List? ?? const <String>[]);
    final importedBy =
    List<String>.from(json[JsonKeys.importedBy] as List? ?? const <String>[]);

    return FusionFileEntry(
      fileNumber: json[JsonKeys.fileNumber] as int,
      fileName: json[JsonKeys.fileName] as String,
      filePath: json[JsonKeys.filePath] as String,
      startLine: (json[JsonKeys.startLine] as num?)?.toInt() ?? -1,
      endLine: (json[JsonKeys.endLine] as num?)?.toInt() ?? -1,
      imports: List.unmodifiable(imports),
      importedBy: List.unmodifiable(importedBy),
      unused: (json[JsonKeys.unused] as bool?) ?? false,
    );
  }
}

/// Conteneur pour l'index JSON complet (liste d'entrées).
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
}
