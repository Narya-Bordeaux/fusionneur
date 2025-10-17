class FusionRecord {
  final String id;
  final DateTime dateTime;
  final String presetId;
  final String presetName;
  final String filePath;   // chemin du .txt/.md
  final int? sizeBytes;    // optionnel
  final int? lineCount;    // optionnel
  const FusionRecord({
    required this.id,
    required this.dateTime,
    required this.presetId,
    required this.presetName,
    required this.filePath,
    this.sizeBytes,
    this.lineCount,
  });
}
