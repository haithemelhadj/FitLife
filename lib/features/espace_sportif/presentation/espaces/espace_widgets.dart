import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/enums.dart';

String libelleType(TypeEspace type) => switch (type) {
  TypeEspace.salle => 'Salle',
  TypeEspace.clubSportif => 'Club sportif',
  TypeEspace.stade => 'Stade',
  TypeEspace.terrain => 'Terrain',
  TypeEspace.parc => 'Parc',
  TypeEspace.centreSportif => 'Centre sportif',
  TypeEspace.piscine => 'Piscine',
  TypeEspace.autre => 'Autre',
};

String libelleStatut(StatutEspace statut) => switch (statut) {
  StatutEspace.actif => 'Actif',
  StatutEspace.inactif => 'Inactif',
  StatutEspace.enMaintenance => 'En maintenance',
};

String erreurEspace(Object erreur) {
  if (erreur is AuthException ||
      (erreur is PostgrestException &&
          ['42501', 'PGRST301', 'PGRST303'].contains(erreur.code))) {
    return 'Accès refusé. Vérifiez votre connexion et les droits de votre compte.';
  }
  if (erreur is PostgrestException && erreur.code == 'PGRST116') {
    return 'Cet espace est introuvable ou ne vous est plus accessible.';
  }
  return 'Opération impossible. Vérifiez votre connexion puis réessayez.';
}

class EtatEspace extends StatelessWidget {
  final String message;
  final VoidCallback? reessayer;
  const EtatEspace({super.key, required this.message, this.reessayer});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (reessayer != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: reessayer,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    ),
  );
}
