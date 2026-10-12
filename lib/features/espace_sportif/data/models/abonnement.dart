import '../../domain/valeurs.dart';
import 'enums.dart';

class Abonnement {
  final int idAbonnement;
  final String idAthlete;
  final int idOffre;
  final DateCivile dateDebut;
  final DateCivile dateFin;
  final MontantTnd montant;
  final StatutAbonnement statut;

  Abonnement({
    required this.idAbonnement,
    required this.idAthlete,
    required this.idOffre,
    required this.dateDebut,
    required this.dateFin,
    required this.montant,
    required this.statut,
  }) {
    verifierIdentifiant(idAbonnement);
    verifierIdentifiant(idOffre);
    if (dateFin.compareTo(dateDebut) < 0) {
      throw const FormatException('Dates invalides.');
    }
  }

  factory Abonnement.fromJson(Map<String, dynamic> json) => Abonnement(
    idAbonnement: json['id_abonnement'] as int,
    idAthlete: json['id_athlete'] as String,
    idOffre: json['id_offre'] as int,
    dateDebut: DateCivile.parse(json['date_debut'] as String),
    dateFin: DateCivile.parse(json['date_fin'] as String),
    montant: MontantTnd.parse(json['montant'] as String),
    statut: StatutAbonnement.depuisCode(json['statut'] as String),
  );

  // Les dates métier proviennent du serveur et non du fuseau de l’appareil.
  StatutAbonnement statutAu(DateCivile dateServeur) =>
      (statut == StatutAbonnement.actif ||
              statut == StatutAbonnement.suspendu) &&
          dateFin.compareTo(dateServeur) < 0
      ? StatutAbonnement.expire
      : statut;
}
