import 'dart:async';

import 'package:coach_app/features/auth/data/auth_repository.dart';
import 'package:coach_app/features/auth/domain/session_app.dart';
import 'package:coach_app/features/auth/presentation/accueil_session_screen.dart';
import 'package:coach_app/features/auth/presentation/login_screen.dart';
import 'package:coach_app/features/espace_sportif/data/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthTest extends AuthRepository {
  AuthTest()
    : super(
        SupabaseClient(
          'https://example.test',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  bool active = false;
  bool echec = false;
  RoleEspace? role = RoleEspace.athlete;
  String? emailRecu;
  int sorties = 0;
  final flux = StreamController<AuthState>.broadcast();
  @override
  Stream<AuthState> get changements => flux.stream;
  @override
  bool get connecte => active;
  @override
  Future<void> connecter(String email, String password) async {
    emailRecu = email;
    if (echec) throw const AuthException('Mot de passe refusé.');
    active = true;
  }

  @override
  Future<RoleEspace?> roleActif() async => active ? role : null;
  @override
  Future<void> deconnecter() async {
    sorties++;
    active = false;
  }
}

void main() {
  late AuthTest depot;
  late SessionApp session;
  setUp(() {
    depot = AuthTest();
    session = SessionApp(depot);
  });
  tearDown(() async {
    session.dispose();
    await depot.flux.close();
    await depot.client.dispose();
  });

  test('La session existante utilise le rôle serveur', () async {
    depot.active = true;
    depot.role = RoleEspace.admin;
    await session.initialiser();
    expect(session.administrateur, true);
  });
  test('Une connexion normale accepte un compte actif', () async {
    expect(await session.connecter('athlete@example.com', 'test'), true);
    expect(session.mode, ModeSession.utilisateur);
    expect(session.administrateur, false);
  });
  test('Le nom admin utilise le compte prévu et vérifie son rôle', () async {
    depot.role = RoleEspace.admin;
    expect(await session.connecter('admin', 'test', admin: true), true);
    expect(depot.emailRecu, 'haithemelhadj42@gmail.com');
    expect(session.administrateur, true);
  });
  test(
    'Un rôle non administrateur est déconnecté après une tentative admin',
    () async {
      expect(await session.connecter('admin', 'test', admin: true), false);
      expect(depot.sorties, 1);
      expect(session.administrateur, false);
      expect(session.mode, ModeSession.deconnecte);
    },
  );
  test('Un mauvais nom admin ne lance pas de connexion', () async {
    expect(await session.connecter('autre', 'test', admin: true), false);
    expect(depot.emailRecu, isNull);
  });
  test('Une erreur de connexion ne crée aucune session applicative', () async {
    depot.echec = true;
    expect(await session.connecter('a@example.com', 'test'), false);
    expect(session.mode, ModeSession.deconnecte);
  });
  test('Un profil inactif est refusé', () async {
    depot.role = null;
    expect(await session.connecter('a@example.com', 'test'), false);
    expect(depot.active, false);
  });
  test('Entrer comme invité supprime la session et les droits admin', () async {
    depot.active = true;
    depot.role = RoleEspace.admin;
    await session.initialiser();
    await session.entrerInvite();
    expect(session.mode, ModeSession.invite);
    expect(session.administrateur, false);
    expect(depot.active, false);
  });
  test('Les erreurs du flux Auth retirent immédiatement les droits', () async {
    depot.active = true;
    depot.role = RoleEspace.admin;
    await session.initialiser();
    depot.flux.addError(const AuthException('Hors ligne.'));
    await Future<void>.delayed(Duration.zero);
    expect(session.administrateur, false);
    expect(session.mode, ModeSession.deconnecte);
  });

  testWidgets('Le formulaire propose les trois modes et valide la saisie', (
    tester,
  ) async {
    session.mode = ModeSession.deconnecte;
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Utilisateur'), findsOneWidget);
    expect(find.text('Administrateur'), findsOneWidget);
    expect(find.text('Continuer comme invité'), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    expect(depot.emailRecu, isNull);
  });
  testWidgets('Le bouton Dashboard est visible uniquement aux admins', (
    tester,
  ) async {
    session.mode = ModeSession.utilisateur;
    session.role = RoleEspace.athlete;
    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: const MaterialApp(home: AccueilSessionScreen()),
      ),
    );
    expect(find.text('Dashboard'), findsNothing);
    session.role = RoleEspace.admin;
    session.publier();
    await tester.pump();
    expect(find.text('Dashboard'), findsOneWidget);
    session.role = null;
    session.mode = ModeSession.invite;
    session.publier();
    await tester.pump();
    expect(find.text('Dashboard'), findsNothing);
  });
  testWidgets(
    'Le tableau de bord refuse aussi une ouverture directe par un invité',
    (tester) async {
      session.mode = ModeSession.invite;
      await tester.pumpWidget(
        SessionScope(
          session: session,
          child: const MaterialApp(
            home: AccesSession(admin: true, child: Text('Secret')),
          ),
        ),
      );
      expect(find.text('Secret'), findsNothing);
      expect(find.text('Accès réservé aux administrateurs.'), findsOneWidget);
    },
  );
}
