import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dossier_nutritionnel.dart';
import '../models/enums_nutrition.dart';

/// Repository pour la gestion du Dossier Nutritionnel de l'athlète (Entité 1).
/// Gère la persistance Supabase (table "dossier_nutritionnel") avec un mode de secours local
/// si Supabase n'est pas encore configuré ou inaccessible.
class DossierRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Données de secours en mémoire (permet de tester l'application avant la création des tables Supabase)
  static final Map<String, DossierNutritionnel> _dossiersLocaux = {
    'demo-athlete-id': DossierNutritionnel(
      idDossier: 'demo-dossier-001',
      idAthlete: 'demo-athlete-id',
      objectif: ObjectifNutrition.PERTE_POIDS,
      poidsInitial: 86.0,
      poidsActuel: 81.5,
      poidsCible: 78.0,
      tailleCm: 178.0,
      remarques: 'Objectif : perte de 8 kg coordonnée avec entraînement cardio/musculation.',
      dateCreation: DateTime.now().subtract(const Duration(days: 30)),
      dateMiseAJour: DateTime.now(),
    ),
  };

  /// Récupère ou initialise le dossier nutritionnel pour un athlète donné
  Future<DossierNutritionnel> getDossier(String idAthlete) async {
    try {
      final response = await _client
          .from('dossier_nutritionnel')
          .select()
          .eq('id_athlete', idAthlete)
          .maybeSingle();

      if (response != null) {
        return DossierNutritionnel.fromMap(response);
      }
    } catch (_) {
      // Supabase non configuré ou table non encore créée
    }

    // Retour du dossier en mémoire ou création d'un dossier par défaut
    if (_dossiersLocaux.containsKey(idAthlete)) {
      return _dossiersLocaux[idAthlete]!;
    }

    final nouveauDossier = DossierNutritionnel(
      idDossier: 'local-${DateTime.now().millisecondsSinceEpoch}',
      idAthlete: idAthlete,
      objectif: ObjectifNutrition.PERTE_POIDS,
      poidsInitial: 80.0,
      poidsActuel: 80.0,
      poidsCible: 75.0,
      tailleCm: 175.0,
      remarques: 'Nouveau dossier créé',
      dateCreation: DateTime.now(),
      dateMiseAJour: DateTime.now(),
    );
    _dossiersLocaux[idAthlete] = nouveauDossier;
    return nouveauDossier;
  }

  /// Enregistre ou met à jour le dossier nutritionnel
  Future<void> enregistrerDossier(DossierNutritionnel dossier) async {
    _dossiersLocaux[dossier.idAthlete] = dossier;

    try {
      await _client.from('dossier_nutritionnel').upsert(
        dossier.toMap()..['id_athlete'] = dossier.idAthlete,
        onConflict: 'id_athlete',
      );
    } catch (_) {
      // Ignoré si Supabase n'est pas encore prêt
    }
  }

  /// Met à jour rapidement le poids actuel de l'athlète (Métier 3 : Suivi)
  Future<DossierNutritionnel> enregistrerPesee(String idAthlete, double nouveauPoids) async {
    final existant = await getDossier(idAthlete);
    final maj = existant.copyWith(
      poidsActuel: nouveauPoids,
      dateMiseAJour: DateTime.now(),
    );

    await enregistrerDossier(maj);
    return maj;
  }
}
