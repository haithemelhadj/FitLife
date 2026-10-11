import 'dart:convert';
import 'enums_nutrition.dart';

/// Composant d'un repas représentant un aliment individuel (issu d'Open Food Facts ou saisie manuelle).
class AlimentRepas {
  final String? codeBarres;
  final String nom;
  final String? marque;
  final double quantiteGrammes;
  final int calories;
  final double proteines;
  final double glucides;
  final double lipides;

  AlimentRepas({
    this.codeBarres,
    required this.nom,
    this.marque,
    this.quantiteGrammes = 100.0,
    required this.calories,
    required this.proteines,
    required this.glucides,
    required this.lipides,
  });

  Map<String, dynamic> toMap() {
    return {
      'code_barres': codeBarres,
      'nom': nom,
      'marque': marque,
      'quantite_grammes': quantiteGrammes,
      'calories': calories,
      'proteines': proteines,
      'glucides': glucides,
      'lipides': lipides,
    };
  }

  factory AlimentRepas.fromMap(Map<String, dynamic> map) {
    return AlimentRepas(
      codeBarres: map['code_barres']?.toString(),
      nom: map['nom']?.toString() ?? 'Aliment',
      marque: map['marque']?.toString(),
      quantiteGrammes: double.tryParse(map['quantite_grammes']?.toString() ?? '100') ?? 100.0,
      calories: int.tryParse(map['calories']?.toString() ?? '0') ?? 0,
      proteines: double.tryParse(map['proteines']?.toString() ?? '0') ?? 0.0,
      glucides: double.tryParse(map['glucides']?.toString() ?? '0') ?? 0.0,
      lipides: double.tryParse(map['lipides']?.toString() ?? '0') ?? 0.0,
    );
  }
}

/// Entité 4 : Repas
/// Relation : ProgrammeNutritionnel 1..N - Repas
/// Représente un repas planifié (Petit-déjeuner, Déjeuner, Dîner, Collation) avec ses nutriments totaux.
class Repas {
  final String idRepas;
  final String idProgramme;
  final String nom;
  final TypeRepas type;
  final String? heureRecommandee;
  final int calories;
  final double proteinesG;
  final double glucidesG;
  final double lipidesG;
  final List<AlimentRepas> aliments;
  final int ordre;
  final DateTime? createdAt;

  Repas({
    required this.idRepas,
    required this.idProgramme,
    required this.nom,
    required this.type,
    this.heureRecommandee,
    required this.calories,
    required this.proteinesG,
    required this.glucidesG,
    required this.lipidesG,
    this.aliments = const [],
    this.ordre = 1,
    this.createdAt,
  });

  String get typeTexte => formatEnumNutrition(type);

  /// Calcule les totaux en sommant la liste des aliments si spécifiée
  factory Repas.depuisAliments({
    required String idRepas,
    required String idProgramme,
    required String nom,
    required TypeRepas type,
    String? heureRecommandee,
    required List<AlimentRepas> aliments,
    int ordre = 1,
  }) {
    int totalCal = 0;
    double totalProt = 0;
    double totalGluc = 0;
    double totalLip = 0;

    for (final a in aliments) {
      totalCal += a.calories;
      totalProt += a.proteines;
      totalGluc += a.glucides;
      totalLip += a.lipides;
    }

    return Repas(
      idRepas: idRepas,
      idProgramme: idProgramme,
      nom: nom,
      type: type,
      heureRecommandee: heureRecommandee,
      calories: totalCal,
      proteinesG: totalProt,
      glucidesG: totalGluc,
      lipidesG: totalLip,
      aliments: aliments,
      ordre: ordre,
    );
  }

  /// Conversion vers Map pour insertion/mise à jour dans Supabase (table "repas")
  Map<String, dynamic> toMap() {
    return {
      'id_programme': idProgramme,
      'nom': nom,
      'type': type.name,
      'heure_recommandee': heureRecommandee,
      'calories': calories,
      'proteines_g': proteinesG,
      'glucides_g': glucidesG,
      'lipides_g': lipidesG,
      'aliments_json': aliments.map((a) => a.toMap()).toList(),
      'ordre': ordre,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Création depuis une ligne Supabase
  factory Repas.fromMap(Map<String, dynamic> data) {
    List<AlimentRepas> alimentsList = [];
    final jsonAliments = data['aliments_json'];

    if (jsonAliments != null) {
      List<dynamic> liste;
      if (jsonAliments is String) {
        try {
          liste = jsonDecode(jsonAliments);
        } catch (_) {
          liste = [];
        }
      } else if (jsonAliments is List) {
        liste = jsonAliments;
      } else {
        liste = [];
      }

      for (var item in liste) {
        if (item is Map<String, dynamic>) {
          alimentsList.add(AlimentRepas.fromMap(item));
        } else if (item is Map) {
          alimentsList.add(AlimentRepas.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Repas(
      idRepas: data['id']?.toString() ?? '',
      idProgramme: data['id_programme']?.toString() ?? '',
      nom: data['nom']?.toString() ?? '',
      type: TypeRepas.values.firstWhere(
        (t) => t.name.toUpperCase() == (data['type'] ?? '').toString().toUpperCase(),
        orElse: () => TypeRepas.DEJEUNER,
      ),
      heureRecommandee: data['heure_recommandee']?.toString(),
      calories: int.tryParse(data['calories']?.toString() ?? '0') ?? 0,
      proteinesG: double.tryParse(data['proteines_g']?.toString() ?? '0') ?? 0.0,
      glucidesG: double.tryParse(data['glucides_g']?.toString() ?? '0') ?? 0.0,
      lipidesG: double.tryParse(data['lipides_g']?.toString() ?? '0') ?? 0.0,
      aliments: alimentsList,
      ordre: int.tryParse(data['ordre']?.toString() ?? '1') ?? 1,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  factory Repas.fromJson(Map<String, dynamic> json) => Repas.fromMap(json);

  Repas copyWith({
    String? idRepas,
    String? idProgramme,
    String? nom,
    TypeRepas? type,
    String? heureRecommandee,
    int? calories,
    double? proteinesG,
    double? glucidesG,
    double? lipidesG,
    List<AlimentRepas>? aliments,
    int? ordre,
    DateTime? createdAt,
  }) {
    return Repas(
      idRepas: idRepas ?? this.idRepas,
      idProgramme: idProgramme ?? this.idProgramme,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      heureRecommandee: heureRecommandee ?? this.heureRecommandee,
      calories: calories ?? this.calories,
      proteinesG: proteinesG ?? this.proteinesG,
      glucidesG: glucidesG ?? this.glucidesG,
      lipidesG: lipidesG ?? this.lipidesG,
      aliments: aliments ?? this.aliments,
      ordre: ordre ?? this.ordre,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
