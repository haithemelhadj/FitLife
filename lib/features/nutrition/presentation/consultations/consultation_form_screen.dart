import 'package:flutter/material.dart';
import '../../data/models/consultation.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/repositories/consultation_repository.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String idAthlete;

  const ConsultationFormScreen({
    super.key,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ConsultationRepository _repository = ConsultationRepository();

  List<NutritionnisteItem> _nutritionnistes = [];
  NutritionnisteItem? _nutritionnisteSelectionne;
  DateTime _dateSelectionnee = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _heureSelectionnee = const TimeOfDay(hour: 14, minute: 30);
  final TextEditingController _motifController = TextEditingController();
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerPraticiens();
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _chargerPraticiens() async {
    try {
      final liste = await _repository.getNutritionnistes();
      if (mounted) {
        setState(() {
          _nutritionnistes = liste;
          if (liste.isNotEmpty) {
            _nutritionnisteSelectionne = liste.first;
          }
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _choisirDate() async {
    final DateTime? choix = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (choix != null) {
      setState(() => _dateSelectionnee = choix);
    }
  }

  Future<void> _choisirHeure() async {
    final TimeOfDay? choix = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
    );
    if (choix != null) {
      setState(() => _heureSelectionnee = choix);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate() || _nutritionnisteSelectionne == null) {
      return;
    }

    final heureFormattee =
        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:${_heureSelectionnee.minute.toString().padLeft(2, '0')}';

    final nouvelleConsultation = Consultation(
      idConsultation: '',
      idAthlete: widget.idAthlete,
      idNutritionniste: _nutritionnisteSelectionne!.id,
      nomNutritionniste: _nutritionnisteSelectionne!.nom,
      dateConsultation: _dateSelectionnee,
      heureConsultation: heureFormattee,
      motif: _motifController.text.trim(),
      statut: StatutConsultation.DEMANDEE,
    );

    try {
      await _repository.demanderConsultation(nouvelleConsultation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de consultation envoyée avec succès !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la demande : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTexte =
        '${_dateSelectionnee.day.toString().padLeft(2, '0')}/${_dateSelectionnee.month.toString().padLeft(2, '0')}/${_dateSelectionnee.year}';
    final heureTexte =
        '${_heureSelectionnee.hour.toString().padLeft(2, '0')}:${_heureSelectionnee.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre une consultation'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.deepPurple),
                                SizedBox(width: 8),
                                Text(
                                  'Métier 1 : Prise de rendez-vous',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sélectionnez votre praticien, la date et formulez votre motif.',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Choix du nutritionniste
                    const Text('1. Nutritionniste', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<NutritionnisteItem>(
                      initialValue: _nutritionnisteSelectionne,
                      items: _nutritionnistes.map((n) {
                        return DropdownMenuItem(
                          value: n,
                          child: Text('${n.nom} (${n.specialite})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _nutritionnisteSelectionne = val),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Choix de la date et heure
                    const Text('2. Date & Heure', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(dateTexte),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirHeure,
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(heureTexte),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Motif
                    const Text('3. Motif de la consultation', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _motifController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ex : Établir un plan pour perte de 8 kg coordonné avec mes entraînements...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Veuillez préciser le motif de consultation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bouton d'envoi
                    ElevatedButton.icon(
                      onPressed: _soumettre,
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer la demande de consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
