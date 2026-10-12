import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/contexte_espace.dart';
import '../../data/models/enums.dart';
import '../../data/models/espace_sportif.dart';
import '../../data/repositories/espace_sportif_repository.dart';
import 'espace_form_screen.dart';
import 'espace_widgets.dart';

class EspaceDetailScreen extends StatefulWidget {
  final int idEspace;
  final EspaceSportifRepository repository;
  const EspaceDetailScreen({
    super.key,
    required this.idEspace,
    required this.repository,
  });

  @override
  State<EspaceDetailScreen> createState() => _EspaceDetailScreenState();
}

class _EspaceDetailScreenState extends State<EspaceDetailScreen> {
  EspaceSportif? espace;
  ContexteEspace? contexte;
  String? erreur;
  bool chargement = true;
  bool modification = false;
  int requete = 0;
  StreamSubscription<AuthState>? connexion;

  @override
  void initState() {
    super.initState();
    connexion = widget.repository.changementsConnexion.listen(
      (_) => charger(),
      onError: (Object e) {
        if (mounted) {
          setState(() {
            requete++;
            espace = null;
            contexte = null;
            chargement = false;
            erreur = erreurEspace(e);
          });
        }
      },
    );
    charger();
  }

  @override
  void dispose() {
    connexion?.cancel();
    super.dispose();
  }

  Future<void> charger() async {
    final numero = ++requete;
    setState(() {
      chargement = true;
      espace = null;
      contexte = null;
      erreur = null;
    });
    try {
      if (!widget.repository.lecturePublique &&
          !widget.repository.estConnecte) {
        if (mounted && numero == requete) {
          setState(() {
            erreur = 'Connectez-vous pour consulter cet espace.';
          });
        }
        return;
      }
      final droits = widget.repository.lecturePublique
          ? null
          : await widget.repository.getContexte();
      if (!widget.repository.lecturePublique && droits?.accessible != true) {
        if (mounted && numero == requete) {
          setState(() {
            erreur = 'Votre compte ne permet pas l’accès aux espaces sportifs.';
          });
        }
        return;
      }
      final resultat = await widget.repository.getEspace(widget.idEspace);
      if (mounted && numero == requete) {
        setState(() {
          espace = resultat;
          contexte = droits;
        });
      }
    } catch (e) {
      if (mounted && numero == requete) {
        setState(() {
          erreur = erreurEspace(e);
        });
      }
    } finally {
      if (mounted && numero == requete) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  Future<void> modifier() async {
    await Navigator.push<EspaceSportif>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EspaceFormScreen(repository: widget.repository, espace: espace),
      ),
    );
    if (mounted) await charger();
  }

  Future<void> desactiver() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogue) => AlertDialog(
        title: const Text('Désactiver cet espace ?'),
        content: const Text(
          'Il sera retiré du catalogue. Les abonnements existants seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogue, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogue, true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (!mounted || confirme != true) return;
    setState(() {
      modification = true;
    });
    try {
      await widget.repository.changerStatut(
        widget.idEspace,
        StatutEspace.inactif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Espace désactivé.')));
      await charger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erreurEspace(e))));
      }
    } finally {
      if (mounted) {
        setState(() {
          modification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final valeur = espace;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l’espace'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: chargement || modification ? null : charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : erreur != null
          ? EtatEspace(message: erreur!, reessayer: charger)
          : valeur == null
          ? const EtatEspace(message: 'Espace indisponible.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  valeur.nom,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(libelleType(valeur.type))),
                    Chip(label: Text(libelleStatut(valeur.statut))),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(valeur.adresse),
                ),
                if (valeur.description != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(valeur.description!),
                  ),
                for (final champ in <String, String?>{
                  'Téléphone': valeur.telephone,
                  'Email': valeur.email,
                  'Site web': valeur.siteWeb,
                  'Coordonnées': valeur.latitude == null
                      ? null
                      : '${valeur.latitude}, ${valeur.longitude}',
                }.entries)
                  if (champ.value != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(champ.key),
                      subtitle: SelectableText(champ.value!),
                    ),
                if (valeur.idGestionnaire != null &&
                    contexte?.peutGerer(valeur.idGestionnaire!) == true) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: modification ? null : modifier,
                    child: const Text('Modifier'),
                  ),
                  if (valeur.statut != StatutEspace.inactif)
                    OutlinedButton(
                      onPressed: modification ? null : desactiver,
                      child: Text(
                        modification ? 'Désactivation…' : 'Désactiver',
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
