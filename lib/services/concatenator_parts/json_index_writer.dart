import 'dart:io';

import 'package:fusionneur/core/json_models.dart';

/// Sérialise l'index JSON (provisoire ou final) entre les délimiteurs normalisés.
/// Conçu pour être appelé par le Concatenator (orchestrateur).
class JsonIndexWriter {
  const JsonIndexWriter();

  /// Écrit l'index délimité dans un IOSink (ex: celui du fichier de sortie ouvert en écriture).
  ///
  /// Exemple d'usage dans le Concatenator:
  ///   sink.writeln(SectionDelimiters.jsonBegin);
  ///   writer.writeDelimitedToSink(sink: sink, index: index);
  ///   sink.writeln(SectionDelimiters.jsonEnd);
  void writeDelimitedToSink({
    required IOSink sink,
    required FusionIndex index,
    bool pretty = true,
  }) {
    final json = index.toJsonString(pretty: pretty);
    sink.writeln(json);
  }

  /// Construit la représentation JSON en String (utile pour tests ou logs).
  String buildJsonString(FusionIndex index, {bool pretty = true}) {
    return index.toJsonString(pretty: pretty);
  }
}
