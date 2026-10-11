import '../data/models/enums_nutrition.dart';

/// Service métier de calculs nutritionnels (Métier 2).
/// Détermine les besoins énergétiques et la répartition optimale des macronutriments.
class NutritionCalculator {
  /// Calcule le Métabolisme de Base (BMR) selon la formule de Mifflin-St Jeor
  static double calculerBmr({
    required double poidsKg,
    required double tailleCm,
    int age = 25,
    bool estHomme = true,
  }) {
    final s = estHomme ? 5.0 : -161.0;
    return (10.0 * poidsKg) + (6.25 * tailleCm) - (5.0 * age) + s;
  }

  /// Calcule les calories cibles recommandées selon le BMR et l'objectif nutritionnel
  static int calculerCaloriesCible({
    required double bmr,
    required ObjectifNutrition objectif,
    double facteurActivite = 1.4, // Modérément actif
  }) {
    final tdee = bmr * facteurActivite;

    switch (objectif) {
      case ObjectifNutrition.PERTE_POIDS:
        return (tdee - 450).round(); // Déficit calorique modéré
      case ObjectifNutrition.PRISE_MASSE:
        return (tdee + 350).round(); // Surplus contrôlé
      case ObjectifNutrition.PERFORMANCE:
        return (tdee + 150).round();
      case ObjectifNutrition.MAINTIEN:
        return tdee.round();
    }
  }

  /// Calcule une proposition de répartition des macronutriments (g) pour un total calorique et un poids donnés
  static Map<String, double> calculerRepartitionMacros({
    required int calories,
    required double poidsKg,
    required ObjectifNutrition objectif,
  }) {
    double ratioProteinesGParKg;
    double ratioLipidesGParKg;

    switch (objectif) {
      case ObjectifNutrition.PERTE_POIDS:
        ratioProteinesGParKg = 2.0; // Protection de la masse musculaire
        ratioLipidesGParKg = 0.8;
        break;
      case ObjectifNutrition.PRISE_MASSE:
        ratioProteinesGParKg = 1.8;
        ratioLipidesGParKg = 1.0;
        break;
      case ObjectifNutrition.PERFORMANCE:
        ratioProteinesGParKg = 1.9;
        ratioLipidesGParKg = 0.9;
        break;
      case ObjectifNutrition.MAINTIEN:
        ratioProteinesGParKg = 1.6;
        ratioLipidesGParKg = 0.9;
        break;
    }

    final proteinesG = (poidsKg * ratioProteinesGParKg);
    final lipidesG = (poidsKg * ratioLipidesGParKg);

    final caloriesProt = proteinesG * 4.0;
    final caloriesLip = lipidesG * 9.0;
    final caloriesRestantesPourGlucides = calories - (caloriesProt + caloriesLip);

    final glucidesG = (caloriesRestantesPourGlucides > 0)
        ? (caloriesRestantesPourGlucides / 4.0)
        : 50.0;

    return {
      'proteines': double.parse(proteinesG.toStringAsFixed(1)),
      'glucides': double.parse(glucidesG.toStringAsFixed(1)),
      'lipides': double.parse(lipidesG.toStringAsFixed(1)),
    };
  }
}
