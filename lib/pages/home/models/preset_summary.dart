class PresetSummary {
  final String id;
  final String name;
  final bool isDefault;
  final bool isFavorite;
  final bool isArchived;
  const PresetSummary({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.isFavorite = false,
    this.isArchived = false,
  });
}