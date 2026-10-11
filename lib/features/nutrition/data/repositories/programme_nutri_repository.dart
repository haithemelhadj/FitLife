import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums_nutrition.dart';
import '../models/programme_nutritionnel.dart';
import '../models/repas.dart';

/// Repository pour la gestion des Programmes Nutritionnels et des Repas (Entités 3 & 4, Métier 2).
class ProgrammeNutriRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Données de démonstration locales
  static final List<ProgrammeNutritionnel> _programmesLocaux = [
    ProgrammeNutritionnel(
      idProgramme: 'demo-prog-001',
      idDossier: 'demo-dossier-001',
      idNutritionniste: 'nutri-1',
      titre: 'Programme Sèche & Définition',
      description: 'Léger déficit calorique, apport élevé en protéines et synchronisation avec les séances cardio.',
      objectif: ObjectifNutrition.PERTE_POIDS,
      caloriesCible: 2100,
      proteinesCibleG: 160.0,
      glucidesCibleG: 210.0,
      lipidesCibleG: 68.0,
      statut: StatutProgramme.ACTIF,
      budgetMontant: 65.0,
      budgetDevise: 'EUR',
      dateDebut: DateTime.now().subtract(const Duration(days: 14)),
      dateFin: DateTime.now().add(const Duration(days: 42)),
    ),
  ];

  static final List<Repas> _repasLocaux = [
    Repas(
      idRepas: 'repas-demo-1',
      idProgramme: 'demo-prog-001',
      nom: 'Bol Énergie Matinal',
      type: TypeRepas.PETIT_DEJEUNER,
      heureRecommandee: '07:30',
      calories: 520,
      proteinesG: 32.0,
      glucidesG: 65.0,
      lipidesG: 14.0,
      aliments: [
        AlimentRepas(
          codeBarres: '3033490004523',
          nom: 'Flocons d\'avoine complets',
          marque: 'Quaker',
          quantiteGrammes: 70,
          calories: 262,
          proteines: 7.7,
          glucides: 42.0,
          lipides: 5.6,
        ),
        AlimentRepas(
          codeBarres: '3250390004040',
          nom: 'Fromage blanc 0%',
          marque: 'Calin',
          quantiteGrammes: 200,
          calories: 96,
          proteines: 16.0,
          glucides: 8.0,
          lipides: 0.4,
        ),
        AlimentRepas(
          codeBarres: '3250390005050',
          nom: 'Banane',
          marque: 'Bio',
          quantiteGrammes: 120,
          calories: 107,
          proteines: 1.3,
          glucides: 27.0,
          lipides: 0.4,
        ),
      ],
      ordre: 1,
    ),
    Repas(
      idRepas: 'repas-demo-2',
      idProgramme: 'demo-prog-001',
      nom: 'Assiette Athlète Poulet & Riz',
      type: TypeRepas.DEJEUNER,
      heureRecommandee: '12:30',
      calories: 680,
      proteinesG: 55.0,
      glucidesG: 82.0,
      lipidesG: 15.0,
      aliments: [
        AlimentRepas(
          codeBarres: '3250390001010',
          nom: 'Blanc de poulet rôti',
          marque: 'Fleury Michon',
          quantiteGrammes: 180,
          calories: 189,
          proteines: 39.6,
          glucides: 1.8,
          lipides: 2.7,
        ),
        AlimentRepas(
          codeBarres: '3250390002020',
          nom: 'Riz Basmati complet',
          marque: 'Taureau Ailé',
          quantiteGrammes: 100,
          calories: 350,
          proteines: 8.5,
          glucides: 74.0,
          lipides: 1.5,
        ),
      ],
      ordre: 2,
    ),
    Repas(
      idRepas: 'repas-demo-3',
      idProgramme: 'demo-prog-001',
      nom: 'Shake & Amandes Post-Training',
      type: TypeRepas.COLLATION,
      heureRecommandee: '16:30',
      calories: 320,
      proteinesG: 28.0,
      glucidesG: 15.0,
      lipidesG: 16.0,
      ordre: 3,
    ),
    Repas(
      idRepas: 'repas-demo-4',
      idProgramme: 'demo-prog-001',
      nom: 'Dîner Saumon & Légumes Verts',
      type: TypeRepas.DINER,
      heureRecommandee: '20:00',
      calories: 580,
      proteinesG: 45.0,
      glucidesG: 48.0,
      lipidesG: 23.0,
      aliments: [
        AlimentRepas(
          codeBarres: '3250390003030',
          nom: 'Pavé de Saumon frais',
          marque: 'Pêche Océan',
          quantiteGrammes: 160,
          calories: 332,
          proteines: 32.0,
          glucides: 0.0,
          lipides: 20.8,
        ),
      ],
      ordre: 4,
    ),
  ];

  /// Récupère tous les programmes d'un dossier
  Future<List<ProgrammeNutritionnel>> getProgrammesDuDossier(String idDossier) async {
    try {
      final response = await _client
          .from('programme_nutritionnel')
          .select()
          .eq('id_dossier', idDossier)
          .order('date_debut', ascending: false);

      if (response.isNotEmpty) {
        return (response as List).map((p) => ProgrammeNutritionnel.fromMap(p)).toList();
      }
    } catch (_) {
      // Fallback
    }

    return _programmesLocaux.where((p) => p.idDossier == idDossier).toList();
  }

  /// Récupère les repas d'un programme
  Future<List<Repas>> getRepasDuProgramme(String idProgramme) async {
    try {
      final response = await _client
          .from('repas')
          .select()
          .eq('id_programme', idProgramme)
          .order('ordre', ascending: true);

      if (response.isNotEmpty) {
        return (response as List).map((r) => Repas.fromMap(r)).toList();
      }
    } catch (_) {
      // Fallback
    }

    return _repasLocaux.where((r) => r.idProgramme == idProgramme).toList();
  }

  /// Métier 2 : Création d'un programme nutritionnel et de ses repas
  Future<ProgrammeNutritionnel> creerProgramme(
    ProgrammeNutritionnel programme, {
    List<Repas> repas = const [],
  }) async {
    final nouveauProg = programme.copyWith(
      idProgramme: programme.idProgramme.isEmpty
          ? 'prog-${DateTime.now().millisecondsSinceEpoch}'
          : programme.idProgramme,
    );

    _programmesLocaux.insert(0, nouveauProg);

    try {
      await _client.from('programme_nutritionnel').insert(nouveauProg.toMap());
    } catch (_) {
      // Ignoré si Supabase pas encore prêt
    }

    for (final r in repas) {
      final repasLie = r.copyWith(
        idRepas: r.idRepas.isEmpty ? 'repas-${DateTime.now().millisecondsSinceEpoch}' : r.idRepas,
        idProgramme: nouveauProg.idProgramme,
      );
      _repasLocaux.add(repasLie);
      try {
        await _client.from('repas').insert(repasLie.toMap());
      } catch (_) {}
    }

    return nouveauProg;
  }

  /// Met à jour un programme
  Future<void> modifierProgramme(ProgrammeNutritionnel programme) async {
    final index = _programmesLocaux.indexWhere((p) => p.idProgramme == programme.idProgramme);
    if (index != -1) {
      _programmesLocaux[index] = programme;
    }

    try {
      await _client
          .from('programme_nutritionnel')
          .update(programme.toMap())
          .eq('id', programme.idProgramme);
    } catch (_) {}
  }

  /// Changer le statut d'un programme (ACTIF, TERMINE, SUSPENDU, ANNULE)
  Future<void> changerStatut(String idProgramme, StatutProgramme statut) async {
    final index = _programmesLocaux.indexWhere((p) => p.idProgramme == idProgramme);
    if (index != -1) {
      _programmesLocaux[index] = _programmesLocaux[index].copyWith(statut: statut);
    }

    try {
      await _client
          .from('programme_nutritionnel')
          .update({'statut': statut.name})
          .eq('id', idProgramme);
    } catch (_) {}
  }

  /// Ajout d'un repas à un programme
  Future<Repas> ajouterRepas(Repas repas) async {
    final nouveau = repas.copyWith(
      idRepas: repas.idRepas.isEmpty ? 'repas-${DateTime.now().millisecondsSinceEpoch}' : repas.idRepas,
    );
    _repasLocaux.add(nouveau);

    try {
      await _client.from('repas').insert(nouveau.toMap());
    } catch (_) {}

    return nouveau;
  }

  /// Suppression d'un repas
  Future<void> supprimerRepas(String idRepas) async {
    _repasLocaux.removeWhere((r) => r.idRepas == idRepas);
    try {
      await _client.from('repas').delete().eq('id', idRepas);
    } catch (_) {}
  }

  /// Suppression d'un programme
  Future<void> supprimerProgramme(String idProgramme) async {
    _programmesLocaux.removeWhere((p) => p.idProgramme == idProgramme);
    _repasLocaux.removeWhere((r) => r.idProgramme == idProgramme);

    try {
      await _client.from('programme_nutritionnel').delete().eq('id', idProgramme);
    } catch (_) {}
  }
}
