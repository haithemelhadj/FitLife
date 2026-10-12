import 'package:flutter/material.dart';

import '../../../core/utils/outils.dart';
import '../domain/session_app.dart';

class AccueilSessionScreen extends StatelessWidget {
  const AccueilSessionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final invite = session.mode == ModeSession.invite;
    return Scaffold(
      appBar: AppBar(title: const Text('FitLife')),
      drawer: construireDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            invite ? 'Bienvenue, invité' : 'Bienvenue dans FitLife',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            invite
                ? 'Consultez les espaces sportifs publics. Connectez-vous pour accéder aux actions de votre compte.'
                : 'Accédez aux fonctionnalités depuis les boutons et le menu.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/espaces-sportifs'),
            icon: const Icon(Icons.sports_handball),
            label: const Text('Espaces sportifs'),
          ),
          if (session.administrateur) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              icon: const Icon(Icons.dashboard),
              label: const Text('Dashboard'),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: session.occupe ? null : session.quitter,
            child: Text(invite ? 'Se connecter' : 'Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class AccesSession extends StatelessWidget {
  final Widget child;
  final bool invites;
  final bool admin;
  const AccesSession({
    super.key,
    required this.child,
    this.invites = false,
    this.admin = false,
  });
  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (session.mode == ModeSession.chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final autorise = admin
        ? session.administrateur
        : session.mode == ModeSession.utilisateur ||
              (invites && session.mode == ModeSession.invite);
    if (autorise) return child;
    return Scaffold(
      appBar: AppBar(title: const Text('Accès limité')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              admin
                  ? 'Accès réservé aux administrateurs.'
                  : 'Connectez-vous pour accéder à cette fonctionnalité.',
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
