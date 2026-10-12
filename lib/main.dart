import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/session_app.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/accueil_session_screen.dart';
import 'features/espace_sportif/data/repositories/espace_public_repository.dart';
import 'features/espace_sportif/presentation/admin/dashboard_espaces_screen.dart';
import 'features/espace_sportif/presentation/espaces/espace_list_screen.dart';
import 'features/evenement/presentation/categories/categorie_list_screen.dart';
import 'features/evenement/presentation/evenements/evenement_list_screen.dart';
import 'features/evenement/presentation/inscription/inscription_list_screen.dart';
import 'navigation_bas_screen.dart';
import 'navigation_onglets_screen.dart';
import 'features/evenement/presentation/paiements/paiement_list_screen.dart';
import 'features/entrainement/presentation/exploration_musculaire/body_screen.dart';
import 'features/entrainement/presentation/programmes/programme_list_screen.dart';
import 'features/entrainement/presentation/entrainement_navigation_bas_screen.dart';
import 'features/entrainement/presentation/entrainement_navigation_onglets_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.clePublishable,
  );
  // Connexion de test : active seulement si les valeurs sont fournies au lancement.
  const emailTest = String.fromEnvironment('DEV_EMAIL');
  const mdpTest = String.fromEnvironment('DEV_PASSWORD');

  if (emailTest.isNotEmpty && mdpTest.isNotEmpty) {
    await Supabase.instance.client.auth.signInWithPassword(
      email: emailTest,
      password: mdpTest,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final navigation = GlobalKey<NavigatorState>();
  late final SessionApp session;
  ModeSession dernierMode = ModeSession.chargement;
  @override
  void initState() {
    super.initState();
    session = SessionApp(AuthRepository(Supabase.instance.client));
    session.addListener(changerPage);
    session.initialiser();
  }

  void changerPage() {
    if (dernierMode == session.mode) return;
    dernierMode = session.mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigation.currentState?.pushNamedAndRemoveUntil(
        session.mode == ModeSession.deconnecte ? '/connexion' : '/',
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    session.removeListener(changerPage);
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: session,
      child: MaterialApp(
        navigatorKey: navigation,
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        initialRoute: '/connexion',
        routes: {
          '/connexion': (context) => const LoginScreen(),
          '/': (context) =>
              const AccesSession(invites: true, child: AccueilSessionScreen()),
          '/dashboard': (context) => AccesSession(
            admin: true,
            child: DashboardEspacesScreen(client: Supabase.instance.client),
          ),
          '/espaces-sportifs': (context) => AccesSession(
            invites: true,
            child: EspaceListScreen(
              repository: SessionScope.of(context).mode == ModeSession.invite
                  ? EspacePublicRepository(Supabase.instance.client)
                  : null,
            ),
          ),
          '/evenements': (context) =>
              const AccesSession(child: EvenementListScreen()),
          '/categories': (context) =>
              const AccesSession(child: CategorieListScreen()),
          '/inscriptions': (context) =>
              const AccesSession(child: InscriptionListScreen()),
          '/paiements': (context) =>
              const AccesSession(child: PaiementListScreen()),
          '/onglets': (context) =>
              const AccesSession(child: NavigationOngletsScreen()),
          '/bas': (context) => const AccesSession(child: NavigationBasScreen()),
          '/corps': (context) => const AccesSession(child: BodyScreen()),
          '/programmes': (context) =>
              const AccesSession(child: ProgrammeListScreen()),
          '/entrainement-bas': (context) =>
              const AccesSession(child: EntrainementNavigationBasScreen()),
          '/entrainement-onglets': (context) =>
              const AccesSession(child: EntrainementNavigationOngletsScreen()),
        },
      ),
    );
  }
}
