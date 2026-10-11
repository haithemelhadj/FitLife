import 'package:flutter/material.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/models/programme_nutritionnel.dart';
import '../../data/models/repas.dart';
import '../../data/repositories/programme_nutri_repository.dart';
import '../../data/services/frankfurter_service.dart';
import 'programme_nutri_form_screen.dart';

class ProgrammeNutriListScreen extends StatefulWidget {
  final bool integre;
  final String idDossier;

  const ProgrammeNutriListScreen({
    super.key,
    this.integre = false,
    this.idDossier = 'demo-dossier-001',
  });

  @override
  State<ProgrammeNutriListScreen> createState() => _ProgrammeNutriListScreenState();
}

class _ProgrammeNutriListScreenState extends State<ProgrammeNutriListScreen> {
  final ProgrammeNutriRepository _repository = ProgrammeNutriRepository();
  final FrankfurterService _frankfurter = FrankfurterService();

  List<ProgrammeNutritionnel> _programmes = [];
  Map<String, List<Repas>> _repasParProgramme = {};
  Map<String, double> _budgetEnTnd = {};
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await _repository.getProgrammesDuDossier(widget.idDossier);

    Map<String, List<Repas>> mapRepas = {};
    Map<String, double> mapTnd = {};

    for (final p in liste) {
      final repas = await _repository.getRepasDuProgramme(p.idProgramme);
      mapRepas[p.idProgramme] = repas;

      if (p.budgetMontant != null && p.budgetMontant! > 0) {
        final conv = await _frankfurter.convertir(p.budgetMontant!, de: p.budgetDevise, vers: 'TND');
        mapTnd[p.idProgramme] = conv;
      }
    }

    if (mounted) {
      setState(() {
        _programmes = liste;
        _repasParProgramme = mapRepas;
        _budgetEnTnd = mapTnd;
        _chargement = false;
      });
    }
  }

  Color _couleurStatut(StatutProgramme st) {
    switch (st) {
      case StatutProgramme.ACTIF:
        return Colors.green;
      case StatutProgramme.TERMINE:
        return Colors.blue;
      case StatutProgramme.SUSPENDU:
        return Colors.orange;
      case StatutProgramme.ANNULE:
        return Colors.red;
    }
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _programmes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgrammeNutriFormScreen(idDossier: widget.idDossier),
                  ),
                );
                if (res == true) _charger();
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un programme nutritionnel (Métier 2)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          );
        }

        final p = _programmes[index - 1];
        final repasDuProg = _repasParProgramme[p.idProgramme] ?? [];
        final couleur = _couleurStatut(p.statut);
        final budgetTnd = _budgetEnTnd[p.idProgramme];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du programme
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.titre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: couleur),
                      ),
                      child: Text(
                        formatEnumNutrition(p.statut),
                        style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(p.description!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
                const SizedBox(height: 12),

                // Badge Objectif & Calories
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.flag, size: 16, color: Colors.white),
                      label: Text(formatEnumNutrition(p.objectif), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.local_fire_department, size: 16, color: Colors.deepOrange),
                      label: Text('${p.caloriesCible} kcal/j', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Répartition Macronutriments
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Macronutriments prescrits :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _badgeMacro('${p.proteinesCibleG}g', 'Protéines', Colors.blue, '${p.pourcentageProteines.round()}%'),
                          _badgeMacro('${p.glucidesCibleG}g', 'Glucides', Colors.amber.shade900, '${p.pourcentageGlucides.round()}%'),
                          _badgeMacro('${p.lipidesCibleG}g', 'Lipides', Colors.red.shade400, '${p.pourcentageLipides.round()}%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Budget alimentaire & API Frankfurter
                if (p.budgetMontant != null && p.budgetMontant! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_exchange, color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Budget : ${p.budgetMontant} ${p.budgetDevise}${budgetTnd != null ? ' ≈ ${budgetTnd.toStringAsFixed(2)} TND (API Frankfurter)' : ''}',
                            style: TextStyle(color: Colors.teal.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Repas planifiés
                Text('Repas planifiés (${repasDuProg.length}) :', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                if (repasDuProg.isEmpty)
                  const Text('Aucun repas configuré pour ce programme.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ...repasDuProg.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${r.nom} (${r.heureRecommandee ?? ''})', style: const TextStyle(fontSize: 13)),
                        Text('${r.calories} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProgrammeNutriFormScreen(
                              idDossier: widget.idDossier,
                              programmeExistant: p,
                            ),
                          ),
                        );
                        if (res == true) _charger();
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    if (p.estActif)
                      ElevatedButton(
                        onPressed: () async {
                          await _repository.changerStatut(p.idProgramme, StatutProgramme.TERMINE);
                          _charger();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                        child: const Text('Terminer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badgeMacro(String val, String lbl, Color col, String pct) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 15)),
        Text(lbl, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(pct, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.integre) return _construireCorps();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmes Nutritionnels'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: _construireCorps(),
    );
  }
}
