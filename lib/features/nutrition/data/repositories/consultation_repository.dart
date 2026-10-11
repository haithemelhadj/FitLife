import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consultation.dart';
import '../models/enums_nutrition.dart';

/// Structure simple pour représenter un praticien nutritionniste sélectionnable
class NutritionnisteItem {
  final String id;
  final String nom;
  final String specialite;

  const NutritionnisteItem({
    required this.id,
    required this.nom,
    this.specialite = 'Nutrition du Sportif',
  });
}

/// Repository pour la gestion des consultations (Entité 2 et Métier 1).
/// Gère les demandes de consultation par l'athlète et les validations/refus du praticien.
class ConsultationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Données de secours en mémoire
  static final List<Consultation> _consultationsLocales = [
    Consultation(
      idConsultation: 'consult-demo-1',
      idAthlete: 'demo-athlete-id',
      idNutritionniste: 'nutri-1',
      dateConsultation: DateTime.now().add(const Duration(days: 3)),
      heureConsultation: '14:30',
      motif: 'Mise en place du plan alimentaire pour perte de poids',
      statut: StatutConsultation.CONFIRMEE,
      nomNutritionniste: 'Dr. Sarah Ben Salem',
    ),
    Consultation(
      idConsultation: 'consult-demo-2',
      idAthlete: 'demo-athlete-id',
      idNutritionniste: 'nutri-2',
      dateConsultation: DateTime.now().add(const Duration(days: 10)),
      heureConsultation: '10:00',
      motif: 'Bilan d\'étape et ajustement des macros',
      statut: StatutConsultation.DEMANDEE,
      nomNutritionniste: 'Dr. Karim Mansour',
    ),
  ];

  /// Liste des nutritionnistes disponibles pour la prise de rendez-vous
  Future<List<NutritionnisteItem>> getNutritionnistes() async {
    try {
      final response = await _client
          .from('utilisateurs')
          .select('id, nom, prenom')
          .eq('role', 'NUTRITIONNISTE');

      if (response.isNotEmpty) {
        return (response as List).map((row) {
          final nomComplet = '${row['prenom'] ?? ''} ${row['nom'] ?? ''}'.trim();
          return NutritionnisteItem(
            id: row['id'].toString(),
            nom: nomComplet.isEmpty ? 'Nutritionniste' : nomComplet,
          );
        }).toList();
      }
    } catch (_) {
      // Supabase non accessible ou table différente
    }

    // Liste par défaut pour démonstration
    return const [
      NutritionnisteItem(id: 'nutri-1', nom: 'Dr. Sarah Ben Salem', specialite: 'Perte de poids & Endurance'),
      NutritionnisteItem(id: 'nutri-2', nom: 'Dr. Karim Mansour', specialite: 'Prise de masse & Force'),
      NutritionnisteItem(id: 'nutri-3', nom: 'Dr. Myriam Trabelsi', specialite: 'Nutrition générale & Santé'),
    ];
  }

  /// Récupère toutes les consultations d'un athlète
  Future<List<Consultation>> getConsultationsAthlete(String idAthlete) async {
    try {
      final response = await _client
          .from('consultation_nutrition')
          .select()
          .eq('id_athlete', idAthlete)
          .order('date_consultation', ascending: true);

      if (response.isNotEmpty) {
        return (response as List).map((r) => Consultation.fromMap(r)).toList();
      }
    } catch (_) {
      // Mode de secours
    }

    return _consultationsLocales.where((c) => c.idAthlete == idAthlete).toList();
  }

  /// Récupère toutes les consultations reçues par un nutritionniste
  Future<List<Consultation>> getConsultationsNutritionniste(String idNutritionniste) async {
    try {
      final response = await _client
          .from('consultation_nutrition')
          .select()
          .eq('id_nutritionniste', idNutritionniste)
          .order('date_consultation', ascending: true);

      if (response.isNotEmpty) {
        return (response as List).map((r) => Consultation.fromMap(r)).toList();
      }
    } catch (_) {
      // Mode de secours
    }

    return _consultationsLocales.where((c) => c.idNutritionniste == idNutritionniste).toList();
  }

  /// Métier 1 : Demande de consultation par l'athlète
  Future<Consultation> demanderConsultation(Consultation consultation) async {
    final nouvelle = consultation.copyWith(
      idConsultation: consultation.idConsultation.isEmpty
          ? 'consult-${DateTime.now().millisecondsSinceEpoch}'
          : consultation.idConsultation,
      statut: StatutConsultation.DEMANDEE,
    );

    _consultationsLocales.add(nouvelle);

    try {
      await _client.from('consultation_nutrition').insert(nouvelle.toMap());
    } catch (_) {
      // Ignoré en mode offline/développement
    }

    return nouvelle;
  }

  /// Métier 1 : Changement de statut (Confirmer, Refuser/Annuler, Clôturer avec compte-rendu)
  Future<void> changerStatut(
    String idConsultation,
    StatutConsultation nouveauStatut, {
    String? compteRendu,
  }) async {
    final index = _consultationsLocales.indexWhere((c) => c.idConsultation == idConsultation);
    if (index != -1) {
      _consultationsLocales[index] = _consultationsLocales[index].copyWith(
        statut: nouveauStatut,
        compteRendu: compteRendu ?? _consultationsLocales[index].compteRendu,
      );
    }

    try {
      final updateData = <String, dynamic>{'statut': nouveauStatut.name};
      if (compteRendu != null) {
        updateData['compte_rendu'] = compteRendu;
      }
      await _client
          .from('consultation_nutrition')
          .update(updateData)
          .eq('id', idConsultation);
    } catch (_) {
      // Ignoré
    }
  }

  /// Supprimer une consultation
  Future<void> supprimer(String idConsultation) async {
    _consultationsLocales.removeWhere((c) => c.idConsultation == idConsultation);
    try {
      await _client.from('consultation_nutrition').delete().eq('id', idConsultation);
    } catch (_) {
      // Ignoré
    }
  }
}
