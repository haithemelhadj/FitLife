import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'muscle_cible.dart';
import 'muscle_mapper/muscle_mapper.dart';

class BodyScreen extends StatefulWidget {
  // integre = true : affiché dans des onglets, sans Scaffold/AppBar.
  final bool integre;

  const BodyScreen({
    super.key,
    this.integre = false,
  });

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  AnatomyGender sexe = AnatomyGender.male;
  AnatomyView vue = AnatomyView.front;

  // Style "minimal" : le seul à avoir des SVG féminins.
  final AnatomyAssetProvider fournisseur =
  const DefaultAnatomyProvider(style: AnatomyStyle.minimal);

  MuscleGroup? groupeChoisi;

  void choisirMuscle(Muscle muscle) {
    setState(() {
      groupeChoisi = muscle.group;
    });
  }

  void voirExercices() {
    if (groupeChoisi == null) {
      return;
    }

    String cible = cibleExerciseDb(groupeChoisi!);

    // À remplacer à l'étape suivante par :
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => ExercicesListScreen(
    //     cible: cible, libelle: libelleGroupe(groupeChoisi!))));
    afficherMessage(context, 'Exercices ciblant : $cible');
  }

  Widget boutonChoix(String texte, bool choisi, VoidCallback action) {
    return ElevatedButton(
      onPressed: action,
      child: Text(choisi ? '✓ $texte' : texte),
    );
  }

  Widget barreChoix() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              boutonChoix('Homme', sexe == AnatomyGender.male, () {
                setState(() {
                  sexe = AnatomyGender.male;
                });
              }),
              Container(
                margin: const EdgeInsets.only(left: 10),
                child: boutonChoix('Femme', sexe == AnatomyGender.female, () {
                  setState(() {
                    sexe = AnatomyGender.female;
                  });
                }),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                boutonChoix('Face', vue == AnatomyView.front, () {
                  setState(() {
                    vue = AnatomyView.front;
                  });
                }),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: boutonChoix('Dos', vue == AnatomyView.back, () {
                    setState(() {
                      vue = AnatomyView.back;
                    });
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget carteSelection() {
    if (groupeChoisi == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Touchez un muscle sur le corps.'),
        ),
      );
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              libelleGroupe(groupeChoisi!),
              style: const TextStyle(fontSize: 20),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: voirExercices,
                child: const Text('Voir les exercices'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construireCorps() {
    // Tous les muscles du groupe touché sont mis en évidence.
    Set<Muscle> actifs = {};

    if (groupeChoisi != null) {
      actifs = groupeChoisi!.subMuscles;
    }

    return Column(
      children: [
        barreChoix(),
        Expanded(
          child: MuscleMapper(
            gender: sexe,
            view: vue,
            assetProvider: fournisseur,
            activeMuscles: actifs,
            onMuscleTapped: choisirMuscle,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          child: carteSelection(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return construireCorps();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exploration musculaire'),
      ),
      drawer: construireDrawer(context),
      body: construireCorps(),
    );
  }
}