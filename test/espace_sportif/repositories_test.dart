import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coach_app/features/espace_sportif/data/models/enums.dart';
import 'package:coach_app/features/espace_sportif/data/models/espace_sportif.dart';
import 'package:coach_app/features/espace_sportif/data/models/offre.dart';
import 'package:coach_app/features/espace_sportif/data/repositories/abonnement_repository.dart';
import 'package:coach_app/features/espace_sportif/data/repositories/espace_sportif_repository.dart';
import 'package:coach_app/features/espace_sportif/data/repositories/offre_repository.dart';
import 'package:coach_app/features/espace_sportif/domain/valeurs.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  late List<({String methode, String chemin, Map<String, dynamic> corps})>
  requetes;
  late Object Function(HttpRequest) reponse;
  var statutHttp = 200;

  setUp(() async {
    requetes = [];
    statutHttp = 200;
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((requete) async {
      final texte = await utf8.decoder.bind(requete).join();
      requetes.add((
        methode: requete.method,
        chemin: requete.uri.path,
        corps: texte.isEmpty
            ? {}
            : Map<String, dynamic>.from(jsonDecode(texte) as Map),
      ));
      requete.response.statusCode = statutHttp;
      requete.response.headers.contentType = ContentType.json;
      requete.response.write(jsonEncode(reponse(requete)));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${serveur.port}',
      'cle_de_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  test(
    'La création d’un espace ne transmet ni identifiant ni propriétaire',
    () async {
      reponse = (_) => {
        'id_espace': 1,
        'nom': 'Salle',
        'type': 'SALLE',
        'adresse': 'Tunis',
        'statut': 'INACTIF',
        'id_gestionnaire': 'gestionnaire',
      };
      final resultat = await EspaceSportifRepository(client).ajouter(
        EspaceSportif(
          idEspace: 99,
          idGestionnaire: 'autre',
          nom: 'Salle',
          type: TypeEspace.salle,
          adresse: 'Tunis',
        ),
      );
      expect(resultat.idEspace, 1);
      expect(requetes.single.corps.containsKey('id_espace'), isFalse);
      expect(requetes.single.corps.containsKey('id_gestionnaire'), isFalse);
    },
  );

  test(
    'La souscription ne transmet que l’offre et lit les millimes exacts',
    () async {
      reponse = (_) => {
        'id_abonnement': 1,
        'id_athlete': 'athlète',
        'id_offre': 2,
        'date_debut': '2026-10-12',
        'date_fin': '2026-11-10',
        'montant': '80.125',
        'statut': 'ACTIF',
      };
      final resultat = await AbonnementRepository(client).souscrire(2);
      expect(requetes.single.chemin, '/rest/v1/rpc/souscrire_offre');
      expect(requetes.single.corps, {'p_offre': 2});
      expect(resultat.montant.millimes, 80125);
    },
  );

  test('La modification d’une offre préserve son rattachement et utilise la vue monétaire', () async {
    reponse = (requete) => requete.method == 'PATCH'
        ? {'id_offre': 2}
        : {
            'id_offre': 2,
            'id_espace': 1,
            'nom': 'Accès',
            'type': 'ABONNEMENT',
            'prix': '0.125',
            'duree': 30,
            'date_debut': '2026-10-12',
            'date_fin': null,
            'statut': 'ACTIVE',
          };
    final resultat = await OffreRepository(client).modifier(
      Offre(
        idOffre: 2,
        idEspace: 1,
        nom: 'Accès',
        type: TypeOffre.abonnement,
        prix: MontantTnd(125),
        duree: 30,
        dateDebut: DateCivile.parse('2026-10-12'),
        statut: StatutOffre.active,
      ),
    );
    expect(requetes.first.corps['prix'], '0.125');
    expect(requetes.first.corps.containsKey('id_espace'), isFalse);
    expect(requetes.last.chemin, '/rest/v1/offres_lecture');
    expect(resultat.prix.millimes, 125);
  });

  test(
    'La désactivation ne remplace pas les autres champs de l’espace',
    () async {
      reponse = (requete) {
        expect(requete.uri.queryParameters['id_espace'], 'eq.7');
        return {
          'id_espace': 7,
          'nom': 'Nom récent',
          'adresse': 'Tunis',
          'type': 'SALLE',
          'statut': 'INACTIF',
          'id_gestionnaire': 'gestionnaire',
        };
      };
      final espace = await EspaceSportifRepository(client)
          .changerStatut(7, StatutEspace.inactif);
      expect(requetes.single.methode, 'PATCH');
      expect(requetes.single.corps, {'statut': 'INACTIF'});
      expect(espace.nom, 'Nom récent');
      expect(espace.statut, StatutEspace.inactif);
    },
  );

  test('Un refus serveur remonte au lieu de simuler une réussite', () async {
    statutHttp = 403;
    reponse = (_) => {
      'code': '42501',
      'message': 'Accès refusé.',
      'details': null,
      'hint': null,
    };
    await expectLater(
      AbonnementRepository(client).changerStatut(1, StatutAbonnement.annule),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
    );
  });
}
