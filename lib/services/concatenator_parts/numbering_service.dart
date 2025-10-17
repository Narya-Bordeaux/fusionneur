// Service de numérotation (1..N) pour une liste de fichiers ordonnés.

class NumberingService {
  const NumberingService();

  /// Construit une map "filePath -> number" (1..N) à partir de [ordered].
  /// - [ordered] : liste de chemins déjà triés/ordonnés.
  /// - Retour : map immuable (unmodifiable) des numéros.
  Map<String, int> build(List<String> ordered) {
    final map = <String, int>{};
    for (var i = 0; i < ordered.length; i++) {
      // Numérotation 1-based pour correspondre aux bannières et au JSON index.
      map[ordered[i]] = i + 1;
    }
    return Map.unmodifiable(map);
  }
}
