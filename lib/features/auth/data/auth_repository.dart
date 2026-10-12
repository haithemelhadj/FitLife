import 'package:supabase_flutter/supabase_flutter.dart';

import '../../espace_sportif/data/models/enums.dart';

class AuthRepository {
  final SupabaseClient client;
  AuthRepository(this.client);
  bool get connecte => client.auth.currentSession != null;
  Stream<AuthState> get changements => client.auth.onAuthStateChange;

  Future<void> connecter(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<RoleEspace?> roleActif() async {
    if (!connecte || client.auth.currentUser?.isAnonymous == true) return null;
    final contexte = await client.rpc('contexte_espaces');
    final code = (contexte as Map)['role'] as String?;
    return code == null ? null : RoleEspace.depuisCode(code);
  }

  Future<void> deconnecter() => client.auth.signOut(scope: SignOutScope.local);
}
