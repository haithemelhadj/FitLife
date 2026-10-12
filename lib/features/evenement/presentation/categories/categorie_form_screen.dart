import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../data/models/categorie.dart';
import '../../data/models/evenement.dart';
import '../../data/repositories/categorie_repository.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../../../core/utils/outils.dart';

class CategorieFormScreen extends StatefulWidget {
  final Categorie? categorie;

  const CategorieFormScreen({
    super.key,
    this.categorie,
  });

  @override
  State<CategorieFormScreen> createState() => _CategorieFormScreenState();
}

class _CategorieFormScreenState extends State<CategorieFormScreen> {
  final formKey = GlobalKey<FormState>();

  CategorieRepository categorieRepository = CategorieRepository();
  EvenementRepository evenementRepository = EvenementRepository();

  List<Evenement> evenements = [];

  String nom = '';
  String ageMinTexte = '';
  String ageMaxTexte = '';
  String idEvenement = '';
  NiveauCategorie niveau = NiveauCategorie.debutant;

  @override
  void initState() {
    super.initState();

    if (widget.categorie != null) {
      Categorie categorie = widget.categorie!;

      nom = categorie.nom;
      ageMinTexte = categorie.ageMin.toString();
      ageMaxTexte = categorie.ageMax.toString();
      idEvenement = categorie.idEvenement;
      niveau = categorie.niveau;
    }

    chargerEvenements();
  }

  Future<void> chargerEvenements() async {
    try {
      List<Evenement> resultat = await evenementRepository.getEvenements();

      if (!mounted) {
        return;
      }

      setState(() {
        evenements = resultat;
      });
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  String? validerNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nom obligatoire';
    }

    return null;
  }

  String? validerAge(String? value) {
    int? age = int.tryParse(value ?? '');

    if (age == null || age < 0 || age > 120) {
      return 'Âge invalide';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (idEvenement.isEmpty) {
      afficherMessage(context, 'Choisissez un événement');
      return;
    }

    int ageMin = int.parse(ageMinTexte);
    int ageMax = int.parse(ageMaxTexte);

    if (ageMin > ageMax) {
      afficherMessage(context, 'L’âge minimum dépasse l’âge maximum');
      return;
    }

    Categorie categorie = Categorie(
      idCategorie: widget.categorie?.idCategorie ?? '',
      nom: nom.trim(),
      ageMin: ageMin,
      ageMax: ageMax,
      niveau: niveau,
      idEvenement: idEvenement,
    );

    try {
      if (widget.categorie == null) {
        await categorieRepository.ajouter(categorie);
      } else {
        await categorieRepository.modifier(categorie);
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

  // Liste des événements : ListView.builder (Chapitre 3) dans une zone
  // de hauteur fixe, chaque ligne est cliquable (InkWell, Chapitre 5).
  Widget choixEvenement() {
    if (evenements.isEmpty) {
      return const Text('Aucun événement : créez-en un d’abord.');
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: evenements.length,
        itemBuilder: (context, index) {
          Evenement evenement = evenements[index];
          bool choisi = idEvenement == evenement.idEvenement;

          return Card(
            color: choisi ? Colors.blue.shade50 : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  idEvenement = evenement.idEvenement;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(choisi ? '✓ ${evenement.nom}' : evenement.nom),
              ),
            ),
          );
        },
      ),
    );
  }

  // Choix du niveau : GridView.builder (Chapitre 4).
  Widget choixNiveau() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: NiveauCategorie.values.length,
      itemBuilder: (context, index) {
        NiveauCategorie valeur = NiveauCategorie.values[index];
        String libelle = valeur.name.toUpperCase();

        return ElevatedButton(
          onPressed: () {
            setState(() {
              niveau = valeur;
            });
          },
          child: Text(niveau == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categorie == null ? 'Ajouter catégorie' : 'Modifier catégorie',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            // Garde tous les champs construits (voir evenement_form_screen).
            scrollCacheExtent: ScrollCacheExtent.pixels(3000), padding: const EdgeInsets.only(bottom: 40),
            children: [
              TextFormField(
                initialValue: nom,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                ),
                onChanged: (value) {
                  nom = value;
                },
                validator: validerNom,
              ),
              TextFormField(
                initialValue: ageMinTexte,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Âge minimum'),
                onChanged: (value) {
                  ageMinTexte = value;
                },
                validator: validerAge,
              ),
              TextFormField(
                initialValue: ageMaxTexte,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Âge maximum'),
                onChanged: (value) {
                  ageMaxTexte = value;
                },
                validator: validerAge,
              ),
              titreSection('Choisir un événement'),
              choixEvenement(),
              titreSection('Niveau'),
              choixNiveau(),
              Container(
                margin: const EdgeInsets.only(top: 35, bottom: 20),
                child: ElevatedButton(
                  onPressed: enregistrer,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
