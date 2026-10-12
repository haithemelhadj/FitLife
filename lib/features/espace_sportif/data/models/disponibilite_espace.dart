import '../../domain/valeurs.dart';
import 'enums.dart';

class DisponibiliteEspace {
  final int? idDisponibilite;
  final int idEspace;
  final JourSemaine jour;
  final HeureLocale heureOuverture;
  final HeureLocale heureFermeture;

  DisponibiliteEspace({
    this.idDisponibilite,
    required this.idEspace,
    required this.jour,
    required this.heureOuverture,
    required this.heureFermeture,
  }) {
    verifierIdentifiant(idEspace);
    if (idDisponibilite != null) verifierIdentifiant(idDisponibilite!);
    if (heureOuverture.compareTo(heureFermeture) >= 0) {
      throw const FormatException('La fermeture doit suivre l’ouverture.');
    }
  }

  factory DisponibiliteEspace.fromJson(Map<String, dynamic> json) =>
      DisponibiliteEspace(
        idDisponibilite: json['id_disponibilite'] as int,
        idEspace: json['id_espace'] as int,
        jour: JourSemaine.depuisCode(json['jour'] as String),
        heureOuverture: HeureLocale.parse(json['heure_ouverture'] as String),
        heureFermeture: HeureLocale.parse(json['heure_fermeture'] as String),
      );

  Map<String, dynamic> toJson() => {
    'jour': jour.code,
    'heure_ouverture': heureOuverture.toString(),
    'heure_fermeture': heureFermeture.toString(),
  };

  Map<String, dynamic> toInsertJson() => {...toJson(), 'id_espace': idEspace};
}
