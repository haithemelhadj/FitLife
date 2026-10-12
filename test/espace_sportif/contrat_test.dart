import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/features/espace_sportif/data/models/abonnement.dart';
import 'package:coach_app/features/espace_sportif/data/models/disponibilite_espace.dart';
import 'package:coach_app/features/espace_sportif/data/models/enums.dart';
import 'package:coach_app/features/espace_sportif/data/models/equipement.dart';
import 'package:coach_app/features/espace_sportif/data/models/espace_sportif.dart';
import 'package:coach_app/features/espace_sportif/data/models/offre.dart';
import 'package:coach_app/features/espace_sportif/domain/disponibilite_checker.dart';
import 'package:coach_app/features/espace_sportif/domain/valeurs.dart';

void main() {
  group('Montants exacts', () {
    test('Les millimes sont conservés jusqu’à la limite SQL', () {
      expect(MontantTnd.parse('80.125').millimes, 80125);
      expect(MontantTnd.parse('0.001').toString(), '0.001');
      expect(MontantTnd.parse('999999999.999').millimes, 999999999999);
      expect(MontantTnd.parse('80').toString(), '80.000');
    });
    test(
      'Les fractions supplémentaires et valeurs non finies sont refusées',
      () {
        for (final texte in [
          '0.0001',
          '-1',
          'NaN',
          'Infinity',
          '1e3',
          '1000000000',
        ]) {
          expect(() => MontantTnd.parse(texte), throwsFormatException);
        }
      },
    );
  });

  group('Dates et heures civiles', () {
    test('Les dates invalides ne sont pas normalisées silencieusement', () {
      expect(() => DateCivile.parse('2026-02-29'), throwsFormatException);
      expect(() => DateCivile.parse('2026-13-01'), throwsFormatException);
      expect(
        () => DateCivile.parse('2026-10-12T23:00:00Z'),
        throwsFormatException,
      );
      expect(
        DateCivile.parse('2028-02-28').ajouterJours(1).toString(),
        '2028-02-29',
      );
      expect(
        DateCivile.parse('2026-12-31').ajouterJours(1).toString(),
        '2027-01-01',
      );
    });
    test('Les secondes et les heures impossibles sont refusées', () {
      for (final texte in ['08:00:01', '25:00', '12:60', '24:01']) {
        expect(() => HeureLocale.parse(texte), throwsFormatException);
      }
      expect(HeureLocale.parse('24:00').minutes, 1440);
      expect(HeureLocale.parse('08:15:00').toString(), '08:15:00');
    });
  });

  group('Contrat des modèles', () {
    test('Les coordonnées partielles ou non finies sont refusées', () {
      EspaceSportif espace(double? latitude, double? longitude) =>
          EspaceSportif(
            nom: 'Salle',
            type: TypeEspace.salle,
            adresse: 'Tunis',
            latitude: latitude,
            longitude: longitude,
          );
      expect(() => espace(36, null), throwsFormatException);
      expect(() => espace(double.nan, 10), throwsFormatException);
      expect(() => espace(36, double.infinity), throwsFormatException);
      expect(espace(null, null).statut, StatutEspace.inactif);
    });
    test(
      'Les écritures ne transmettent pas la propriété ou les identifiants',
      () {
        final espace = EspaceSportif(
          idEspace: 1,
          idGestionnaire: 'identité',
          nom: ' Salle ',
          description: ' ',
          type: TypeEspace.salle,
          adresse: ' Tunis ',
        );
        expect(espace.toJson().containsKey('id_gestionnaire'), isFalse);
        expect(espace.toJson().containsKey('id_espace'), isFalse);
        expect(espace.nom, 'Salle');
        expect(espace.description, isNull);
        final equipement = Equipement(
          idEquipement: 2,
          idEspace: 1,
          nom: 'Banc',
          quantite: 1,
          etat: EtatEquipement.bon,
        );
        expect(equipement.toJson().containsKey('id_espace'), isFalse);
        expect(equipement.toInsertJson()['id_espace'], 1);
      },
    );
    test('La fin de vente est inclusive et indépendante de la durée', () {
      final offre = Offre(
        idEspace: 1,
        nom: 'Accès',
        type: TypeOffre.abonnement,
        prix: MontantTnd.parse('80.125'),
        duree: 30,
        dateDebut: DateCivile.parse('2026-10-01'),
        dateFin: DateCivile.parse('2026-10-12'),
        statut: StatutOffre.active,
      );
      expect(offre.ouverteAu(DateCivile.parse('2026-09-30')), isFalse);
      expect(offre.ouverteAu(DateCivile.parse('2026-10-12')), isTrue);
      expect(
        offre.statutAu(DateCivile.parse('2026-10-13')),
        StatutOffre.expiree,
      );
      expect(offre.toJson()['prix'], '80.125');
      expect(
        () => Offre(
          idEspace: 1,
          nom: 'Séance',
          type: TypeOffre.seance,
          prix: MontantTnd(0),
          duree: 2,
          dateDebut: DateCivile.parse('2026-10-12'),
        ),
        throwsFormatException,
      );
    });
    test(
      'Un abonnement suspendu expire, un abonnement annulé reste annulé',
      () {
        Abonnement abonnement(StatutAbonnement statut) => Abonnement(
          idAbonnement: 1,
          idAthlete: 'athlète',
          idOffre: 1,
          dateDebut: DateCivile.parse('2026-10-01'),
          dateFin: DateCivile.parse('2026-10-12'),
          montant: MontantTnd(80000),
          statut: statut,
        );
        expect(
          abonnement(StatutAbonnement.actif)
              .statutAu(DateCivile.parse('2026-10-12')),
          StatutAbonnement.actif,
        );
        expect(
          abonnement(StatutAbonnement.suspendu)
              .statutAu(DateCivile.parse('2026-10-13')),
          StatutAbonnement.expire,
        );
        expect(
          abonnement(StatutAbonnement.annule)
              .statutAu(DateCivile.parse('2026-10-13')),
          StatutAbonnement.annule,
        );
      },
    );
  });

  group('Disponibilité indicative', () {
    final date = DateCivile.parse('2026-10-12');
    final espace = EspaceSportif(
      idEspace: 1,
      nom: 'Salle',
      type: TypeEspace.salle,
      adresse: 'Tunis',
      statut: StatutEspace.actif,
    );
    DisponibiliteEspace horaire(String debut, String fin) =>
        DisponibiliteEspace(
          idEspace: 1,
          jour: JourSemaine.lundi,
          heureOuverture: HeureLocale.parse(debut),
          heureFermeture: HeureLocale.parse(fin),
        );
    ResultatDisponibilite verifier({
      String debut = '10:00',
      String fin = '11:00',
      bool gestionnaireActif = true,
      List<DisponibiliteEspace>? horaires,
      List<Equipement> equipements = const [],
      List<ExigenceEquipement> exigences = const [],
      List<CreneauOccupe> occupations = const [],
    }) => DisponibiliteChecker().verifier(
      espace: espace,
      gestionnaireActif: gestionnaireActif,
      date: date,
      debut: HeureLocale.parse(debut),
      fin: HeureLocale.parse(fin),
      horaires: horaires ?? [horaire('08:00', '18:00')],
      equipements: equipements,
      exigences: exigences,
      occupations: occupations,
    );

    test('Une séance adjacente ne bloque pas le créneau', () {
      final occupation = CreneauOccupe(
        idEspace: 1,
        date: date,
        debut: HeureLocale.parse('09:00'),
        fin: HeureLocale.parse('10:00'),
      );
      expect(verifier(occupations: [occupation]).disponible, isTrue);
      expect(
        verifier(debut: '09:59', occupations: [occupation]).motifs,
        contains(MotifIndisponibilite.conflitSeance),
      );
    });
    test('Une séance ne traverse pas une interruption des horaires', () {
      expect(
        verifier(
          debut: '11:00',
          fin: '14:00',
          horaires: [horaire('08:00', '12:00'), horaire('13:00', '18:00')],
        ).motifs,
        contains(MotifIndisponibilite.horsHoraires),
      );
      expect(
        verifier(horaires: []).motifs,
        contains(MotifIndisponibilite.horsHoraires),
      );
    });
    test('Les quantités répétées sont additionnées', () {
      final equipement = Equipement(
        idEquipement: 1,
        idEspace: 1,
        nom: 'Haltères',
        quantite: 2,
        etat: EtatEquipement.bon,
      );
      final exigences = [
        ExigenceEquipement(idEquipement: 1, quantite: 2),
        ExigenceEquipement(idEquipement: 1, quantite: 1),
      ];
      expect(
        verifier(equipements: [equipement], exigences: exigences).motifs,
        contains(MotifIndisponibilite.equipementIndisponible),
      );
    });
    test(
      'Un équipement endommagé ou appartenant à un autre espace est refusé',
      () {
        for (final etat in [
          EtatEquipement.endommage,
          EtatEquipement.enMaintenance,
          EtatEquipement.horsService,
        ]) {
          expect(
            verifier(
              equipements: [
                Equipement(
                  idEquipement: 1,
                  idEspace: 1,
                  nom: 'Banc',
                  quantite: 2,
                  etat: etat,
                ),
              ],
              exigences: [ExigenceEquipement(idEquipement: 1, quantite: 1)],
            ).disponible,
            isFalse,
          );
        }
        expect(
          verifier(
            equipements: [
              Equipement(
                idEquipement: 1,
                idEspace: 2,
                nom: 'Banc',
                quantite: 2,
                etat: EtatEquipement.bon,
              ),
            ],
            exigences: [ExigenceEquipement(idEquipement: 1, quantite: 1)],
          ).disponible,
          isFalse,
        );
      },
    );
    test('Un gestionnaire inactif rend son espace indisponible', () {
      expect(
        verifier(gestionnaireActif: false).motifs,
        contains(MotifIndisponibilite.espaceIndisponible),
      );
    });
    test('Les demandes invalides ne produisent pas un résultat disponible', () {
      expect(
        () => verifier(debut: '11:00', fin: '10:00'),
        throwsFormatException,
      );
      expect(
        () => ExigenceEquipement(idEquipement: 1, quantite: 0),
        throwsArgumentError,
      );
    });
  });
}
