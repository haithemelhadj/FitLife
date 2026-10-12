import '../../domain/valeurs.dart';
import 'enums.dart';

class Offre {
  final int? idOffre;
  final int idEspace;
  final String nom;
  final String? description;
  final TypeOffre type;
  final MontantTnd prix;
  final int duree;
  final DateCivile dateDebut;
  final DateCivile? dateFin;
  final StatutOffre statut;

  Offre({
    this.idOffre,
    required this.idEspace,
    required String nom,
    String? description,
    required this.type,
    required this.prix,
    required this.duree,
    required this.dateDebut,
    this.dateFin,
    this.statut = StatutOffre.inactive,
  }) : nom = texteRequis(nom),
       description = texteOptionnel(description) {
    verifierIdentifiant(idEspace);
    if (idOffre != null) verifierIdentifiant(idOffre!);
    if (duree <= 0 || (type == TypeOffre.seance && duree != 1)) {
      throw const FormatException('Durée de l’offre invalide.');
    }
    if (dateFin != null && dateFin!.compareTo(dateDebut) < 0) {
      throw const FormatException('Dates de l’offre invalides.');
    }
  }

  factory Offre.fromJson(Map<String, dynamic> json) => Offre(
    idOffre: json['id_offre'] as int,
    idEspace: json['id_espace'] as int,
    nom: json['nom'] as String,
    description: json['description'] as String?,
    type: TypeOffre.depuisCode(json['type'] as String),
    prix: MontantTnd.parse(json['prix'] as String),
    duree: json['duree'] as int,
    dateDebut: DateCivile.parse(json['date_debut'] as String),
    dateFin: json['date_fin'] == null
        ? null
        : DateCivile.parse(json['date_fin'] as String),
    statut: StatutOffre.depuisCode(json['statut'] as String),
  );

  StatutOffre statutAu(DateCivile dateServeur) =>
      dateFin != null && dateFin!.compareTo(dateServeur) < 0
      ? StatutOffre.expiree
      : statut;

  bool ouverteAu(DateCivile dateServeur) =>
      statutAu(dateServeur) == StatutOffre.active &&
      dateDebut.compareTo(dateServeur) <= 0;

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'type': type.code,
    'prix': prix.toString(),
    'duree': duree,
    'date_debut': dateDebut.toString(),
    'date_fin': dateFin?.toString(),
    'statut': statut.code,
  };

  Map<String, dynamic> toInsertJson() => {...toJson(), 'id_espace': idEspace};
}
