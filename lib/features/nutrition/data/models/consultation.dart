import 'enums_nutrition.dart';

/// Entité 2 : Consultation
/// Relation : Utilisateur (ATHLETE) 1..N - Consultation - N..1 Utilisateur (NUTRITIONNISTE)
/// Gère la prise de rendez-vous, la validation/refus du nutritionniste et les comptes-rendus.
class Consultation {
  final String idConsultation;
  final String idAthlete;
  final String idNutritionniste;
  final DateTime dateConsultation;
  final String heureConsultation;
  final String motif;
  final StatutConsultation statut;
  final String? compteRendu;
  final DateTime? createdAt;

  // Champs d'affichage optionnels (lors de jointures avec les profils utilisateurs)
  final String? nomAthlete;
  final String? nomNutritionniste;

  Consultation({
    required this.idConsultation,
    required this.idAthlete,
    required this.idNutritionniste,
    required this.dateConsultation,
    required this.heureConsultation,
    required this.motif,
    this.statut = StatutConsultation.DEMANDEE,
    this.compteRendu,
    this.createdAt,
    this.nomAthlete,
    this.nomNutritionniste,
  });

  /// Indique si la consultation peut être confirmée ou refusée par le nutritionniste
  bool get estEnAttente => statut == StatutConsultation.DEMANDEE;

  /// Indique si la consultation a été confirmée
  bool get estConfirmee => statut == StatutConsultation.CONFIRMEE;

  /// Indique si la consultation est clôturée
  bool get estTerminee => statut == StatutConsultation.TERMINEE;

  /// Indique si la consultation a été annulée / refusée
  bool get estAnnulee => statut == StatutConsultation.ANNULEE;

  /// Libellé d'affichage en français du statut
  String get statutTexte => formatEnumNutrition(statut);

  /// Conversion vers Map pour Supabase (table "consultation_nutrition")
  Map<String, dynamic> toMap() {
    return {
      'id_athlete': idAthlete,
      'id_nutritionniste': idNutritionniste,
      'date_consultation': dateConsultation.toIso8601String().split('T').first,
      'heure_consultation': heureConsultation,
      'motif': motif,
      'compte_rendu': compteRendu,
      'statut': statut.name,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Création depuis les données Supabase
  factory Consultation.fromMap(Map<String, dynamic> data) {
    return Consultation(
      idConsultation: data['id']?.toString() ?? '',
      idAthlete: data['id_athlete']?.toString() ?? '',
      idNutritionniste: data['id_nutritionniste']?.toString() ?? '',
      dateConsultation: data['date_consultation'] != null
          ? DateTime.parse(data['date_consultation'].toString())
          : DateTime.now(),
      heureConsultation: data['heure_consultation']?.toString() ?? '',
      motif: data['motif']?.toString() ?? '',
      compteRendu: data['compte_rendu']?.toString(),
      statut: StatutConsultation.values.firstWhere(
        (st) => st.name.toUpperCase() == (data['statut'] ?? '').toString().toUpperCase(),
        orElse: () => StatutConsultation.DEMANDEE,
      ),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      nomAthlete: data['nom_athlete']?.toString(),
      nomNutritionniste: data['nom_nutritionniste']?.toString(),
    );
  }

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation.fromMap(json);

  Consultation copyWith({
    String? idConsultation,
    String? idAthlete,
    String? idNutritionniste,
    DateTime? dateConsultation,
    String? heureConsultation,
    String? motif,
    StatutConsultation? statut,
    String? compteRendu,
    DateTime? createdAt,
    String? nomAthlete,
    String? nomNutritionniste,
  }) {
    return Consultation(
      idConsultation: idConsultation ?? this.idConsultation,
      idAthlete: idAthlete ?? this.idAthlete,
      idNutritionniste: idNutritionniste ?? this.idNutritionniste,
      dateConsultation: dateConsultation ?? this.dateConsultation,
      heureConsultation: heureConsultation ?? this.heureConsultation,
      motif: motif ?? this.motif,
      statut: statut ?? this.statut,
      compteRendu: compteRendu ?? this.compteRendu,
      createdAt: createdAt ?? this.createdAt,
      nomAthlete: nomAthlete ?? this.nomAthlete,
      nomNutritionniste: nomNutritionniste ?? this.nomNutritionniste,
    );
  }
}
