import '../../domain/valeurs.dart';
import 'enums.dart';

class Equipement {
  final int? idEquipement;
  final int idEspace;
  final String nom;
  final String? description;
  final int quantite;
  final EtatEquipement etat;

  Equipement({
    this.idEquipement,
    required this.idEspace,
    required String nom,
    String? description,
    required this.quantite,
    required this.etat,
  }) : nom = texteRequis(nom),
       description = texteOptionnel(description) {
    verifierIdentifiant(idEspace);
    if (idEquipement != null) verifierIdentifiant(idEquipement!);
    if (quantite < 0) throw ArgumentError.value(quantite, 'quantite');
  }

  factory Equipement.fromJson(Map<String, dynamic> json) => Equipement(
    idEquipement: json['id_equipement'] as int,
    idEspace: json['id_espace'] as int,
    nom: json['nom'] as String,
    description: json['description'] as String?,
    quantite: json['quantite'] as int,
    etat: EtatEquipement.depuisCode(json['etat'] as String),
  );

  bool get utilisable => etat == EtatEquipement.bon && quantite > 0;

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'quantite': quantite,
    'etat': etat.code,
  };

  Map<String, dynamic> toInsertJson() => {...toJson(), 'id_espace': idEspace};
}
