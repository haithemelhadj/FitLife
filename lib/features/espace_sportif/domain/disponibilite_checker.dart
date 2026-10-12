import '../data/models/disponibilite_espace.dart';
import '../data/models/enums.dart';
import '../data/models/equipement.dart';
import '../data/models/espace_sportif.dart';
import 'valeurs.dart';

enum MotifIndisponibilite {
  espaceIndisponible('ESPACE_INDISPONIBLE'),
  horsHoraires('HORS_HORAIRES'),
  conflitSeance('CONFLIT_SEANCE'),
  equipementIndisponible('EQUIPEMENT_INDISPONIBLE');

  final String code;
  const MotifIndisponibilite(this.code);
}

class ExigenceEquipement {
  final int idEquipement;
  final int quantite;

  ExigenceEquipement({required this.idEquipement, required this.quantite}) {
    verifierIdentifiant(idEquipement);
    if (quantite <= 0) throw ArgumentError.value(quantite, 'quantite');
  }
}

class CreneauOccupe {
  final int idEspace;
  final DateCivile date;
  final HeureLocale debut;
  final HeureLocale fin;

  CreneauOccupe({
    required this.idEspace,
    required this.date,
    required this.debut,
    required this.fin,
  }) {
    verifierIdentifiant(idEspace);
    if (debut.compareTo(fin) >= 0) {
      throw const FormatException('Créneau invalide.');
    }
  }
}

class ResultatDisponibilite {
  final List<MotifIndisponibilite> motifs;

  ResultatDisponibilite(Iterable<MotifIndisponibilite> motifs)
    : motifs = List.unmodifiable(motifs);

  bool get disponible => motifs.isEmpty;
}

// Ce contrôle informe l’interface. La réservation doit être vérifiée en base.
class DisponibiliteChecker {
  ResultatDisponibilite verifier({
    required EspaceSportif espace,
    required bool gestionnaireActif,
    required DateCivile date,
    required HeureLocale debut,
    required HeureLocale fin,
    required List<DisponibiliteEspace> horaires,
    required List<Equipement> equipements,
    required List<ExigenceEquipement> exigences,
    required List<CreneauOccupe> occupations,
  }) {
    if (espace.idEspace == null || debut.compareTo(fin) >= 0) {
      throw const FormatException('Demande de disponibilité invalide.');
    }
    final motifs = <MotifIndisponibilite>[];
    if (espace.statut != StatutEspace.actif || !gestionnaireActif) {
      motifs.add(MotifIndisponibilite.espaceIndisponible);
    }
    if (!horaires.any(
      (horaire) =>
          horaire.idEspace == espace.idEspace &&
          horaire.jour.index + 1 == date.jourSemaine &&
          horaire.heureOuverture.compareTo(debut) <= 0 &&
          horaire.heureFermeture.compareTo(fin) >= 0,
    )) {
      motifs.add(MotifIndisponibilite.horsHoraires);
    }
    if (occupations.any(
      (creneau) =>
          creneau.idEspace == espace.idEspace &&
          creneau.date == date &&
          creneau.debut.compareTo(fin) < 0 &&
          creneau.fin.compareTo(debut) > 0,
    )) {
      motifs.add(MotifIndisponibilite.conflitSeance);
    }
    final quantites = <int, int>{};
    for (final exigence in exigences) {
      quantites.update(
        exigence.idEquipement,
        (quantite) => quantite + exigence.quantite,
        ifAbsent: () => exigence.quantite,
      );
    }
    if (quantites.entries.any(
      (besoin) => !equipements.any(
        (equipement) =>
            equipement.idEspace == espace.idEspace &&
            equipement.idEquipement == besoin.key &&
            equipement.utilisable &&
            equipement.quantite >= besoin.value,
      ),
    )) {
      motifs.add(MotifIndisponibilite.equipementIndisponible);
    }
    return ResultatDisponibilite(motifs);
  }
}
