import 'package:flutter/material.dart';

import 'features/evenement/data/models/evenement.dart';
import 'features/evenement/data/models/categorie.dart';
import 'features/evenement/data/models/inscription.dart';
import 'features/evenement/data/models/paiement_evenement.dart';

import 'features/evenement/data/repositories/evenement_repository.dart';
import 'features/evenement/data/repositories/categorie_repository.dart';
import 'features/evenement/data/repositories/inscription_repository.dart';
import 'features/evenement/data/repositories/paiement_evenement_repository.dart';

import 'core/utils/outils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();
  InscriptionRepository inscriptionRepository = InscriptionRepository();

  PaiementEvenementRepository paiementRepository =
  PaiementEvenementRepository();

  List<Evenement> evenements = [];
  List<Categorie> categories = [];
  List<Inscription> inscriptions = [];
  List<PaiementEvenement> paiements = [];

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      List<Evenement> resultatEvenements =
      await evenementRepository.getEvenements();

      List<Categorie> resultatCategories =
      await categorieRepository.getCategories();

      List<Inscription> resultatInscriptions =
      await inscriptionRepository.getInscriptions();

      List<PaiementEvenement> resultatPaiements =
      await paiementRepository.getPaiements();

      if (!mounted) {
        return;
      }

      setState(() {
        evenements = resultatEvenements;
        categories = resultatCategories;
        inscriptions = resultatInscriptions;
        paiements = resultatPaiements;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  // Carte de résumé : affiche le nombre d'éléments.
  Widget carteResume(
      String titre,
      int nombre,
      IconData icone,
      ) {
    return Card(
      color: Colors.deepPurple.shade50,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icone,
              color: Colors.deepPurple,
              size: 30,
            ),
            Text(
              '$nombre',
              style: const TextStyle(
                fontSize: 26,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              titre,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Titre d'une section.
  Widget titreSection(String titre) {
    return Container(
      margin: const EdgeInsets.only(
        top: 24,
        bottom: 10,
      ),
      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FitLife',
        ),
        backgroundColor: Colors.deepPurple.shade50,
      ),

      drawer: construireDrawer(context),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MESSAGE DE BIENVENUE
          Card(
            color: Colors.deepPurple,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 50,
                  ),
                  Text(
                    'Bienvenue !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                  Text(
                    'Plateforme de gestion des événements sportifs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          titreSection('Tableau de bord'),

          // RÉSUMÉ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              carteResume(
                'Événements',
                evenements.length,
                Icons.event,
              ),
              carteResume(
                'Catégories',
                categories.length,
                Icons.category,
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              carteResume(
                'Inscriptions',
                inscriptions.length,
                Icons.how_to_reg,
              ),
              carteResume(
                'Paiements',
                paiements.length,
                Icons.payment,
              ),
            ],
          ),

          titreSection('Événements sportifs'),

          if (evenements.isEmpty)
            const Text(
              'Aucun événement disponible.',
            ),

          for (Evenement evenement in evenements)
            Card(
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      evenement.nom,
                      style: const TextStyle(
                        fontSize: 19,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Lieu : ${evenement.lieu}',
                    ),
                    Text(
                      'Date : ${afficherDate(evenement.dateDebut)}',
                    ),
                    Text(
                      'Prix : ${evenement.prix.toStringAsFixed(2)} DT',
                    ),
                    Text(
                      'Statut : ${evenement.statut.name.toUpperCase()}',
                    ),
                  ],
                ),
              ),
            ),

          titreSection('Catégories'),

          if (categories.isEmpty)
            const Text(
              'Aucune catégorie disponible.',
            ),

          for (Categorie categorie in categories)
            Card(
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      categorie.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Âge : ${categorie.ageMin} - ${categorie.ageMax}',
                    ),
                    Text(
                      'Niveau : ${categorie.niveau.name.toUpperCase()}',
                    ),
                  ],
                ),
              ),
            ),

          titreSection('Inscriptions'),

          if (inscriptions.isEmpty)
            const Text(
              'Aucune inscription disponible.',
            ),

          for (Inscription inscription in inscriptions)
            Card(
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      'Athlète : ${inscription.idAthlete}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Date : ${afficherDate(inscription.dateInscription)}',
                    ),
                    Text(
                      'Statut : ${inscription.statutToString()}',
                    ),
                  ],
                ),
              ),
            ),

          titreSection('Paiements'),

          if (paiements.isEmpty)
            const Text(
              'Aucun paiement disponible.',
            ),

          for (PaiementEvenement paiement in paiements)
            Card(
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      '${paiement.montant.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Méthode : ${paiement.methodeToString()}',
                    ),
                    Text(
                      'Statut : ${paiement.statutToString()}',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
