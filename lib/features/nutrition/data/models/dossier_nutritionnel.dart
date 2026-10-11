import 'enums_nutrition.dart';

/// Entité 1 : DossierNutritionnel
/// Lié à l'athlète (relation 1-1). Contient l'objectif, les métriques corporelles et le suivi d'évolution.
class DossierNutritionnel {
  final String idDossier;
  final String idAthlete;
  final ObjectifNutrition objectif;
  final double poidsInitial;
  final double poidsActuel;
  final double poidsCible;
  final double? tailleCm;
  final String? remarques;
  final DateTime? dateCreation;
  final DateTime? dateMiseAJour;

  DossierNutritionnel({
    required this.idDossier,
    required this.idAthlete,
    required this.objectif,
    required this.poidsInitial,
    required this.poidsActuel,
    required this.poidsCible,
    this.tailleCm,
    this.remarques,
    this.dateCreation,
    this.dateMiseAJour,
  });

  /// Indice de Masse Corporelle (IMC)
  double? get imc {
    if (tailleCm == null || tailleCm! <= 0) return null;
    final tailleM = tailleCm! / 100.0;
    return poidsActuel / (tailleM * tailleM);
  }

  /// Écart restant jusqu'à l'objectif (en kg)
  double get poidsRestantKg {
    return (poidsActuel - poidsCible).abs();
  }

  /// Pourcentage d'accomplissement de l'objectif (Métier 3)
  double get progressionPourcentage {
    final ecartTotal = (poidsInitial - poidsCible).abs();
    if (ecartTotal == 0) return 100.0;

    final ecartRealise = (poidsInitial - poidsActuel).abs();
    final pourcentage = (ecartRealise / ecartTotal) * 100.0;
    return pourcentage.clamp(0.0, 100.0);
  }

  /// Conversion vers Map pour insertion/mise à jour dans Supabase (table "dossier_nutritionnel")
  Map<String, dynamic> toMap() {
    return {
      'id_athlete': idAthlete,
      'objectif': objectif.name,
      'poids_initial': poidsInitial,
      'poids_actuel': poidsActuel,
      'poids_cible': poidsCible,
      'taille_cm': tailleCm,
      'remarques': remarques,
      'date_mise_a_jour': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Création d'une instance depuis une ligne retournée par Supabase
  factory DossierNutritionnel.fromMap(Map<String, dynamic> data) {
    return DossierNutritionnel(
      idDossier: data['id']?.toString() ?? '',
      idAthlete: data['id_athlete']?.toString() ?? '',
      objectif: ObjectifNutrition.values.firstWhere(
        (obj) => obj.name.toUpperCase() == (data['objectif'] ?? '').toString().toUpperCase(),
        orElse: () => ObjectifNutrition.MAINTIEN,
      ),
      poidsInitial: double.tryParse(data['poids_initial']?.toString() ?? '0') ?? 0.0,
      poidsActuel: double.tryParse(data['poids_actuel']?.toString() ?? '0') ?? 0.0,
      poidsCible: double.tryParse(data['poids_cible']?.toString() ?? '0') ?? 0.0,
      tailleCm: data['taille_cm'] != null ? double.tryParse(data['taille_cm'].toString()) : null,
      remarques: data['remarques']?.toString(),
      dateCreation: data['date_creation'] != null ? DateTime.tryParse(data['date_creation'].toString()) : null,
      dateMiseAJour: data['date_mise_a_jour'] != null ? DateTime.tryParse(data['date_mise_a_jour'].toString()) : null,
    );
  }

  factory DossierNutritionnel.fromJson(Map<String, dynamic> json) => DossierNutritionnel.fromMap(json);

  /// Crée une copie modifiée de l'instance
  DossierNutritionnel copyWith({
    String? idDossier,
    String? idAthlete,
    ObjectifNutrition? objectif,
    double? poidsInitial,
    double? poidsActuel,
    double? poidsCible,
    double? tailleCm,
    String? remarques,
    DateTime? dateCreation,
    DateTime? dateMiseAJour,
  }) {
    return DossierNutritionnel(
      idDossier: idDossier ?? this.idDossier,
      idAthlete: idAthlete ?? this.idAthlete,
      objectif: objectif ?? this.objectif,
      poidsInitial: poidsInitial ?? this.poidsInitial,
      poidsActuel: poidsActuel ?? this.poidsActuel,
      poidsCible: poidsCible ?? this.poidsCible,
      tailleCm: tailleCm ?? this.tailleCm,
      remarques: remarques ?? this.remarques,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
    );
  }
}
