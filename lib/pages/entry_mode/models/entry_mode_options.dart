// Modèle d’options pour le mode Entrypoint.
// Permet de configurer le comportement de la fusion autour d’un fichier d’entrée.

import 'package:flutter/foundation.dart';

@immutable
class EntryModeOptions {
  /// Inclure les fichiers qui importent directement le fichier d’entrée
  /// (imported-by une seule fois).
  final bool includeImportedByOnce;

  /// Exclure les fichiers générés automatiquement (ex: *.g.dart)
  final bool excludeGenerated;

  /// Exclure les fichiers de localisation (ex: *.arb)
  final bool excludeI18n;

  const EntryModeOptions({
    this.includeImportedByOnce = false,
    this.excludeGenerated = false,
    this.excludeI18n = false,
  });

  /// Copie immuable avec modification sélective.
  EntryModeOptions copyWith({
    bool? includeImportedByOnce,
    bool? excludeGenerated,
    bool? excludeI18n,
  }) {
    return EntryModeOptions(
      includeImportedByOnce:
      includeImportedByOnce ?? this.includeImportedByOnce,
      excludeGenerated: excludeGenerated ?? this.excludeGenerated,
      excludeI18n: excludeI18n ?? this.excludeI18n,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntryModeOptions &&
        other.includeImportedByOnce == includeImportedByOnce &&
        other.excludeGenerated == excludeGenerated &&
        other.excludeI18n == excludeI18n;
  }

  @override
  int get hashCode =>
      Object.hash(includeImportedByOnce, excludeGenerated, excludeI18n);

  @override
  String toString() {
    return 'EntryModeOptions('
        'includeImportedByOnce: $includeImportedByOnce, '
        'excludeGenerated: $excludeGenerated, '
        'excludeI18n: $excludeI18n'
        ')';
  }
}
