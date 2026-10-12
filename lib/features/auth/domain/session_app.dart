import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../espace_sportif/data/models/enums.dart';
import '../data/auth_repository.dart';

enum ModeSession { chargement, deconnecte, utilisateur }

class SessionApp extends ChangeNotifier {
  final AuthRepository repository;
  final String emailAdmin;
  ModeSession mode = ModeSession.chargement;
  RoleEspace? role;
  String? erreur;
  bool occupe = false;
  bool ferme = false;
  int revision = 0;
  StreamSubscription<AuthState>? abonnement;

  SessionApp(this.repository, {this.emailAdmin = 'haithemelhadj42@gmail.com'});
  bool get administrateur =>
      mode == ModeSession.utilisateur && role == RoleEspace.admin;

  Future<void> initialiser() async {
    abonnement = repository.changements.listen(
      (_) {
        if (!occupe) actualiser();
      },
      onError: (Object e) {
        revision++;
        role = null;
        mode = ModeSession.deconnecte;
        erreur = 'Connexion interrompue. Veuillez vous reconnecter.';
        publier();
      },
    );
    await actualiser();
  }

  void publier() {
    if (!ferme) notifyListeners();
  }

  Future<void> actualiser() async {
    final numero = ++revision;
    try {
      final valeur = await repository.roleActif();
      if (ferme || numero != revision) return;
      role = valeur;
      mode = valeur == null ? ModeSession.deconnecte : ModeSession.utilisateur;
    } catch (_) {
      if (ferme || numero != revision) return;
      role = null;
      mode = ModeSession.deconnecte;
      erreur = 'Impossible de vérifier votre compte. Réessayez.';
    }
    publier();
  }

  Future<bool> connecter(
    String identifiant,
    String password, {
    bool admin = false,
  }) async {
    if (occupe) return false;
    occupe = true;
    erreur = null;
    role = null;
    revision++;
    publier();
    try {
      if (admin && identifiant.trim() != 'admin') {
        throw const AuthException('Identifiant incorrect.');
      }
      await repository.connecter(admin ? emailAdmin : identifiant, password);
      final valeur = await repository.roleActif();
      if (valeur == null || (admin && valeur != RoleEspace.admin)) {
        await repository.deconnecter();
        erreur = admin
            ? 'Ce compte ne possède pas les droits administrateur.'
            : 'Votre compte est indisponible.';
        mode = ModeSession.deconnecte;
        return false;
      }
      role = valeur;
      mode = ModeSession.utilisateur;
      return true;
    } catch (_) {
      role = null;
      mode = ModeSession.deconnecte;
      erreur =
          'Connexion impossible. Vérifiez vos identifiants et votre connexion.';
      return false;
    } finally {
      occupe = false;
      publier();
    }
  }

  Future<void> quitter() async {
    if (occupe) return;
    occupe = true;
    erreur = null;
    revision++;
    role = null;
    mode = ModeSession.deconnecte;
    publier();
    try {
      await repository.deconnecter();
    } catch (_) {
      erreur = 'Déconnexion locale impossible. Réessayez avant de changer de compte.';
    } finally {
      occupe = false;
      publier();
    }
  }

  @override
  void dispose() {
    ferme = true;
    revision++;
    abonnement?.cancel();
    super.dispose();
  }
}

class SessionScope extends InheritedNotifier<SessionApp> {
  const SessionScope({
    super.key,
    required SessionApp session,
    required super.child,
  }) : super(notifier: session);
  static SessionApp? peutEtre(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
  static SessionApp of(BuildContext context) => peutEtre(context)!;
}
