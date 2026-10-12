import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';

class ProgrammeFormScreen extends StatefulWidget {
  final Programme? programme;

  const ProgrammeFormScreen({
    super.key,
    this.programme,
  });

  @override
  State<ProgrammeFormScreen> createState() => _ProgrammeFormScreenState();
}

class _ProgrammeFormScreenState extends State<ProgrammeFormScreen> {
  final formKey = GlobalKey<FormState>();

  ProgrammeRepository programmeRepository = ProgrammeRepository();

  String nom = '';
  String description = '';
  String dureeTexte = '';
  String dateDebutTexte = '';
  String dateFinTexte = '';

  ObjectifProgramme objectif = ObjectifProgramme.PERTE_POIDS;
  Niveau niveau = Niveau.DEBUTANT;

  @override
  void initState() {
    super.initState();

    if (widget.programme != null) {
      Programme programme = widget.programme!;

      nom = programme.nom;
      description = programme.description ?? '';
      dureeTexte = programme.dureeSemaines?.toString() ?? '';
      objectif = programme.objectif;
      niveau = programme.niveau;

      if (programme.dateDebut != null) {
        dateDebutTexte = afficherDate(programme.dateDebut!);
      }

      if (programme.dateFin != null) {
        dateFinTexte = afficherDate(programme.dateFin!);
      }
    }
  }

  String? validerNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nom obligatoire';
    }

    return null;
  }

  String? validerDuree(String? value) {
    int? duree = int.tryParse(value ?? '');

    if (duree == null || duree <= 0) {
      return 'Durée invalide';
    }

    return null;
  }

  // Les dates sont facultatives : vide = accepté.
  String? validerDateFacultative(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (lireDate(value) == null) {
      return 'Date invalide (jj/mm/aaaa)';
    }

    return null;
  }

  Future<void> enregistrer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Le coach est l'utilisateur connecté, il ne se saisit pas.
    User? utilisateur = Supabase.instance.client.auth.currentUser;

    if (utilisateur == null) {
      afficherMessage(context, 'Connectez-vous d’abord.');
      return;
    }

    DateTime? dateDebut = lireDate(dateDebutTexte);
    DateTime? dateFin = lireDate(dateFinTexte);

    if (dateDebut != null && dateFin != null && dateFin.isBefore(dateDebut)) {
      afficherMessage(
        context,
        'La date de fin doit être après la date de début',
      );
      return;
    }

    Programme programme = Programme(
      id: widget.programme?.id,
      nom: nom.trim(),
      description: description.trim(),
      objectif: objectif,
      niveau: niveau,
      dureeSemaines: int.parse(dureeTexte),
      dateDebut: dateDebut,
      dateFin: dateFin,
      idCoach: widget.programme?.idCoach ?? utilisateur.id,
    );

    try {
      if (widget.programme == null) {
        await programmeRepository.ajouter(programme);
      } else {
        await programmeRepository.modifier(programme);
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

  // Choix de l'objectif : GridView.builder (Chapitre 4).
  Widget choixObjectif() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ObjectifProgramme.values.length,
      itemBuilder: (context, index) {
        ObjectifProgramme valeur = ObjectifProgramme.values[index];
        String libelle = enTexte(valeur);

        return ElevatedButton(
          onPressed: () {
            setState(() {
              objectif = valeur;
            });
          },
          child: Text(objectif == valeur ? '✓ $libelle' : libelle),
        );
      },
    );
  }

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
      itemCount: Niveau.values.length,
      itemBuilder: (context, index) {
        Niveau valeur = Niveau.values[index];
        String libelle = enTexte(valeur);

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
          widget.programme == null ? 'Ajouter programme' : 'Modifier programme',
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
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (value) {
                  nom = value;
                },
                validator: validerNom,
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  description = value;
                },
              ),
              TextFormField(
                initialValue: dureeTexte,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée (semaines)',
                ),
                onChanged: (value) {
                  dureeTexte = value;
                },
                validator: validerDuree,
              ),
              titreSection('Objectif'),
              choixObjectif(),
              titreSection('Niveau'),
              choixNiveau(),
              titreSection('Dates (facultatif)'),
              TextFormField(
                initialValue: dateDebutTexte,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Date de début (jj/mm/aaaa)',
                ),
                onChanged: (value) {
                  dateDebutTexte = value;
                },
                validator: validerDateFacultative,
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
                validator: validerDateFacultative,
              ),
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
