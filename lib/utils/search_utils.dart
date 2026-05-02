/// Search utilities for filtering and suggesting results like YouTube
class SearchUtils {
  /// Calculate similarity score between two strings (0-1)
  /// Returns 1.0 for exact matches, lower values for partial matches
  static double calculateSimilarity(String query, String target) {
    query = query.toLowerCase();
    target = target.toLowerCase();

    if (query.isEmpty || target.isEmpty) {
      return 0.0;
    }

    if (query == target) {
      return 1.0; // Exact match
    }

    if (target.contains(query)) {
      return 0.9; // Substring match
    }

    // Check if query starts with target or vice versa
    if (target.startsWith(query)) {
      return 0.85;
    }

    if (query.startsWith(target)) {
      return 0.8;
    }

    // Levenshtein distance for fuzzy matching
    final distance = _levenshteinDistance(query, target);
    final maxLength = query.length > target.length ? query.length : target.length;
    final similarity = 1.0 - (distance / maxLength);

    return similarity > 0 ? similarity : 0;
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String a, String b) {
    final aLen = a.length;
    final bLen = b.length;

    if (aLen == 0) return bLen;
    if (bLen == 0) return aLen;

    final result = List<List<int>>.generate(
      aLen + 1,
      (i) => List<int>.filled(bLen + 1, 0),
    );

    for (int i = 0; i <= aLen; i++) {
      result[i][0] = i;
    }

    for (int j = 0; j <= bLen; j++) {
      result[0][j] = j;
    }

    for (int i = 1; i <= aLen; i++) {
      for (int j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        result[i][j] = [
          result[i - 1][j] + 1,
          result[i][j - 1] + 1,
          result[i - 1][j - 1] + cost,
        ].reduce((min, val) => val < min ? val : min);
      }
    }

    return result[aLen][bLen];
  }

  /// Filter and sort items by similarity to query
  /// Returns items sorted by relevance (highest similarity first)
  static List<T> searchAndSort<T>(
    String query,
    List<T> items,
    String Function(T) getText,
  ) {
    if (query.isEmpty) {
      return items;
    }

    final scored = items.map((item) {
      final score = calculateSimilarity(query, getText(item));
      return MapEntry(item, score);
    }).toList();

    // Filter items with low similarity (below 0.3 threshold)
    scored.removeWhere((entry) => entry.value < 0.3);

    // Sort by score in descending order
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).toList();
  }

  /// Get suggestions for incomplete query
  static List<String> getSuggestions(
    String query,
    List<String> items,
  ) {
    if (query.isEmpty) {
      return items.take(5).toList(); // Return first 5 items as suggestions
    }

    return searchAndSort(query, items, (item) => item).take(5).toList();
  }
}
