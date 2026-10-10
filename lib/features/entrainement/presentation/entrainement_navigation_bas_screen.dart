import 'package:flutter/material.dart';

import 'package:coach_app/core/utils/outils.dart';
import 'exploration_musculaire/body_screen.dart';
import 'programmes/programme_list_screen.dart';

class EntrainementNavigationBasScreen extends StatefulWidget {
  const EntrainementNavigationBasScreen({super.key});

  @override
  State<EntrainementNavigationBasScreen> createState() =>
      _EntrainementNavigationBasScreenState();
}

class _EntrainementNavigationBasScreenState
    extends State<EntrainementNavigationBasScreen> {
  int indexCourant = 0;

  List<String> titres = [
    'Exploration musculaire',
    'Programmes',
    // à ajouter : 'Séances'
  ];

  List<Widget> pages = [
    const BodyScreen(integre: true),
    const ProgrammeListScreen(integre: true),
    // à ajouter : const SeanceListScreen(integre: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titres[indexCourant]),
      ),
      drawer: construireDrawer(context),
      body: pages[indexCourant],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indexCourant,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            indexCourant = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: 'Corps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Programmes',
          ),
          // à ajouter :
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.event_available),
          //   label: 'Séances',
          // ),
        ],
      ),
    );
  }
}