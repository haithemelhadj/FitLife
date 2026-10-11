import 'repas.dart';

/// Modèle DTO pour les informations nutritionnelles issues de l'API Open Food Facts (API 1).
class AlimentInfo {
  final String codeBarres;
  final String nom;
  final String? marque;
  final String? imageUrl;
  final String? nutriscore;
  final double calories100g;
  final double proteines100g;
  final double glucides100g;
  final double lipides100g;

  AlimentInfo({
    required this.codeBarres,
    required this.nom,
    this.marque,
    this.imageUrl,
    this.nutriscore,
    required this.calories100g,
    required this.proteines100g,
    required this.glucides100g,
    required this.lipides100g,
  });

  /// Convertit cet aliment en composant de repas pour une quantité donnée en grammes
  AlimentRepas versAlimentRepas(double quantiteGrammes) {
    final ratio = quantiteGrammes / 100.0;
    return AlimentRepas(
      codeBarres: codeBarres,
      nom: nom,
      marque: marque,
      quantiteGrammes: quantiteGrammes,
      calories: (calories100g * ratio).round(),
      proteines: double.parse((proteines100g * ratio).toStringAsFixed(1)),
      glucides: double.parse((glucides100g * ratio).toStringAsFixed(1)),
      lipides: double.parse((lipides100g * ratio).toStringAsFixed(1)),
    );
  }

  /// Parse le JSON retourné par l'API Open Food Facts (v0 ou v2)
  factory AlimentInfo.fromOpenFoodFacts(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    // Open Food Facts fournit les calories soit dans 'energy-kcal_100g', soit 'energy-kcal'
    final cal = nutriments['energy-kcal_100g'] ??
        nutriments['energy-kcal'] ??
        (nutriments['energy_100g'] != null ? (nutriments['energy_100g'] / 4.184) : 0);

    final prot = nutriments['proteins_100g'] ?? nutriments['proteins'] ?? 0;
    final gluc = nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates'] ?? 0;
    final lip = nutriments['fat_100g'] ?? nutriments['fat'] ?? 0;

    return AlimentInfo(
      codeBarres: json['code']?.toString() ?? json['_id']?.toString() ?? '',
      nom: json['product_name']?.toString() ??
          json['product_name_fr']?.toString() ??
          'Produit sans nom',
      marque: json['brands']?.toString(),
      imageUrl: json['image_front_url']?.toString() ?? json['image_url']?.toString(),
      nutriscore: json['nutriscore_grade']?.toString().toUpperCase(),
      calories100g: double.tryParse(cal.toString()) ?? 0.0,
      proteines100g: double.tryParse(prot.toString()) ?? 0.0,
      glucides100g: double.tryParse(gluc.toString()) ?? 0.0,
      lipides100g: double.tryParse(lip.toString()) ?? 0.0,
    );
  }
}
