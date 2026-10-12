import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../espaces/espace_widgets.dart';

class DashboardEspacesScreen extends StatefulWidget {
  final SupabaseClient client;
  const DashboardEspacesScreen({super.key, required this.client});
  @override
  State<DashboardEspacesScreen> createState() => _DashboardEspacesScreenState();
}

class _DashboardEspacesScreenState extends State<DashboardEspacesScreen> {
  Map<String, dynamic>? resume;
  String? erreur;
  bool chargement = true;
  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    setState(() {
      chargement = true;
      erreur = null;
      resume = null;
    });
    try {
      final resultat = await widget.client.rpc('resume_admin_espaces');
      if (mounted) {
        setState(() {
          resume = Map<String, dynamic>.from(resultat as Map);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          erreur = erreurEspace(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard espaces sportifs'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: chargement ? null : charger,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: chargement
        ? const Center(child: CircularProgressIndicator())
        : erreur != null
        ? EtatEspace(message: erreur!, reessayer: charger)
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final champ in {
                'total': 'Tous les espaces',
                'actifs': 'Actifs',
                'inactifs': 'Inactifs',
                'maintenance': 'En maintenance',
              }.entries)
                Card(
                  child: ListTile(
                    title: Text(champ.value),
                    trailing: Text(
                      '${resume![champ.key]}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/espaces-sportifs'),
                icon: const Icon(Icons.edit),
                label: const Text('Gérer les espaces'),
              ),
            ],
          ),
  );
}
