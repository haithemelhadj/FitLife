import 'package:flutter/material.dart';

// Afficher un message en bas de l'écran.
void afficherMessage(BuildContext context, String texte) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(texte),
    ),
  );
}

// Convertir "26/09/2026" en DateTime.
DateTime? lireDate(String texte) {
  List<String> parties = texte.trim().split('/');

  if (parties.length != 3) {
    return null;
  }

  int? jour = int.tryParse(parties[0]);
  int? mois = int.tryParse(parties[1]);
  int? annee = int.tryParse(parties[2]);

  if (jour == null || mois == null || annee == null) {
    return null;
  }

  if (annee < 2000 || annee > 2100) {
    return null;
  }

  DateTime date = DateTime(annee, mois, jour);

  if (date.day != jour ||
      date.month != mois ||
      date.year != annee) {
    return null;
  }

  return date;
}

// Convertir DateTime en "26/09/2026".
String afficherDate(DateTime date) {
  String jour = date.day.toString().padLeft(2, '0');
  String mois = date.month.toString().padLeft(2, '0');

  return '$jour/$mois/${date.year}';
}

// Convertir "8:5" en "08:05".
String? lireHeure(String texte) {
  List<String> parties = texte.trim().split(':');

  if (parties.length != 2) {
    return null;
  }

  int? heure = int.tryParse(parties[0]);
  int? minute = int.tryParse(parties[1]);

  if (heure == null || minute == null) {
    return null;
  }

  if (heure < 0 ||
      heure > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }

  return '${heure.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

// Élément cliquable du Drawer.
// Chapitre 5 : InkWell + Navigator.pushReplacementNamed.
Widget elementMenu(
    BuildContext context,
    String titre,
    IconData icone,
    String route,
    ) {
  return InkWell(
    onTap: () {
      Navigator.pop(context);

      Navigator.pushReplacementNamed(
        context,
        route,
      );
    },

    child: Container(
      padding: const EdgeInsets.all(14),

      child: Row(
        children: [
          Icon(
            icone,
            color: Colors.deepPurple,
          ),

          // Expanded : le texte passe à la ligne au lieu de déborder.
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 14),

              child: Text(
                titre,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Drawer commun à tous les écrans.
// Chapitre 5 : Drawer.
Widget construireDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: const EdgeInsets.all(12),

      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.deepPurple,

          child: const Column(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 48,
                color: Colors.white,
              ),

              Text(
                'FITLIFE',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),

              Text(
                'Coaching sportif',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // ACCUEIL EN PREMIER
        Container(
          margin: const EdgeInsets.only(top: 15),

          child: Card(
            child: elementMenu(
              context,
              'Accueil',
              Icons.home,
              '/',
            ),
          ),
        ),

        // BLOC GESTION
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),

          child: const Text(
            'GESTION',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Événements',
                Icons.event,
                '/evenements',
              ),

              elementMenu(
                context,
                'Catégories',
                Icons.category,
                '/categories',
              ),

              elementMenu(
                context,
                'Inscriptions',
                Icons.how_to_reg,
                '/inscriptions',
              ),

              elementMenu(
                context,
                'Paiements',
                Icons.payment,
                '/paiements',
              ),
            ],
          ),
        ),

        // BLOC ENTRAÎNEMENT
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),

          child: const Text(
            'ENTRAÎNEMENT',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Exploration musculaire',
                Icons.accessibility_new,
                '/corps',
              ),

              elementMenu(
                context,
                'Programmes',
                Icons.fitness_center,
                '/programmes',
              ),

              elementMenu(
                context,
                'Entraînement (bas)',
                Icons.vertical_align_bottom,
                '/entrainement-bas',
              ),

              elementMenu(
                context,
                'Entraînement (haut)',
                Icons.tab,
                '/entrainement-onglets',
              ),
            ],
          ),
        ),

        // BLOC NAVIGATION
        Container(
          margin: const EdgeInsets.only(
            top: 20,
            bottom: 8,
          ),

          child: const Text(
            'NAVIGATION',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
            ),
          ),
        ),

        Card(
          child: Column(
            children: [
              elementMenu(
                context,
                'Navigation en haut',
                Icons.tab,
                '/onglets',
              ),

              elementMenu(
                context,
                'Navigation en bas',
                Icons.vertical_align_bottom,
                '/bas',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}