import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'package:coach_app/features/entrainement/data/models/enums.dart';
import 'package:coach_app/features/entrainement/data/models/programme.dart';
import 'package:coach_app/features/entrainement/data/repositories/programme_repository.dart';
import 'programme_form_screen.dart';

class ProgrammeListScreen extends StatefulWidget {
  // integre = true : affiché dans un TabBarView ou sous un
  // BottomNavigationBar, donc sans son propre Scaffold/AppBar.
  final bool integre;

  const ProgrammeListScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<ProgrammeListScreen> createState() => _ProgrammeListScreenState();
}

class _ProgrammeListScreenState extends State<ProgrammeListScreen> {
  ProgrammeRepository programmeRepository = ProgrammeRepository();

  List<Programme> programmes = [];
  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerProgrammes();
  }

  Future<void> chargerProgrammes() async {
    try {
      List<Programme> resultat =
      await programmeRepository.getProgrammesDuCoach();

      if (!mounted) {
        return;
      }

      setState(() {
        programmes = resultat;
        chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          chargement = false;
        });

        afficherMessage(context, 'Erreur de chargement : $erreur');
      }
    }
  }

  Future<void> supprimer(int id) async {
    try {
      await programmeRepository.supprimer(id);
      await chargerProgrammes();
    } catch (erreur) {
      if (mounted) {
        afficherMessage(context, 'Suppression impossible : $erreur');
      }
    }
  }

  // Demande de confirmation avant de supprimer.
  Future<void> confirmerSuppression(Programme programme) async {
    bool? confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: Text('Supprimer le programme "${programme.nom}" ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirme == true) {
      supprimer(programme.id!);
    }
  }

  Future<void> ouvrirFormulaire(Programme? programme) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgrammeFormScreen(programme: programme),
      ),
    );

    chargerProgrammes();
  }

  Widget construireListe() {
    if (chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 : la première ligne est le bouton "Ajouter".
      itemCount: programmes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ouvrirFormulaire(null);
                  },
                  child: const Text('Ajouter un programme'),
                ),
                if (programmes.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: const Text('Aucun programme pour le moment.'),
                  ),
              ],
            ),
          );
        }

        Programme programme = programmes[index - 1];

        return Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    programme.nom,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                if (programme.description != null &&
                    programme.description!.isNotEmpty)
                  Text(programme.description!),
                Text('Objectif : ${enTexte(programme.objectif)}'),
                Text('Niveau : ${enTexte(programme.niveau)}'),
                if (programme.dureeSemaines != null)
                  Text('Durée : ${programme.dureeSemaines} semaines'),
                if (programme.dateDebut != null)
                  Text('Début : ${afficherDate(programme.dateDebut!)}'),
                if (programme.dateFin != null)
                  Text('Fin : ${afficherDate(programme.dateFin!)}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ouvrirFormulaire(programme);
                        },
                        child: const Text('Modifier'),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            confirmerSuppression(programme);
                          },
                          child: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireListe();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmes'),
      ),
      drawer: construireDrawer(context),
      body: construireListe(),
    );
  }
}