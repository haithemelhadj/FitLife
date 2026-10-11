import 'dart:convert';
import 'dart:io';

/// Service d'interfaçage avec l'API Frankfurter (API 2).
/// API open-source sans clé permettant de récupérer des taux de change
/// et de convertir le budget alimentaire dans différentes devises (ex: EUR vers TND).
class FrankfurterService {
  static const String _host = 'api.frankfurter.dev';
  static const String _fallbackHost = 'api.frankfurter.app';

  // Taux de secours réaliste par défaut si le réseau est inaccessible
  static const double _tauxSecoursEurVersTnd = 3.38;

  /// Récupère le taux de change entre deux devises (ex: 'EUR' vers 'TND')
  Future<double> getTauxChange({String de = 'EUR', String vers = 'TND'}) async {
    if (de.toUpperCase() == vers.toUpperCase()) return 1.0;

    try {
      final taux = await _interrogerApi(_host, de, vers);
      if (taux != null) return taux;
    } catch (_) {
      try {
        final taux = await _interrogerApi(_fallbackHost, de, vers);
        if (taux != null) return taux;
      } catch (_) {
        // En cas d'échec total du réseau, on utilise le taux de secours
      }
    }

    if (de.toUpperCase() == 'EUR' && vers.toUpperCase() == 'TND') {
      return _tauxSecoursEurVersTnd;
    } else if (de.toUpperCase() == 'TND' && vers.toUpperCase() == 'EUR') {
      return 1.0 / _tauxSecoursEurVersTnd;
    }

    return 1.0;
  }

  /// Convertit un montant d'une devise source vers une devise cible.
  /// Exemple : 50 EUR -> 169.00 TND
  Future<double> convertir(
    double montant, {
    String de = 'EUR',
    String vers = 'TND',
  }) async {
    final taux = await getTauxChange(de: de, vers: vers);
    return double.parse((montant * taux).toStringAsFixed(2));
  }

  Future<double?> _interrogerApi(String host, String de, String vers) async {
    final uri = Uri.https(host, '/v1/latest', {
      'base': de.toUpperCase(),
      'symbols': vers.toUpperCase(),
    });

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);

    final request = await client.getUrl(uri);
    request.headers.set('Accept', 'application/json');

    final response = await request.close();

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;

      if (rates != null && rates.containsKey(vers.toUpperCase())) {
        return double.tryParse(rates[vers.toUpperCase()].toString());
      }
    }
    return null;
  }
}
