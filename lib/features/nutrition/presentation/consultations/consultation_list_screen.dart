import 'package:flutter/material.dart';
import '../../data/models/consultation.dart';
import '../../data/models/enums_nutrition.dart';
import '../../data/repositories/consultation_repository.dart';
import 'consultation_form_screen.dart';

class ConsultationListScreen extends StatefulWidget {
  final bool integre;
  final String idAthlete;

  const ConsultationListScreen({
    super.key,
    this.integre = false,
    this.idAthlete = 'demo-athlete-id',
  });

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  final ConsultationRepository _repository = ConsultationRepository();
  List<Consultation> _consultations = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await _repository.getConsultationsAthlete(widget.idAthlete);
    if (mounted) {
      setState(() {
        _consultations = liste;
        _chargement = false;
      });
    }
  }

  Color _couleurStatut(StatutConsultation statut) {
    switch (statut) {
      case StatutConsultation.DEMANDEE:
        return Colors.orange;
      case StatutConsultation.CONFIRMEE:
        return Colors.green;
      case StatutConsultation.TERMINEE:
        return Colors.blue;
      case StatutConsultation.ANNULEE:
        return Colors.red;
    }
  }

  Future<void> _changerStatut(Consultation consultation, StatutConsultation nouveauStatut) async {
    String? compteRendu;

    if (nouveauStatut == StatutConsultation.TERMINEE) {
      final controller = TextEditingController(text: consultation.compteRendu ?? '');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Compte-rendu de consultation'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Recommandations diététiques, plan validé...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      );
      if (ok != true) return;
      compteRendu = controller.text.trim();
    }

    await _repository.changerStatut(
      consultation.idConsultation,
      nouveauStatut,
      compteRendu: compteRendu,
    );
    _charger();
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_consultations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Aucune consultation programmée.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ConsultationFormScreen(idAthlete: widget.idAthlete),
                    ),
                  );
                  if (res == true) _charger();
                },
                icon: const Icon(Icons.add),
                label: const Text('Demander un rendez-vous'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ConsultationFormScreen(idAthlete: widget.idAthlete),
                  ),
                );
                if (res == true) _charger();
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Prendre une nouvelle consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          );
        }

        final c = _consultations[index - 1];
        final couleur = _couleurStatut(c.statut);
        final dateFormatee =
            '${c.dateConsultation.day.toString().padLeft(2, '0')}/${c.dateConsultation.month.toString().padLeft(2, '0')}/${c.dateConsultation.year}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.nomNutritionniste ?? 'Nutritionniste',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: couleur),
                      ),
                      child: Text(
                        c.statutTexte,
                        style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(dateFormatee, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(c.heureConsultation, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Motif : ${c.motif}', style: const TextStyle(fontSize: 14)),
                if (c.compteRendu != null && c.compteRendu!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Compte-rendu : ${c.compteRendu}',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Actions selon le rôle/statut (Métier 1 : confirmer, refuser ou terminer)
                Wrap(
                  spacing: 8,
                  children: [
                    if (c.estEnAttente) ...[
                      OutlinedButton.icon(
                        onPressed: () => _changerStatut(c, StatutConsultation.CONFIRMEE),
                        icon: const Icon(Icons.check, size: 16, color: Colors.green),
                        label: const Text('Confirmer', style: TextStyle(color: Colors.green)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _changerStatut(c, StatutConsultation.ANNULEE),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    if (c.estConfirmee)
                      ElevatedButton.icon(
                        onPressed: () => _changerStatut(c, StatutConsultation.TERMINEE),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Clôturer séance'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    if (widget.integre) {
      return _construireCorps();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations Nutrition'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: _construireCorps(),
    );
  }
}
