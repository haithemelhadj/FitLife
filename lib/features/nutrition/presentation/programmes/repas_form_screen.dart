import 'package:flutter/material.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/models/repas.dart';
import '../open_food_facts/aliment_search_screen.dart';

class RepasFormScreen extends StatefulWidget {
  final String idProgramme;
  final Repas? repasExistant;

  const RepasFormScreen({
    super.key,
    required this.idProgramme,
    this.repasExistant,
  });

  @override
  State<RepasFormScreen> createState() => _RepasFormScreenState();
}

class _RepasFormScreenState extends State<RepasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _heureController = TextEditingController(text: '12:00');

  TypeRepas _type = TypeRepas.DEJEUNER;
  List<AlimentRepas> _aliments = [];

  @override
  void initState() {
    super.initState();
    if (widget.repasExistant != null) {
      final r = widget.repasExistant!;
      _nomController.text = r.nom;
      _heureController.text = r.heureRecommandee ?? '12:00';
      _type = r.type;
      _aliments = List.from(r.aliments);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _heureController.dispose();
    super.dispose();
  }

  int get _totalCalories => _aliments.fold(0, (sum, a) => sum + a.calories);
  double get _totalProteines => _aliments.fold(0.0, (sum, a) => sum + a.proteines);
  double get _totalGlucides => _aliments.fold(0.0, (sum, a) => sum + a.glucides);
  double get _totalLipides => _aliments.fold(0.0, (sum, a) => sum + a.lipides);

  Future<void> _ouvrirRechercheOpenFoodFacts() async {
    final AlimentRepas? selection = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlimentSearchScreen()),
    );

    if (selection != null) {
      setState(() {
        _aliments.add(selection);
        if (_nomController.text.isEmpty) {
          _nomController.text = '${formatEnumNutrition(_type)} équilibré';
        }
      });
    }
  }

  void _ajouterAlimentManuel() {
    final nomCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final glucCtrl = TextEditingController();
    final lipCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajout manuel d\'un aliment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom de l\'aliment')),
              TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories (kcal)'), keyboardType: TextInputType.number),
              TextField(controller: protCtrl, decoration: const InputDecoration(labelText: 'Protéines (g)'), keyboardType: TextInputType.number),
              TextField(controller: glucCtrl, decoration: const InputDecoration(labelText: 'Glucides (g)'), keyboardType: TextInputType.number),
              TextField(controller: lipCtrl, decoration: const InputDecoration(labelText: 'Lipides (g)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nomCtrl.text.trim().isEmpty) return;
              setState(() {
                _aliments.add(AlimentRepas(
                  nom: nomCtrl.text.trim(),
                  calories: int.tryParse(calCtrl.text) ?? 0,
                  proteines: double.tryParse(protCtrl.text) ?? 0,
                  glucides: double.tryParse(glucCtrl.text) ?? 0,
                  lipides: double.tryParse(lipCtrl.text) ?? 0,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _validerRepas() {
    if (!_formKey.currentState!.validate()) return;

    final repas = Repas.depuisAliments(
      idRepas: widget.repasExistant?.idRepas ?? '',
      idProgramme: widget.idProgramme,
      nom: _nomController.text.trim(),
      type: _type,
      heureRecommandee: _heureController.text.trim(),
      aliments: _aliments,
    );

    Navigator.pop(context, repas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repasExistant == null ? 'Composer un Repas' : 'Modifier le Repas'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du repas (ex : Déjeuner poulet & patates douces)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TypeRepas>(
                      initialValue: _type,
                      items: TypeRepas.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(formatEnumNutrition(t)));
                      }).toList(),
                      onChanged: (val) => setState(() => _type = val ?? TypeRepas.DEJEUNER),
                      decoration: const InputDecoration(labelText: 'Type de repas', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _heureController,
                      decoration: const InputDecoration(
                        labelText: 'Heure (ex: 12:30)',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synthèse calorique et macros du repas
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroTotal('$_totalCalories kcal', 'Total Énergie', Colors.deepPurple),
                    _macroTotal('${_totalProteines.toStringAsFixed(1)}g', 'Protéines', Colors.blue),
                    _macroTotal('${_totalGlucides.toStringAsFixed(1)}g', 'Glucides', Colors.amber.shade900),
                    _macroTotal('${_totalLipides.toStringAsFixed(1)}g', 'Lipides', Colors.red.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Boutons d'ajout d'aliments
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _ouvrirRechercheOpenFoodFacts,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Open Food Facts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _ajouterAlimentManuel,
                    icon: const Icon(Icons.add),
                    label: const Text('Manuel'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Aliments du repas :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_aliments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Aucun aliment ajouté. Utilisez le scanner ou le catalogue.'),
                ),

              ..._aliments.asMap().entries.map((entry) {
                final idx = entry.key;
                final a = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(a.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${a.quantiteGrammes.round()}g • ${a.calories} kcal • P:${a.proteines}g G:${a.glucides}g L:${a.lipides}g'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _aliments.removeAt(idx)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _validerRepas,
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer ce repas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroTotal(String val, String lbl, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
        Text(lbl, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
