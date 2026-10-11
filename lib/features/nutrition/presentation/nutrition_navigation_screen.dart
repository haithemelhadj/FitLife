import 'package:flutter/material.dart';
import 'consultations/consultation_list_screen.dart';
import 'programmes/programme_nutri_list_screen.dart';
import 'suivi/suivi_dashboard_screen.dart';

/// Écran principal de navigation pour la feature Nutrition & Suivi (Gestion 4).
/// Regroupe :
/// 1. Suivi & Coordination (Métier 3, Métier 4, API Frankfurter)
/// 2. Programmes & Repas (Métier 2, API Open Food Facts)
/// 3. Consultations (Métier 1)
class NutritionNavigationScreen extends StatefulWidget {
  final String idAthlete;

  const NutritionNavigationScreen({
    super.key,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<NutritionNavigationScreen> createState() => _NutritionNavigationScreenState();
}

class _NutritionNavigationScreenState extends State<NutritionNavigationScreen> {
  int _indexCourant = 0;

  final List<String> _titres = [
    'Suivi & Coordination',
    'Programmes Nutritionnels',
    'Consultations',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SuiviDashboardScreen(integre: true, idAthlete: widget.idAthlete),
      const ProgrammeNutriListScreen(integre: true),
      ConsultationListScreen(integre: true, idAthlete: widget.idAthlete),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titres[_indexCourant]),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: _pages[_indexCourant],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexCourant,
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _indexCourant = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Suivi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Programmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Consultations',
          ),
        ],
      ),
    );
  }
}
