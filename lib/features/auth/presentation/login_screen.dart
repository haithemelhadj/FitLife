import 'package:flutter/material.dart';

import '../domain/session_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formulaire = GlobalKey<FormState>();
  final identifiant = TextEditingController();
  final password = TextEditingController();
  bool admin = false;
  bool masquer = true;
  @override
  void dispose() {
    identifiant.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> connecter() async {
    if (!formulaire.currentState!.validate()) return;
    await SessionScope.of(context)
        .connecter(identifiant.text, password.text, admin: admin);
    if (mounted) password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion FitLife')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: formulaire,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.sports_handball, size: 64),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Utilisateur'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Administrateur'),
                        icon: Icon(Icons.admin_panel_settings),
                      ),
                    ],
                    selected: {admin},
                    onSelectionChanged: session.occupe
                        ? null
                        : (selection) {
                            setState(() {
                              admin = selection.single;
                              identifiant.clear();
                              password.clear();
                              formulaire.currentState?.reset();
                            });
                          },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: identifiant,
                    enabled: !session.occupe,
                    decoration: InputDecoration(
                      labelText: admin ? 'Nom administrateur' : 'Email',
                      helperText: admin ? 'Identifiant : admin' : null,
                    ),
                    keyboardType: admin
                        ? TextInputType.text
                        : TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: admin ? null : const [AutofillHints.email],
                    validator: (valeur) {
                      final texte = (valeur ?? '').trim();
                      if (texte.isEmpty) return 'Ce champ est obligatoire.';
                      if (!admin &&
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(texte)) {
                        return 'Email invalide.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    enabled: !session.occupe,
                    obscureText: masquer,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      suffixIcon: IconButton(
                        tooltip: masquer
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        onPressed: () => setState(() {
                          masquer = !masquer;
                        }),
                        icon: Icon(
                          masquer ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (valeur) => valeur == null || valeur.isEmpty
                        ? 'Ce champ est obligatoire.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!session.occupe) connecter();
                    },
                  ),
                  if (session.erreur != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        session.erreur!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: session.occupe ? null : connecter,
                    child: Text(session.occupe ? 'Connexion…' : 'Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: session.occupe ? null : session.entrerInvite,
                    child: const Text('Continuer comme invité'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les invités peuvent consulter les espaces publics. Connectez-vous pour utiliser les actions de votre compte.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
