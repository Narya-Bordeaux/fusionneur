// pages/entry_mode/models/entry_mode_state.dart
//
// État complet pour la feature Entrypoint Fusion.
// Contient :
// - entryFile : chemin du fichier d'entrée
// - options : options utilisateur (importeurs, etc.)
// - previewFiles : liste de fichiers sélectionnés (après preview)
// - flags : isLoadingPreview, isRunning, hasError
// - message d'erreur éventuel
// - canPreview, canRun : dérivés calculés
//
// Fournit des helpers : reset, copyWith, etc.

import 'package:fusionneur/pages/entry_mode/models/entry_mode_options.dart';

class EntryModeState {
  final String? entryFile;
  final EntryModeOptions options;

  final List<String> previewFiles;

  final bool isLoadingPreview;
  final bool isRunning;
  final bool hasError;
  final String? errorMessage;

  final bool canPreview;
  final bool canRun;

  const EntryModeState({
    required this.entryFile,
    required this.options,
    required this.previewFiles,
    required this.isLoadingPreview,
    required this.isRunning,
    required this.hasError,
    required this.errorMessage,
    required this.canPreview,
    required this.canRun,
  });

  factory EntryModeState.initial() {
    return EntryModeState(
      entryFile: null,
      options: EntryModeOptions(),
      previewFiles: [],
      isLoadingPreview: false,
      isRunning: false,
      hasError: false,
      errorMessage: null,
      canPreview: false,
      canRun: false,
    );
  }

  EntryModeState copyWith({
    String? entryFile,
    EntryModeOptions? options,
    List<String>? previewFiles,
    bool? isLoadingPreview,
    bool? isRunning,
    bool? hasError,
    String? errorMessage,
    bool? canPreview,
    bool? canRun,
  }) {
    return EntryModeState(
      entryFile: entryFile ?? this.entryFile,
      options: options ?? this.options,
      previewFiles: previewFiles ?? this.previewFiles,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isRunning: isRunning ?? this.isRunning,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      canPreview: canPreview ?? this.canPreview,
      canRun: canRun ?? this.canRun,
    );
  }

  EntryModeState withEntry(String? file) {
    return copyWith(entryFile: file);
  }

  EntryModeState onPreviewStart() {
    return copyWith(
      isLoadingPreview: true,
      hasError: false,
      errorMessage: null,
    );
  }

  EntryModeState onPreviewSuccess(List<String> files) {
    return copyWith(
      previewFiles: files,
      isLoadingPreview: false,
    );
  }

  EntryModeState onRunStart() {
    return copyWith(
      isRunning: true,
      hasError: false,
      errorMessage: null,
    );
  }

  EntryModeState onRunDone() {
    return copyWith(
      isRunning: false,
      hasError: false,
      errorMessage: null,
    );
  }

  EntryModeState onError(String message) {
    return copyWith(
      hasError: true,
      isLoadingPreview: false,
      isRunning: false,
      errorMessage: message,
    );
  }

  EntryModeState resetKeepOptions() {
    return EntryModeState(
      entryFile: null,
      options: options,
      previewFiles: [],
      isLoadingPreview: false,
      isRunning: false,
      hasError: false,
      errorMessage: null,
      canPreview: false,
      canRun: false,
    );
  }
}
