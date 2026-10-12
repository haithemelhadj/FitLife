import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/outils.dart';
import '../../data/models/contexte_espace.dart';
import '../../data/models/enums.dart';
import '../../data/models/espace_sportif.dart';
import '../../data/repositories/espace_sportif_repository.dart';
import 'espace_detail_screen.dart';
import 'espace_form_screen.dart';
import 'espace_widgets.dart';

class EspaceListScreen extends StatefulWidget {
  final EspaceSportifRepository? repository;
  const EspaceListScreen({super.key, this.repository});

  @override
  State<EspaceListScreen> createState() => _EspaceListScreenState();
}

class _EspaceListScreenState extends State<EspaceListScreen> {
  late final EspaceSportifRepository repository;
  final recherche = TextEditingController();
  StreamSubscription<AuthState>? connexion;
  List<EspaceSportif> espaces = [];
  ContexteEspace? contexte;
  TypeEspace? type;
  bool mesEspaces = false;
  bool chargement = true;
  bool suite = false;
  bool encore = false;
  String? erreur;
  String? erreurSuite;
  String filtreRecherche = '';
  int requete = 0;

  @override
  void initState() {
    super.initState();
    repository =
        widget.repository ?? EspaceSportifRepository(Supabase.instance.client);
    connexion = repository.changementsConnexion.listen(
      (_) => charger(),
      onError: (Object e) {
        if (mounted) {
          setState(() {
            requete++;
            espaces = [];
            contexte = null;
            chargement = false;
            suite = false;
            erreur = erreurEspace(e);
          });
        }
      },
    );
    charger();
  }

  @override
  void dispose() {
    recherche.dispose();
    connexion?.cancel();
    super.dispose();
  }

  Future<void> charger({bool suivant = false}) async {
    if (suivant && (suite || chargement || !encore)) return;
    final numero = ++requete;
    final curseur = suivant && espaces.isNotEmpty
        ? espaces.last.idEspace
        : null;
    if (!suivant) filtreRecherche = recherche.text;
    setState(() {
      erreurSuite = null;
      if (suivant) {
        suite = true;
      } else {
        chargement = true;
        suite = false;
        erreur = null;
        espaces = [];
        contexte = null;
      }
    });
    try {
      if (!repository.estConnecte) {
        if (mounted && numero == requete) {
          setState(() {
            erreur = 'Connectez-vous pour consulter les espaces sportifs.';
            espaces = [];
            contexte = null;
          });
        }
        return;
      }
      final droits = await repository.getContexte();
      if (!droits.accessible) {
        if (mounted && numero == requete) {
          setState(() {
            erreur = 'Votre compte ne permet pas l’accès aux espaces sportifs.';
            espaces = [];
            contexte = null;
          });
        }
        return;
      }
      final gestion =
          droits.role == RoleEspace.gestionnaire ||
          droits.role == RoleEspace.admin;
      final resultat = await repository.rechercher(
        recherche: filtreRecherche,
        type: type,
        apresId: curseur,
        mesEspaces: gestion && mesEspaces,
      );
      // Une réponse ancienne ne doit pas remplacer les nouveaux filtres.
      if (mounted && numero == requete) {
        setState(() {
          contexte = droits;
          if (!gestion) mesEspaces = false;
          espaces = suivant ? [...espaces, ...resultat] : resultat;
          encore = resultat.length == 20;
        });
      }
    } catch (e) {
      if (mounted && numero == requete) {
        setState(() {
          if (suivant) {
            erreurSuite = erreurEspace(e);
          } else {
            erreur = erreurEspace(e);
          }
        });
      }
    } finally {
      if (mounted && numero == requete) {
        setState(() {
          chargement = false;
          suite = false;
        });
      }
    }
  }

  Future<void> ajouter() async {
    final resultat = await Navigator.push<EspaceSportif>(
      context,
      MaterialPageRoute(
        builder: (_) => EspaceFormScreen(repository: repository),
      ),
    );
    if (!mounted || resultat == null) return;
    setState(() {
      mesEspaces = true;
      type = null;
      recherche.clear();
    });
    await charger();
  }

  Future<void> ouvrir(EspaceSportif espace) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspaceDetailScreen(
          idEspace: espace.idEspace!,
          repository: repository,
        ),
      ),
    );
    if (mounted) await charger();
  }

  @override
  Widget build(BuildContext context) {
    final gestion =
        contexte?.role == RoleEspace.gestionnaire ||
        contexte?.role == RoleEspace.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espaces sportifs'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: chargement ? null : charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: construireDrawer(context),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : erreur != null
          ? EtatEspace(message: erreur!, reessayer: charger)
          : RefreshIndicator(
              onRefresh: charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (gestion)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        contexte?.role == RoleEspace.admin
                            ? 'Tous les espaces à gérer'
                            : 'Mes espaces',
                      ),
                      value: mesEspaces,
                      onChanged: (valeur) {
                        setState(() {
                          mesEspaces = valeur;
                        });
                        charger();
                      },
                    ),
                  if (contexte?.role == RoleEspace.gestionnaire)
                    ElevatedButton.icon(
                      onPressed: ajouter,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un espace'),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recherche,
                    decoration: const InputDecoration(
                      labelText: 'Nom ou adresse',
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => charger(),
                  ),
                  DropdownButtonFormField<TypeEspace>(
                    key: ValueKey(type),
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Type d’espace',
                    ),
                    items: [
                      const DropdownMenuItem<TypeEspace>(
                        value: null,
                        child: Text('Tous les types'),
                      ),
                      ...TypeEspace.values.map(
                        (valeur) => DropdownMenuItem(
                          value: valeur,
                          child: Text(libelleType(valeur)),
                        ),
                      ),
                    ],
                    onChanged: (valeur) {
                      setState(() {
                        type = valeur;
                      });
                      charger();
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => charger(),
                    child: const Text('Rechercher'),
                  ),
                  if (espaces.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun espace trouvé.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final espace in espaces)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_handball),
                        title: Text(espace.nom),
                        subtitle: Text(
                          '${libelleType(espace.type)} · ${libelleStatut(espace.statut)}\n${espace.adresse}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ouvrir(espace),
                      ),
                    ),
                  if (erreurSuite != null)
                    Text(
                      erreurSuite!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (encore)
                    OutlinedButton(
                      onPressed: suite ? null : () => charger(suivant: true),
                      child: Text(
                        suite
                            ? 'Chargement…'
                            : erreurSuite != null
                            ? 'Réessayer la suite'
                            : 'Charger la suite',
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
