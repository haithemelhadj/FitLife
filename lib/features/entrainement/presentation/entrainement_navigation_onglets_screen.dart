import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'exploration_musculaire/body_screen.dart';
import 'programmes/programme_list_screen.dart';

class EntrainementNavigationOngletsScreen extends StatelessWidget {
  const EntrainementNavigationOngletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // passe à 3 quand les séances sont prêtes
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entraînement'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Corps'),
              Tab(text: 'Programmes'),
              // à ajouter : Tab(text: 'Séances'),
            ],
          ),
        ),
        drawer: construireDrawer(context),
        body: const TabBarView(
          children: [
            BodyScreen(integre: true),
            ProgrammeListScreen(integre: true),
            // à ajouter : SeanceListScreen(integre: true),
          ],
        ),
      ),
    );
  }
}