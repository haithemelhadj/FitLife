import 'dart:convert';
import 'dart:io';
import '../models/aliment_info.dart';

/// Service d'interfaçage avec l'API Open Food Facts (API 1).
/// Permet la recherche d'aliments et la consultation nutritionnelle par code-barres.
class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const String _userAgent = 'FitLifeApp-Nutrition/1.0 (contact@fitlife.app)';

  /// Recherche des aliments par mots-clés (ex: "flocons d'avoine", "poulet", "pomme").
  Future<List<AlimentInfo>> rechercherAliments(String motCle) async {
    if (motCle.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(motCle)}&search_simple=1&action=process&json=1&page_size=25',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', _userAgent);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();

      if (response.statusCode == 200) {
        final bodyString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(bodyString) as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>? ?? [];

        final resultats = <AlimentInfo>[];
        for (final item in products) {
          if (item is Map<String, dynamic>) {
            // Filtrer les produits sans nom
            final nom = item['product_name'] ?? item['product_name_fr'];
            if (nom != null && nom.toString().trim().isNotEmpty) {
              resultats.add(AlimentInfo.fromOpenFoodFacts(item));
            }
          }
        }
        if (resultats.isNotEmpty) {
          return resultats;
        }
      }
    } catch (_) {
      // En cas de problème réseau ou timeout, on bascule sur la recherche locale de secours
    }

    return _rechercherEnSecours(motCle);
  }

  /// Recherche un aliment spécifique par son code-barres (scan de produit).
  Future<AlimentInfo?> getAlimentParCodeBarres(String codeBarres) async {
    if (codeBarres.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/api/v2/product/${codeBarres.trim()}.json');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', _userAgent);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();

      if (response.statusCode == 200) {
        final bodyString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(bodyString) as Map<String, dynamic>;

        if (data['status'] == 1 && data['product'] != null) {
          return AlimentInfo.fromOpenFoodFacts(data['product'] as Map<String, dynamic>);
        }
      }
    } catch (_) {
      // Fallback
    }

    // Recherche dans la base de démonstration si non trouvé ou hors-ligne
    for (final a in _alimentsSecours) {
      if (a.codeBarres == codeBarres.trim()) {
        return a;
      }
    }
    return null;
  }

  /// Données de démonstration et de secours (mode hors-ligne ou tests sans réseau).
  List<AlimentInfo> _rechercherEnSecours(String motCle) {
    final query = motCle.toLowerCase();
    return _alimentsSecours
        .where((a) => a.nom.toLowerCase().contains(query) || (a.marque?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  static final List<AlimentInfo> _alimentsSecours = [
    AlimentInfo(
      codeBarres: '3017620422003',
      nom: 'Nutella Pâte à tartiner',
      marque: 'Ferrero',
      nutriscore: 'E',
      calories100g: 539,
      proteines100g: 6.3,
      glucides100g: 57.5,
      lipides100g: 30.9,
    ),
    AlimentInfo(
      codeBarres: '3033490004523',
      nom: 'Flocons d\'avoine complets',
      marque: 'Quaker',
      nutriscore: 'A',
      calories100g: 375,
      proteines100g: 11.0,
      glucides100g: 60.0,
      lipides100g: 8.0,
    ),
    AlimentInfo(
      codeBarres: '3250390001010',
      nom: 'Blanc de poulet rôti',
      marque: 'Fleury Michon',
      nutriscore: 'A',
      calories100g: 105,
      proteines100g: 22.0,
      glucides100g: 1.0,
      lipides100g: 1.5,
    ),
    AlimentInfo(
      codeBarres: '3250390002020',
      nom: 'Riz Basmati complet',
      marque: 'Taureau Ailé',
      nutriscore: 'A',
      calories100g: 350,
      proteines100g: 8.5,
      glucides100g: 74.0,
      lipides100g: 1.5,
    ),
    AlimentInfo(
      codeBarres: '3250390003030',
      nom: 'Pavé de Saumon frais',
      marque: 'Pêche Océan',
      nutriscore: 'A',
      calories100g: 208,
      proteines100g: 20.0,
      glucides100g: 0.0,
      lipides100g: 13.0,
    ),
    AlimentInfo(
      codeBarres: '3250390004040',
      nom: 'Fromage blanc 0%',
      marque: 'Calin',
      nutriscore: 'A',
      calories100g: 48,
      proteines100g: 8.0,
      glucides100g: 4.0,
      lipides100g: 0.2,
    ),
    AlimentInfo(
      codeBarres: '3250390005050',
      nom: 'Banane Cavendish',
      marque: 'Bio',
      nutriscore: 'A',
      calories100g: 89,
      proteines100g: 1.1,
      glucides100g: 22.8,
      lipides100g: 0.3,
    ),
  ];
}
