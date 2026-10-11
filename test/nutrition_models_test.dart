import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/nutrition/data/models/enums_nutrition.dart';
import 'package:coach_app/features/nutrition/data/models/dossier_nutritionnel.dart';
import 'package:coach_app/features/nutrition/data/models/consultation.dart';
import 'package:coach_app/features/nutrition/data/models/programme_nutritionnel.dart';
import 'package:coach_app/features/nutrition/data/models/repas.dart';
import 'package:coach_app/features/nutrition/data/models/aliment_info.dart';

void main() {
  group('Tests des Modèles Nutrition & Suivi', () {
    test('DossierNutritionnel fromMap / toMap et calculs', () {
      final dossier = DossierNutritionnel.fromMap({
        'id': 'dossier-123',
        'id_athlete': 'user-ath-1',
        'objectif': 'PERTE_POIDS',
        'poids_initial': '90.0',
        'poids_actuel': '85.0',
        'poids_cible': '80.0',
        'taille_cm': '180.0',
        'remarques': 'Sans lactose',
      });

      expect(dossier.objectif, ObjectifNutrition.PERTE_POIDS);
      expect(dossier.poidsRestantKg, 5.0);
      expect(dossier.progressionPourcentage, 50.0);
      expect(dossier.imc, closeTo(26.23, 0.05));

      final map = dossier.toMap();
      expect(map['objectif'], 'PERTE_POIDS');
      expect(map['poids_initial'], 90.0);
      expect(map['poids_actuel'], 85.0);
    });

    test('Consultation fromMap / toMap', () {
      final consultation = Consultation.fromMap({
        'id': 'consult-1',
        'id_athlete': 'user-ath-1',
        'id_nutritionniste': 'user-nutri-2',
        'date_consultation': '2026-10-25',
        'heure_consultation': '14:30',
        'motif': 'Bilan initial et plan alimentaire',
        'statut': 'DEMANDEE',
      });

      expect(consultation.statut, StatutConsultation.DEMANDEE);
      expect(consultation.estEnAttente, true);
      expect(consultation.statutTexte, 'Demandée');

      final map = consultation.toMap();
      expect(map['statut'], 'DEMANDEE');
      expect(map['heure_consultation'], '14:30');
    });

    test('ProgrammeNutritionnel fromMap / toMap et calcul macronutriments', () {
      final programme = ProgrammeNutritionnel.fromMap({
        'id': 'prog-1',
        'id_dossier': 'dossier-123',
        'id_nutritionniste': 'user-nutri-2',
        'titre': 'Sèche 8 semaines',
        'description': 'Déficit calorique modéré',
        'objectif': 'PERTE_POIDS',
        'calories_cible': 2000,
        'proteines_cible_g': 150.0,
        'glucides_cible_g': 200.0,
        'lipides_cible_g': 66.6,
        'statut': 'ACTIF',
        'budget_montant': 80.0,
        'budget_devise': 'EUR',
        'date_debut': '2026-10-20',
      });

      expect(programme.objectif, ObjectifNutrition.PERTE_POIDS);
      expect(programme.estActif, true);
      // (150 * 4) + (200 * 4) + (66.6 * 9) = 600 + 800 + 599.4 = 1999.4
      expect(programme.caloriesCalculeesDepuisMacros, closeTo(2000.0, 1.0));
      expect(programme.pourcentageProteines, closeTo(30.0, 0.5));
    });

    test('Repas et AlimentRepas calculs', () {
      final aliment1 = AlimentRepas(
        nom: 'Flocons d avoine',
        calories: 370,
        proteines: 13.0,
        glucides: 68.0,
        lipides: 7.0,
      );

      final aliment2 = AlimentRepas(
        nom: 'Lait demi-écrémé',
        calories: 90,
        proteines: 6.4,
        glucides: 9.6,
        lipides: 3.0,
      );

      final repas = Repas.depuisAliments(
        idRepas: 'repas-1',
        idProgramme: 'prog-1',
        nom: 'Porridge du matin',
        type: TypeRepas.PETIT_DEJEUNER,
        aliments: [aliment1, aliment2],
      );

      expect(repas.type, TypeRepas.PETIT_DEJEUNER);
      expect(repas.calories, 460);
      expect(repas.proteinesG, closeTo(19.4, 0.1));
      expect(repas.aliments.length, 2);
    });

    test('AlimentInfo Open Food Facts conversion', () {
      final info = AlimentInfo.fromOpenFoodFacts({
        'code': '3017620422003',
        'product_name': 'Nutella',
        'brands': 'Ferrero',
        'nutriments': {
          'energy-kcal_100g': 539,
          'proteins_100g': 6.3,
          'carbohydrates_100g': 57.5,
          'fat_100g': 30.9,
        },
        'nutriscore_grade': 'e',
      });

      expect(info.codeBarres, '3017620422003');
      expect(info.nom, 'Nutella');
      expect(info.nutriscore, 'E');

      final portion = info.versAlimentRepas(30.0);
      expect(portion.quantiteGrammes, 30.0);
      expect(portion.calories, (539 * 0.3).round());
      expect(portion.proteines, closeTo(1.9, 0.1));
    });
  });
}
