import 'package:flutter/material.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/models/programme_nutritionnel.dart';
import '../../data/models/repas.dart';
import '../../data/repositories/programme_nutri_repository.dart';
import '../../domain/nutrition_calculator.dart';
import 'repas_form_screen.dart';

class ProgrammeNutriFormScreen extends StatefulWidget {
  final String idDossier;
  final ProgrammeNutritionnel? programmeExistant;

  const ProgrammeNutriFormScreen({
    super.key,
    this.idDossier = 'demo-dossier-001',
    this.programmeExistant,
  });

  @override
  State<ProgrammeNutriFormScreen> createState() => _ProgrammeNutriFormScreenState();
}

class _ProgrammeNutriFormScreenState extends State<ProgrammeNutriFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProgrammeNutriRepository _repository = ProgrammeNutriRepository();

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController(text: '2000');
  final TextEditingController _proteinesController = TextEditingController(text: '150');
  final TextEditingController _glucidesController = TextEditingController(text: '200');
  final TextEditingController _lipidesController = TextEditingController(text: '65');
  final TextEditingController _budgetController = TextEditingController(text: '50');

  ObjectifNutrition _objectif = ObjectifNutrition.PERTE_POIDS;
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin = DateTime.now().add(const Duration(days: 30));
  List<Repas> _repas = [];

  @override
  void initState() {
    super.initState();
    if (widget.programmeExistant != null) {
      final p = widget.programmeExistant!;
      _titreController.text = p.titre;
      _descController.text = p.description ?? '';
      _caloriesController.text = p.caloriesCible.toString();
      _proteinesController.text = p.proteinesCibleG.toString();
      _glucidesController.text = p.glucidesCibleG.toString();
      _lipidesController.text = p.lipidesCibleG.toString();
      _budgetController.text = p.budgetMontant?.toString() ?? '50';
      _objectif = p.objectif;
      _dateDebut = p.dateDebut;
      _dateFin = p.dateFin;
      _chargerRepas(p.idProgramme);
    } else {
      _titreController.text = 'Plan Alimentaire Spécifique';
    }
  }

  Future<void> _chargerRepas(String idProgramme) async {
    final list = await _repository.getRepasDuProgramme(idProgramme);
    if (mounted) setState(() => _repas = list);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _caloriesController.dispose();
    _proteinesController.dispose();
    _glucidesController.dispose();
    _lipidesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _calculerMacrosAutomatiquement() {
    final cal = int.tryParse(_caloriesController.text) ?? 2000;
    final macros = NutritionCalculator.calculerRepartitionMacros(
      calories: cal,
      poidsKg: 80.0,
      objectif: _objectif,
    );

    setState(() {
      _proteinesController.text = macros['proteines']!.toString();
      _glucidesController.text = macros['glucides']!.toString();
      _lipidesController.text = macros['lipides']!.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Répartition calculée selon l\'objectif : ${formatEnumNutrition(_objectif)}')),
    );
  }

  Future<void> _ajouterRepas() async {
    final Repas? nouveauRepas = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepasFormScreen(
          idProgramme: widget.programmeExistant?.idProgramme ?? '',
        ),
      ),
    );

    if (nouveauRepas != null) {
      setState(() => _repas.add(nouveauRepas));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    final prog = ProgrammeNutritionnel(
      idProgramme: widget.programmeExistant?.idProgramme ?? '',
      idDossier: widget.idDossier,
      titre: _titreController.text.trim(),
      description: _descController.text.trim(),
      objectif: _objectif,
      caloriesCible: int.tryParse(_caloriesController.text) ?? 2000,
      proteinesCibleG: double.tryParse(_proteinesController.text) ?? 150.0,
      glucidesCibleG: double.tryParse(_glucidesController.text) ?? 200.0,
      lipidesCibleG: double.tryParse(_lipidesController.text) ?? 65.0,
      budgetMontant: double.tryParse(_budgetController.text),
      budgetDevise: 'EUR',
      dateDebut: _dateDebut,
      dateFin: _dateFin,
      statut: widget.programmeExistant?.statut ?? StatutProgramme.ACTIF,
    );

    try {
      if (widget.programmeExistant == null) {
        await _repository.creerProgramme(prog, repas: _repas);
      } else {
        await _repository.modifierProgramme(prog);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programme nutritionnel enregistré avec succès !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = int.tryParse(_caloriesController.text) ?? 0;
    final prot = double.tryParse(_proteinesController.text) ?? 0;
    final gluc = double.tryParse(_glucidesController.text) ?? 0;
    final lip = double.tryParse(_lipidesController.text) ?? 0;
    final totalCalMacros = (prot * 4) + (gluc * 4) + (lip * 9);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.programmeExistant == null ? 'Nouveau Programme Nutritionnel' : 'Modifier le Programme'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.deepPurple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.deepPurple, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Métier 2 : Le nutritionniste définit l\'objectif, les calories, la répartition des macronutriments et les repas.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre & Objectif
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'Titre du programme', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Titre obligatoire' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ObjectifNutrition>(
              initialValue: _objectif,
              items: ObjectifNutrition.values.map((o) {
                return DropdownMenuItem(value: o, child: Text(formatEnumNutrition(o)));
              }).toList(),
              onChanged: (val) => setState(() => _objectif = val ?? ObjectifNutrition.PERTE_POIDS),
              decoration: const InputDecoration(labelText: 'Objectif nutritionnel', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Calories & Bouton de suggestion
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories cibles (kcal/j)',
                      suffixText: 'kcal',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _calculerMacrosAutomatiquement,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Calculer'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Macronutriments
            const Text('Répartition des Macronutriments :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protéines', suffixText: 'g', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _glucidesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Glucides', suffixText: 'g', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lipidesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Lipides', suffixText: 'g', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total calculé via macros : ${totalCalMacros.round()} kcal (Écart cible : ${(totalCalMacros - cal).abs().round()} kcal)',
              style: TextStyle(fontSize: 12, color: (totalCalMacros - cal).abs() > 100 ? Colors.orange.shade800 : Colors.green),
            ),
            const SizedBox(height: 16),

            // Budget alimentaire (pour Frankfurter API)
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget alimentaire estimé (API Frankfurter)',
                prefixIcon: Icon(Icons.euro),
                suffixText: 'EUR',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Liste des repas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Repas du programme :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _ajouterRepas,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un repas'),
                ),
              ],
            ),
            if (_repas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucun repas configuré pour ce programme.', style: TextStyle(color: Colors.grey)),
              ),
            ..._repas.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu, color: Colors.deepPurple),
                  title: Text(r.nom),
                  subtitle: Text('${formatEnumNutrition(r.type)} • ${r.calories} kcal • P:${r.proteinesG}g'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _repas.removeAt(idx)),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enregistrer,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer le programme nutritionnel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
