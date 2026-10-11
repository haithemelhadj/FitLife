import 'package:flutter/material.dart';
import '../../data/models/aliment_info.dart';
import '../../data/services/open_food_facts_service.dart';

class AlimentSearchScreen extends StatefulWidget {
  const AlimentSearchScreen({super.key});

  @override
  State<AlimentSearchScreen> createState() => _AlimentSearchScreenState();
}

class _AlimentSearchScreenState extends State<AlimentSearchScreen> {
  final OpenFoodFactsService _offService = OpenFoodFactsService();
  final TextEditingController _rechercheController = TextEditingController();
  final TextEditingController _codeBarresController = TextEditingController();

  List<AlimentInfo> _resultats = [];
  bool _enChargement = false;
  String? _messageErreur;

  @override
  void dispose() {
    _rechercheController.dispose();
    _codeBarresController.dispose();
    super.dispose();
  }

  Future<void> _lancerRecherche() async {
    final query = _rechercheController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _enChargement = true;
      _messageErreur = null;
    });

    try {
      final produits = await _offService.rechercherAliments(query);
      if (mounted) {
        setState(() {
          _resultats = produits;
          _enChargement = false;
          if (produits.isEmpty) {
            _messageErreur = 'Aucun aliment trouvé pour "$query".';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enChargement = false;
          _messageErreur = 'Erreur lors de la recherche : $e';
        });
      }
    }
  }

  Future<void> _rechercherParCodeBarres() async {
    final code = _codeBarresController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _enChargement = true;
      _messageErreur = null;
    });

    try {
      final produit = await _offService.getAlimentParCodeBarres(code);
      if (mounted) {
        setState(() {
          _enChargement = false;
          if (produit != null) {
            _resultats = [produit];
          } else {
            _messageErreur = 'Code-barres inconnu : $code';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enChargement = false;
          _messageErreur = 'Erreur lors de la lecture du code-barres : $e';
        });
      }
    }
  }

  void _selectionnerAliment(AlimentInfo aliment) {
    double quantite = 100.0;
    final qteController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final portion = aliment.versAlimentRepas(quantite);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aliment.nom,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (aliment.marque != null)
                    Text('Marque : ${aliment.marque}', style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 24),

                  const Text('Définir la quantité (en grammes) :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: 'g',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 100.0;
                            setModalState(() => quantite = parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 6,
                        children: [50, 100, 150, 200].map((q) {
                          return ActionChip(
                            label: Text('${q}g'),
                            onPressed: () {
                              qteController.text = q.toString();
                              setModalState(() => quantite = q.toDouble());
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Résumé nutritionnel de la portion
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoNutri('${portion.calories} kcal', 'Énergie', Colors.deepPurple),
                        _infoNutri('${portion.proteines}g', 'Protéines', Colors.blue),
                        _infoNutri('${portion.glucides}g', 'Glucides', Colors.amber.shade800),
                        _infoNutri('${portion.lipides}g', 'Lipides', Colors.red.shade400),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, portion);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Valider et ajouter au repas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoNutri(String valeur, String libelle, Color couleur) {
    return Column(
      children: [
        Text(valeur, style: TextStyle(fontWeight: FontWeight.bold, color: couleur, fontSize: 15)),
        Text(libelle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _couleurNutriscore(String? score) {
    switch (score) {
      case 'A':
        return Colors.green.shade800;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.amber;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Food Facts (API 1)'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Onglets / Barre de recherche
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _rechercheController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un aliment (ex : avoine, poulet...)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _lancerRecherche,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _lancerRecherche(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeBarresController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Code-barres (ex: 3017620422003)',
                              prefixIcon: const Icon(Icons.qr_code_scanner),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            onSubmitted: (_) => _rechercherParCodeBarres(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _rechercherParCodeBarres,
                          child: const Text('Scanner'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_enChargement)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),

            if (_messageErreur != null && !_enChargement)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(_messageErreur!, style: const TextStyle(color: Colors.red)),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: _resultats.length,
                itemBuilder: (context, index) {
                  final aliment = _resultats[index];
                  final couleurNutri = _couleurNutriscore(aliment.nutriscore);

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: aliment.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                aliment.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 40),
                              ),
                            )
                          : const Icon(Icons.fastfood, color: Colors.deepPurple, size: 36),
                      title: Text(
                        aliment.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${aliment.calories100g.round()} kcal/100g • P:${aliment.proteines100g}g G:${aliment.glucides100g}g L:${aliment.lipides100g}g',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (aliment.nutriscore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: couleurNutri,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                aliment.nutriscore!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          const Icon(Icons.add_circle, color: Colors.deepPurple),
                        ],
                      ),
                      onTap: () => _selectionnerAliment(aliment),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
