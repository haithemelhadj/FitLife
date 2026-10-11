import 'enums_nutrition.dart';

/// Entité 3 : ProgrammeNutritionnel
/// Relation : DossierNutritionnel 1..N - ProgrammeNutritionnel - 1..N Repas
/// Définit l'objectif, les calories journalières, la répartition des macronutriments et le budget.
class ProgrammeNutritionnel {
  final String idProgramme;
  final String idDossier;
  final String? idNutritionniste;
  final String titre;
  final String? description;
  final ObjectifNutrition objectif;
  final int caloriesCible;
  final double proteinesCibleG;
  final double glucidesCibleG;
  final double lipidesCibleG;
  final StatutProgramme statut;
  final double? budgetMontant;
  final String budgetDevise;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final DateTime? createdAt;

  ProgrammeNutritionnel({
    required this.idProgramme,
    required this.idDossier,
    this.idNutritionniste,
    required this.titre,
    this.description,
    required this.objectif,
    required this.caloriesCible,
    required this.proteinesCibleG,
    required this.glucidesCibleG,
    required this.lipidesCibleG,
    this.statut = StatutProgramme.ACTIF,
    this.budgetMontant,
    this.budgetDevise = 'EUR',
    required this.dateDebut,
    this.dateFin,
    this.createdAt,
  });

  /// Calcule l'apport calorique total réel correspondant aux macronutriments prescrits :
  /// 1g Protéines = 4 kcal, 1g Glucides = 4 kcal, 1g Lipides = 9 kcal
  double get caloriesCalculeesDepuisMacros {
    return (proteinesCibleG * 4.0) + (glucidesCibleG * 4.0) + (lipidesCibleG * 9.0);
  }

  /// Part énergétique des protéines en pourcentage
  double get pourcentageProteines {
    if (caloriesCible <= 0) return 0;
    return ((proteinesCibleG * 4.0) / caloriesCible) * 100.0;
  }

  /// Part énergétique des glucides en pourcentage
  double get pourcentageGlucides {
    if (caloriesCible <= 0) return 0;
    return ((glucidesCibleG * 4.0) / caloriesCible) * 100.0;
  }

  /// Part énergétique des lipides en pourcentage
  double get pourcentageLipides {
    if (caloriesCible <= 0) return 0;
    return ((lipidesCibleG * 9.0) / caloriesCible) * 100.0;
  }

  bool get estActif => statut == StatutProgramme.ACTIF;
  bool get estTermine => statut == StatutProgramme.TERMINE;
  bool get estSuspendu => statut == StatutProgramme.SUSPENDU;
  bool get estAnnule => statut == StatutProgramme.ANNULE;

  String get statutTexte => formatEnumNutrition(statut);
  String get objectifTexte => formatEnumNutrition(objectif);

  /// Conversion vers Map pour insertion/mise à jour dans Supabase (table "programme_nutritionnel")
  Map<String, dynamic> toMap() {
    return {
      'id_dossier': idDossier,
      'id_nutritionniste': idNutritionniste,
      'titre': titre,
      'description': description,
      'calories_cible': caloriesCible,
      'proteines_cible_g': proteinesCibleG,
      'glucides_cible_g': glucidesCibleG,
      'lipides_cible_g': lipidesCibleG,
      'statut': statut.name,
      'budget_montant': budgetMontant,
      'budget_devise': budgetDevise,
      'date_debut': dateDebut.toIso8601String().split('T').first,
      'date_fin': dateFin?.toIso8601String().split('T').first,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Création d'une instance depuis une ligne Supabase
  factory ProgrammeNutritionnel.fromMap(Map<String, dynamic> data) {
    return ProgrammeNutritionnel(
      idProgramme: data['id']?.toString() ?? '',
      idDossier: data['id_dossier']?.toString() ?? '',
      idNutritionniste: data['id_nutritionniste']?.toString(),
      titre: data['titre']?.toString() ?? '',
      description: data['description']?.toString(),
      objectif: ObjectifNutrition.values.firstWhere(
        (obj) => obj.name.toUpperCase() == (data['objectif'] ?? '').toString().toUpperCase(),
        orElse: () => ObjectifNutrition.MAINTIEN,
      ),
      caloriesCible: int.tryParse(data['calories_cible']?.toString() ?? '0') ?? 0,
      proteinesCibleG: double.tryParse(data['proteines_cible_g']?.toString() ?? '0') ?? 0.0,
      glucidesCibleG: double.tryParse(data['glucides_cible_g']?.toString() ?? '0') ?? 0.0,
      lipidesCibleG: double.tryParse(data['lipides_cible_g']?.toString() ?? '0') ?? 0.0,
      statut: StatutProgramme.values.firstWhere(
        (st) => st.name.toUpperCase() == (data['statut'] ?? '').toString().toUpperCase(),
        orElse: () => StatutProgramme.ACTIF,
      ),
      budgetMontant: data['budget_montant'] != null
          ? double.tryParse(data['budget_montant'].toString())
          : null,
      budgetDevise: data['budget_devise']?.toString() ?? 'EUR',
      dateDebut: data['date_debut'] != null
          ? DateTime.parse(data['date_debut'].toString())
          : DateTime.now(),
      dateFin: data['date_fin'] != null
          ? DateTime.tryParse(data['date_fin'].toString())
          : null,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  factory ProgrammeNutritionnel.fromJson(Map<String, dynamic> json) => ProgrammeNutritionnel.fromMap(json);

  ProgrammeNutritionnel copyWith({
    String? idProgramme,
    String? idDossier,
    String? idNutritionniste,
    String? titre,
    String? description,
    ObjectifNutrition? objectif,
    int? caloriesCible,
    double? proteinesCibleG,
    double? glucidesCibleG,
    double? lipidesCibleG,
    StatutProgramme? statut,
    double? budgetMontant,
    String? budgetDevise,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? createdAt,
  }) {
    return ProgrammeNutritionnel(
      idProgramme: idProgramme ?? this.idProgramme,
      idDossier: idDossier ?? this.idDossier,
      idNutritionniste: idNutritionniste ?? this.idNutritionniste,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      objectif: objectif ?? this.objectif,
      caloriesCible: caloriesCible ?? this.caloriesCible,
      proteinesCibleG: proteinesCibleG ?? this.proteinesCibleG,
      glucidesCibleG: glucidesCibleG ?? this.glucidesCibleG,
      lipidesCibleG: lipidesCibleG ?? this.lipidesCibleG,
      statut: statut ?? this.statut,
      budgetMontant: budgetMontant ?? this.budgetMontant,
      budgetDevise: budgetDevise ?? this.budgetDevise,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
