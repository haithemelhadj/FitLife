import 'dart:async';

import 'package:coach_app/features/espace_sportif/data/models/contexte_espace.dart';
import 'package:coach_app/features/espace_sportif/data/models/enums.dart';
import 'package:coach_app/features/espace_sportif/data/models/espace_sportif.dart';
import 'package:coach_app/features/espace_sportif/data/repositories/espace_sportif_repository.dart';
import 'package:coach_app/features/espace_sportif/domain/valeurs.dart';
import 'package:coach_app/features/espace_sportif/presentation/espaces/espace_detail_screen.dart';
import 'package:coach_app/features/espace_sportif/presentation/espaces/espace_form_screen.dart';
import 'package:coach_app/features/espace_sportif/presentation/espaces/espace_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

EspaceSportif exemple({int id = 1, StatutEspace statut = StatutEspace.actif}) =>
    EspaceSportif(
      idEspace: id,
      nom: 'Salle $id',
      adresse: 'Tunis',
      type: TypeEspace.salle,
      statut: statut,
      idGestionnaire: 'gestionnaire',
    );

class DepotTest extends EspaceSportifRepository {
  DepotTest()
    : super(
        SupabaseClient(
          'https://example.test',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  bool connecte = true;
  RoleEspace? role = RoleEspace.gestionnaire;
  String utilisateur = 'gestionnaire';
  bool echec = false;
  bool echecSauvegarde = false;
  int lectures = 0;
  int ecritures = 0;
  EspaceSportif? sauvegarde;
  List<EspaceSportif> lignes = [exemple()];
  final evenements = StreamController<AuthState>.broadcast();
  final recherches = <({int? apres, bool propres, String texte})>[];
  Future<List<EspaceSportif>> Function(int?)? reponse;

  @override
  bool get estConnecte => connecte;
  @override
  Stream<AuthState> get changementsConnexion => evenements.stream;
  @override
  Future<ContexteEspace> getContexte() async => ContexteEspace(
    idUtilisateur: connecte ? utilisateur : null,
    role: role,
    dateServeur: DateCivile.parse('2026-10-12'),
  );
  @override
  Future<List<EspaceSportif>> rechercher({
    String recherche = '',
    TypeEspace? type,
    int? apresId,
    int limite = 20,
    bool mesEspaces = false,
  }) async {
    lectures++;
    recherches.add((apres: apresId, propres: mesEspaces, texte: recherche));
    if (echec) throw const PostgrestException(message: 'Erreur de test');
    if (reponse != null) return reponse!(apresId);
    return lignes
        .where(
          (e) =>
              (mesEspaces || e.statut == StatutEspace.actif) &&
              (type == null || e.type == type),
        )
        .toList();
  }

  @override
  Future<EspaceSportif> getEspace(int id) async {
    if (echec) {
      throw const PostgrestException(message: 'Absent', code: 'PGRST116');
    }
    return lignes.firstWhere((e) => e.idEspace == id);
  }

  @override
  Future<EspaceSportif> ajouter(EspaceSportif espace) async {
    ecritures++;
    if (echecSauvegarde) {
      throw const PostgrestException(message: 'Erreur de test');
    }
    sauvegarde = espace;
    final resultat = EspaceSportif(
      idEspace: 2,
      idGestionnaire: utilisateur,
      nom: espace.nom,
      adresse: espace.adresse,
      type: espace.type,
      statut: espace.statut,
    );
    lignes = [...lignes, resultat];
    return resultat;
  }

  @override
  Future<EspaceSportif> modifier(EspaceSportif espace) async {
    ecritures++;
    sauvegarde = espace;
    final resultat = EspaceSportif(
      idEspace: espace.idEspace,
      idGestionnaire: utilisateur,
      nom: espace.nom,
      adresse: espace.adresse,
      type: espace.type,
      statut: espace.statut,
    );
    lignes = lignes
        .map((e) => e.idEspace == espace.idEspace ? resultat : e)
        .toList();
    return resultat;
  }

  @override
  Future<EspaceSportif> changerStatut(int id, StatutEspace statut) async {
    ecritures++;
    lignes = lignes
        .map((e) => e.idEspace == id ? exemple(id: id, statut: statut) : e)
        .toList();
    return lignes.firstWhere((e) => e.idEspace == id);
  }
}

void main() {
  late DepotTest depot;
  setUp(() {
    depot = DepotTest();
  });
  tearDown(() async {
    await depot.evenements.close();
    await depot.client.dispose();
  });

  Future<void> afficher(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  Future<void> cliquer(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  Future<void> remplir(WidgetTester tester) async {
    await tester.enterText(find.byKey(const ValueKey('Nom')), 'Nouvelle salle');
    await tester.enterText(find.byKey(const ValueKey('Adresse')), 'Sousse');
    final choix = find.byType(DropdownButtonFormField<TypeEspace>);
    await cliquer(tester, choix);
    await tester.tap(find.text('Salle').last);
    await tester.pumpAndSettle();
  }

  testWidgets('Sans connexion, aucune lecture du catalogue', (tester) async {
    depot.connecte = false;
    await afficher(tester, EspaceListScreen(repository: depot));
    expect(
      find.text('Connectez-vous pour consulter les espaces sportifs.'),
      findsOneWidget,
    );
    expect(depot.lectures, 0);
    expect(find.text('Ajouter un espace'), findsNothing);
  });

  testWidgets('Un compte indisponible ne lit aucun espace', (tester) async {
    depot.role = null;
    await afficher(tester, EspaceListScreen(repository: depot));
    expect(
      find.text('Votre compte ne permet pas l’accès aux espaces sportifs.'),
      findsOneWidget,
    );
    expect(depot.lectures, 0);
  });

  testWidgets('Un athlète consulte les détails sans commandes de gestion', (
    tester,
  ) async {
    depot.role = RoleEspace.athlete;
    depot.utilisateur = 'athlete';
    await afficher(tester, EspaceListScreen(repository: depot));
    expect(find.text('Mes espaces'), findsNothing);
    expect(find.text('Ajouter un espace'), findsNothing);
    await cliquer(tester, find.text('Salle 1'));
    expect(find.text('Détails de l’espace'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Désactiver'), findsNothing);
  });

  testWidgets(
    'Le gestionnaire crée un espace inactif puis le retrouve dans ses espaces',
    (tester) async {
      await afficher(tester, EspaceListScreen(repository: depot));
      await cliquer(tester, find.text('Ajouter un espace'));
      await remplir(tester);
      await cliquer(tester, find.text('Enregistrer'));
      expect(depot.sauvegarde!.statut, StatutEspace.inactif);
      expect(depot.sauvegarde!.idGestionnaire, isNull);
      expect(depot.recherches.last.propres, isTrue);
      await tester.scrollUntilVisible(
        find.text('Nouvelle salle'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Nouvelle salle'), findsOneWidget);
    },
  );

  testWidgets('Les champs obligatoires et le type bloquent une création vide', (
    tester,
  ) async {
    await afficher(tester, EspaceFormScreen(repository: depot));
    await cliquer(tester, find.text('Enregistrer'));
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    expect(find.text('Choisissez un type.'), findsOneWidget);
    expect(depot.ecritures, 0);
  });

  testWidgets('Coordonnées incomplètes, email et URL invalides sont refusés', (
    tester,
  ) async {
    await afficher(tester, EspaceFormScreen(repository: depot));
    await remplir(tester);
    await tester.enterText(find.byKey(const ValueKey('Latitude')), '36');
    await tester.enterText(find.byKey(const ValueKey('Email')), 'invalide');
    await tester.enterText(
      find.byKey(const ValueKey('Site web')),
      'ftp://example.com',
    );
    await cliquer(tester, find.text('Enregistrer'));
    expect(find.text('Les deux coordonnées sont nécessaires.'), findsOneWidget);
    expect(find.text('Saisissez une adresse email valide.'), findsOneWidget);
    expect(
      find.text('Saisissez une URL HTTP ou HTTPS valide.'),
      findsOneWidget,
    );
    expect(depot.ecritures, 0);
  });

  testWidgets('Une sauvegarde échouée conserve la saisie pour réessayer', (
    tester,
  ) async {
    depot.echecSauvegarde = true;
    await afficher(tester, EspaceFormScreen(repository: depot));
    await remplir(tester);
    await cliquer(tester, find.text('Enregistrer'));
    expect(
      find.text(
        'Opération impossible. Vérifiez votre connexion puis réessayez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nouvelle salle'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('Une perte de rôle avant sauvegarde interdit la mutation', (
    tester,
  ) async {
    await afficher(tester, EspaceFormScreen(repository: depot));
    await remplir(tester);
    depot.role = RoleEspace.athlete;
    await cliquer(tester, find.text('Enregistrer'));
    expect(depot.ecritures, 0);
    expect(
      find.text('Votre compte ne peut pas modifier cet espace.'),
      findsOneWidget,
    );
  });

  testWidgets('Désactivation confirmée, sans suppression', (tester) async {
    await afficher(tester, EspaceDetailScreen(idEspace: 1, repository: depot));
    await cliquer(tester, find.text('Désactiver'));
    await cliquer(tester, find.text('Annuler'));
    expect(depot.ecritures, 0);
    await cliquer(tester, find.text('Désactiver'));
    await cliquer(tester, find.widgetWithText(FilledButton, 'Désactiver'));
    expect(depot.ecritures, 1);
    expect(depot.lignes.single.statut, StatutEspace.inactif);
    expect(find.text('Inactif'), findsOneWidget);
    expect(find.text('Désactiver'), findsNothing);
  });

  testWidgets('Chargement, erreur, nouvelle tentative et résultat vide', (
    tester,
  ) async {
    final attente = Completer<List<EspaceSportif>>();
    depot.reponse = (_) => attente.future;
    await tester.pumpWidget(
      MaterialApp(home: EspaceListScreen(repository: depot)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    attente.completeError(const PostgrestException(message: 'Erreur'));
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    depot.reponse = (_) async => [];
    await cliquer(tester, find.text('Réessayer'));
    expect(find.text('Aucun espace trouvé.'), findsOneWidget);
  });

  testWidgets(
    'La pagination conserve le filtre appliqué et utilise le dernier identifiant',
    (tester) async {
      depot.reponse = (apres) async => apres == null
          ? List.generate(20, (i) => exemple(id: i + 1))
          : [exemple(id: 21)];
      await afficher(tester, EspaceListScreen(repository: depot));
      await tester.enterText(find.byType(TextField), 'Brouillon non soumis');
      await tester.scrollUntilVisible(
        find.text('Charger la suite'),
        600,
        scrollable: find
            .descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await cliquer(tester, find.text('Charger la suite'));
      expect(depot.recherches.last.apres, 20);
      expect(depot.recherches.last.texte, '');
      await tester.scrollUntilVisible(
        find.text('Salle 21'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Salle 21'), findsOneWidget);
    },
  );

  testWidgets(
    'Un autre gestionnaire ne voit pas les commandes de modification',
    (tester) async {
      depot.utilisateur = 'autre';
      await afficher(
        tester,
        EspaceDetailScreen(idEspace: 1, repository: depot),
      );
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Désactiver'), findsNothing);
    },
  );

  testWidgets(
    'La modification revient aux détails avec les données actualisées',
    (tester) async {
      await afficher(
        tester,
        EspaceDetailScreen(idEspace: 1, repository: depot),
      );
      await cliquer(tester, find.text('Modifier'));
      await tester.enterText(
        find.byKey(const ValueKey('Nom')),
        'Salle corrigée',
      );
      await cliquer(tester, find.text('Enregistrer'));
      expect(find.text('Salle corrigée'), findsOneWidget);
      expect(depot.sauvegarde!.idEspace, 1);
    },
  );

  testWidgets(
    'Une réponse en retard ne réaffiche pas les données après déconnexion',
    (tester) async {
      final attente = Completer<List<EspaceSportif>>();
      depot.reponse = (_) => attente.future;
      await tester.pumpWidget(
        MaterialApp(home: EspaceListScreen(repository: depot)),
      );
      await tester.pump();
      depot.connecte = false;
      depot.evenements.add(AuthState(AuthChangeEvent.signedOut, null));
      await tester.pumpAndSettle();
      attente.complete([exemple()]);
      await tester.pumpAndSettle();
      expect(find.text('Salle 1'), findsNothing);
      expect(
        find.text('Connectez-vous pour consulter les espaces sportifs.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('La déconnexion efface les résultats déjà affichés', (
    tester,
  ) async {
    await afficher(tester, EspaceListScreen(repository: depot));
    depot.connecte = false;
    depot.evenements.add(AuthState(AuthChangeEvent.signedOut, null));
    await tester.pumpAndSettle();
    expect(find.text('Salle 1'), findsNothing);
    expect(
      find.text('Connectez-vous pour consulter les espaces sportifs.'),
      findsOneWidget,
    );
  });
}
