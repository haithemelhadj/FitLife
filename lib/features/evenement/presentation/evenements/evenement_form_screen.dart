import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../data/models/evenement.dart';
import '../../data/repositories/evenement_repository.dart';
import '../../../../core/utils/outils.dart';

class EvenementFormScreen extends StatefulWidget {
  final Evenement? evenement;

  const EvenementFormScreen({
    super.key,
    this.evenement,
  });

  @override
  State<EvenementFormScreen> createState() => _EvenementFormScreenState();
}

class _EvenementFormScreenState extends State<EvenementFormScreen> {
  final formKey = GlobalKey<FormState>();

  EvenementRepository evenementRepository = EvenementRepository();

  // Valeurs du formulaire (mises à jour par onChanged).
  String nom = '';
  String description = '';
  String lieu = '';
  String capaciteTexte = '';
  String prixTexte = '';
  String dateDebutTexte = '';
  String dateFinTexte = '';
  String heureTexte = '';

  TypeEvenement type = TypeEvenement.marathon;
  StatutEvenement statut = StatutEvenement.brouillon;

  @override
  void initState() {
    super.initState();

    if (widget.evenement != null) {
      Evenement evenement = widget.evenement!;

      nom = evenement.nom;
      description = evenement.description;
      lieu = evenement.lieu;
      capaciteTexte = evenement.capacite.toString();
      prixTexte = evenement.prix.toString();
      dateDebutTexte = afficherDate(evenement.dateDebut);
      dateFinTexte = afficherDate(evenement.dateFin);
      heureTexte = evenement.heureDebut;
      type = evenement.type;
      statut = evenement.statut;
    }
  }

  String? validerObligatoire(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }

    return null;
  }

  String? validerCapacite(String? value) {
    int? capacite = int.tryParse(value ?? '');

    if (capacite == null || capacite <= 0) {
      return 'Capacité invalide';
    }

    return null;
  }

  String? validerPrix(String? value) {
    double? prix = double.tryParse((value ?? '').replaceAll(',', '.'));

    if (prix == null || prix < 0) {
      return 'Prix invalide';
    }

    return null;
  }

  String? validerDate(String? value) {
    if (lireDate(value ?? '') == null) {
      return 'Date invalide (jj/mm/aaaa)';
    }

    return null;
  }

  String? validerHeure(String? value) {
    if (lireHeure(value ?? '') == null) {
      return 'Heure invalide (hh:mm)';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    DateTime? dateDebut = lireDate(dateDebutTexte);
    DateTime? dateFin = lireDate(dateFinTexte);
    String? heure = lireHeure(heureTexte);

    if (dateDebut == null || dateFin == null || heure == null) {
      afficherMessage(context, 'Dates ou heure invalides');
      return;
    }

    if (dateFin.isBefore(dateDebut)) {
      afficherMessage(
        context,
        'La date de fin doit être après la date de début',
      );
      return;
    }

    Evenement evenement = Evenement(
      idEvenement: widget.evenement?.idEvenement ?? '',
      nom: nom.trim(),
      description: description.trim(),
      type: type,
      dateDebut: dateDebut,
      dateFin: dateFin,
      heureDebut: heure,
      lieu: lieu.trim(),
      capacite: int.parse(capaciteTexte),
      prix: double.parse(prixTexte.replaceAll(',', '.')),
      statut: statut,
    );

    try {
      if (widget.evenement == null) {
        await evenementRepository.ajouter(evenement);
      } else {
        await evenementRepository.modifier(evenement);
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

  // Choix du type : GridView.builder (Chapitre 4).
  Widget choixType() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: TypeEvenement.values.length,
      itemBuilder: (context, index) {
        TypeEvenement valeur = TypeEvenement.values[index];
        String libelle = valeur.name.toUpperCase();

        return ElevatedButton(
          onPressed: () {
            setState(() {
              type = valeur;
            });
          },
          child: Text(type == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  Widget choixStatut() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: StatutEvenement.values.length,
      itemBuilder: (context, index) {
        StatutEvenement valeur = StatutEvenement.values[index];
        String libelle = valeur.name.toUpperCase();

        return ElevatedButton(
          onPressed: () {
            setState(() {
              statut = valeur;
            });
          },
          child: Text(statut == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.evenement == null ? 'Ajouter événement' : 'Modifier événement',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            // Garde tous les champs construits : sans cela, un TextFormField
            // sorti de l'écran serait détruit et ne serait plus validé.
            scrollCacheExtent: ScrollCacheExtent.pixels(3000), padding: const EdgeInsets.only(bottom: 40),
            children: [
              TextFormField(
                initialValue: nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (value) {
                  nom = value;
                },
                validator: validerObligatoire,
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  description = value;
                },
              ),
              TextFormField(
                initialValue: lieu,
                decoration: const InputDecoration(labelText: 'Lieu'),
                onChanged: (value) {
                  lieu = value;
                },
                validator: validerObligatoire,
              ),
              TextFormField(
                initialValue: capaciteTexte,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacité'),
                onChanged: (value) {
                  capaciteTexte = value;
                },
                validator: validerCapacite,
              ),
              TextFormField(
                initialValue: prixTexte,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Prix (DT)'),
                onChanged: (value) {
                  prixTexte = value;
                },
                validator: validerPrix,
              ),
              titreSection('Type de l’événement'),
              choixType(),
              titreSection('Date et heure'),
              TextFormField(
                initialValue: dateDebutTexte,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Date de début (jj/mm/aaaa)',
                ),
                onChanged: (value) {
                  dateDebutTexte = value;
                },
                validator: validerDate,
              ),
              TextFormField(
                initialValue: dateFinTexte,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Date de fin (jj/mm/aaaa)',
                ),
                onChanged: (value) {
                  dateFinTexte = value;
                },
                validator: validerDate,
              ),
              TextFormField(
                initialValue: heureTexte,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Heure de début (hh:mm)',
                ),
                onChanged: (value) {
                  heureTexte = value;
                },
                validator: validerHeure,
              ),
              titreSection('Statut'),
              choixStatut(),
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
