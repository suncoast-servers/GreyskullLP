class FoodSearchResult {
  FoodSearchResult({
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.source,
    required this.servingDescription,
  });

  final String name;
  final int calories;
  final int proteinGrams;
  final String source;
  final String servingDescription;
}
