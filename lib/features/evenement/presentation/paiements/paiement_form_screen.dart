import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/models/inscription.dart';
import '../../data/models/paiement_evenement.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../data/repositories/inscription_repository.dart';
import '../../data/repositories/paiement_evenement_repository.dart';
import '../../../../core/utils/outils.dart';

class PaiementFormScreen extends StatefulWidget {
  final PaiementEvenement? paiement;

  const PaiementFormScreen({
    super.key,
    this.paiement,
  });

  @override
  State<PaiementFormScreen> createState() => _PaiementFormScreenState();
}

class _PaiementFormScreenState extends State<PaiementFormScreen> {
  PaiementEvenementRepository paiementRepository =
  PaiementEvenementRepository();
  InscriptionRepository inscriptionRepository = InscriptionRepository();
  EvenementRepository evenementRepository = EvenementRepository();
  CategorieRepository categorieRepository = CategorieRepository();

  List<Inscription> inscriptions = [];
  List<Evenement> evenements = [];
  List<Categorie> categories = [];

  String idInscription = '';

  double montant = 0;

  MethodePaiement methode = MethodePaiement.carte;

  @override
  void initState() {
    super.initState();

    if (widget.paiement != null) {
      idInscription = widget.paiement!.idInscription;
      montant = widget.paiement!.montant;
      methode = widget.paiement!.methode;
    }

    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      List<Inscription> resultatInscriptions =
      await inscriptionRepository.getInscriptions();

      List<Evenement> resultatEvenements =
      await evenementRepository.getEvenements();

      List<Categorie> resultatCategories =
      await categorieRepository.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        inscriptions = resultatInscriptions;
        evenements = resultatEvenements;
        categories = resultatCategories;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  String nomEvenement(String idEvenement) {
    for (Evenement evenement in evenements) {
      if (evenement.idEvenement == idEvenement) {
        return evenement.nom;
      }
    }

    return 'Événement inconnu';
  }

  String nomCategorie(String idCategorie) {
    for (Categorie categorie in categories) {
      if (categorie.idCategorie == idCategorie) {
        return categorie.nom;
      }
    }

    return 'Catégorie inconnue';
  }

  double prixEvenement(String idEvenement) {
    for (Evenement evenement in evenements) {
      if (evenement.idEvenement == idEvenement) {
        return evenement.prix;
      }
    }

    return 0;
  }

  Future<void> choisirInscription(Inscription inscription) async {
    // Relation 1-1 : une inscription ne peut avoir qu'un seul paiement.
    if (widget.paiement == null) {
      try {
        bool existe = await paiementRepository.inscriptionDejaPayee(
          inscription.idInscription,
        );

        if (existe) {
          if (mounted) {
            afficherMessage(
              context,
              'Cette inscription possède déjà un paiement.',
            );
          }

          return;
        }
      } catch (erreur) {
        if (mounted) {
          afficherMessage(context, 'Vérification impossible : $erreur');
        }

        return;
      }
    }

    setState(() {
      idInscription = inscription.idInscription;
      montant = prixEvenement(inscription.idEvenement);
    });
  }

  String genererReference() {
    return 'PAY-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> enregistrer() async {
    if (idInscription.isEmpty) {
      afficherMessage(context, 'Choisissez une inscription.');
      return;
    }

    try {
      if (widget.paiement == null) {
        PaiementEvenement paiement = PaiementEvenement(
          idPaiement: '',
          idInscription: idInscription,
          montant: montant,
          datePaiement: DateTime.now(),
          methode: methode,
          // L'athlète ne choisit pas le statut.
          statut: StatutPaiement.enAttente,
          // Générée par l'application.
          reference: genererReference(),
        );

        await paiementRepository.ajouter(paiement);
      } else {
        // En modification, on garde la date, le statut et la référence.
        PaiementEvenement paiement = PaiementEvenement(
          idPaiement: widget.paiement!.idPaiement,
          idInscription: idInscription,
          montant: montant,
          datePaiement: widget.paiement!.datePaiement,
          methode: methode,
          statut: widget.paiement!.statut,
          reference: widget.paiement!.reference,
        );

        await paiementRepository.modifier(paiement);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Enregistrement impossible : $erreur');
      }
    }
  }

  Widget titreSection(String texte) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget choixInscription() {
    if (inscriptions.isEmpty) {
      return const Text('Aucune inscription : créez-en une d’abord.');
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        itemCount: inscriptions.length,
        itemBuilder: (context, index) {
          Inscription inscription = inscriptions[index];
          bool choisie = idInscription == inscription.idInscription;
          String nom = nomEvenement(inscription.idEvenement);

          return Card(
            color: choisie ? Colors.blue.shade50 : null,
            child: InkWell(
              onTap: () {
                choisirInscription(inscription);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      choisie ? '✓ $nom' : nom,
                      style: const TextStyle(fontSize: 17),
                    ),
                    Text(
                      'Catégorie : ${nomCategorie(inscription.idCategorie)}',
                    ),
                    Text('Athlète : ${inscription.idAthlete}'),
                    Text(
                      'Prix : '
                          '${prixEvenement(inscription.idEvenement).toStringAsFixed(2)} DT',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget carteMontant() {
    String texte = '-';

    if (idInscription.isNotEmpty) {
      texte = '${montant.toStringAsFixed(2)} DT';
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Montant à payer',
              style: TextStyle(fontSize: 17),
            ),
            Text(
              texte,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }

  // Choix de la méthode : GridView.builder (Chapitre 4).
  Widget choixMethode() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: MethodePaiement.values.length,
      itemBuilder: (context, index) {
        MethodePaiement valeur = MethodePaiement.values[index];
        String libelle = methodePaiementEnTexte(valeur);

        return ElevatedButton(
          onPressed: () {
            setState(() {
              methode = valeur;
            });
          },
          child: Text(methode == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paiement == null ? 'Paiement' : 'Modifier paiement',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            titreSection('Choisir une inscription'),
            choixInscription(),
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: carteMontant(),
            ),
            titreSection('Méthode de paiement'),
            choixMethode(),
            Container(
              margin: const EdgeInsets.only(top: 35, bottom: 20),
              child: ElevatedButton(
                onPressed: enregistrer,
                child: Text(widget.paiement == null ? 'Payer' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
