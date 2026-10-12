import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/espace_sportif.dart';
import '../../data/repositories/espace_sportif_repository.dart';
import 'espace_widgets.dart';

class EspaceFormScreen extends StatefulWidget {
  final EspaceSportifRepository repository;
  final EspaceSportif? espace;
  const EspaceFormScreen({super.key, required this.repository, this.espace});

  @override
  State<EspaceFormScreen> createState() => _EspaceFormScreenState();
}

class _EspaceFormScreenState extends State<EspaceFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> champs;
  TypeEspace? type;
  late StatutEspace statut;
  bool enregistrement = false;
  String? erreur;

  @override
  void initState() {
    super.initState();
    final espace = widget.espace;
    champs = {
      'Nom': TextEditingController(text: espace?.nom),
      'Adresse': TextEditingController(text: espace?.adresse),
      'Description': TextEditingController(text: espace?.description),
      'Téléphone': TextEditingController(text: espace?.telephone),
      'Email': TextEditingController(text: espace?.email),
      'Site web': TextEditingController(text: espace?.siteWeb),
      'Latitude': TextEditingController(text: espace?.latitude?.toString()),
      'Longitude': TextEditingController(text: espace?.longitude?.toString()),
    };
    type = espace?.type;
    statut = espace?.statut ?? StatutEspace.inactif;
  }

  @override
  void dispose() {
    for (final champ in champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  String texte(String nom) => champs[nom]!.text.trim();

  String? valider(String nom, String? valeur) {
    final texte = (valeur ?? '').trim();
    if (['Nom', 'Adresse'].contains(nom) && texte.isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    if (nom == 'Email' &&
        texte.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texte)) {
      return 'Saisissez une adresse email valide.';
    }
    if (nom == 'Site web' && texte.isNotEmpty) {
      final uri = Uri.tryParse(texte);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          texte.contains(RegExp(r'\s'))) {
        return 'Saisissez une URL HTTP ou HTTPS valide.';
      }
    }
    if (nom == 'Latitude' || nom == 'Longitude') {
      final autre = nom == 'Latitude' ? 'Longitude' : 'Latitude';
      if (texte.isEmpty) {
        return this.texte(autre).isEmpty
            ? null
            : 'Les deux coordonnées sont nécessaires.';
      }
      final nombre = double.tryParse(texte.replaceAll(',', '.'));
      final limite = nom == 'Latitude' ? 90 : 180;
      if (nombre == null || !nombre.isFinite || nombre.abs() > limite) {
        return 'Valeur attendue entre ${-limite} et $limite.';
      }
    }
    return null;
  }

  Future<void> enregistrer() async {
    if (enregistrement || !formKey.currentState!.validate()) return;
    setState(() {
      enregistrement = true;
      erreur = null;
    });
    try {
      final contexte = await widget.repository.getContexte();
      final autorise = widget.espace == null
          ? contexte.accessible && contexte.role == RoleEspace.gestionnaire
          : contexte.peutGerer(widget.espace!.idGestionnaire!);
      if (!autorise) {
        if (mounted) {
          setState(() {
            erreur = 'Votre compte ne peut pas modifier cet espace.';
          });
        }
        return;
      }
      if (!mounted) return;
      final espace = EspaceSportif(
        idEspace: widget.espace?.idEspace,
        nom: texte('Nom'),
        adresse: texte('Adresse'),
        type: type!,
        statut: statut,
        description: texte('Description'),
        telephone: texte('Téléphone'),
        email: texte('Email'),
        siteWeb: texte('Site web'),
        latitude: double.tryParse(texte('Latitude').replaceAll(',', '.')),
        longitude: double.tryParse(texte('Longitude').replaceAll(',', '.')),
      );
      final resultat = widget.espace == null
          ? await widget.repository.ajouter(espace)
          : await widget.repository.modifier(espace);
      if (mounted) Navigator.pop(context, resultat);
    } catch (e) {
      if (mounted) {
        setState(() {
          erreur = erreurEspace(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          enregistrement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !enregistrement,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.espace == null ? 'Ajouter un espace' : 'Modifier un espace',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final nom in champs.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    key: ValueKey(nom),
                    controller: champs[nom],
                    enabled: !enregistrement,
                    decoration: InputDecoration(
                      labelText: nom,
                      helperText: ['Latitude', 'Longitude'].contains(nom)
                          ? 'Facultatif, à renseigner ensemble.'
                          : null,
                    ),
                    minLines: nom == 'Description' ? 3 : 1,
                    maxLines: nom == 'Description' ? 5 : 1,
                    keyboardType: switch (nom) {
                      'Latitude' ||
                      'Longitude' => const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      'Téléphone' => TextInputType.phone,
                      'Email' => TextInputType.emailAddress,
                      'Site web' => TextInputType.url,
                      _ => TextInputType.text,
                    },
                    validator: (valeur) => valider(nom, valeur),
                  ),
                ),
              DropdownButtonFormField<TypeEspace>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TypeEspace.values
                    .map(
                      (valeur) => DropdownMenuItem(
                        value: valeur,
                        child: Text(libelleType(valeur)),
                      ),
                    )
                    .toList(),
                onChanged: enregistrement
                    ? null
                    : (valeur) => setState(() {
                        type = valeur;
                      }),
                validator: (valeur) =>
                    valeur == null ? 'Choisissez un type.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StatutEspace>(
                initialValue: statut,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: StatutEspace.values
                    .map(
                      (valeur) => DropdownMenuItem(
                        value: valeur,
                        child: Text(libelleStatut(valeur)),
                      ),
                    )
                    .toList(),
                onChanged: enregistrement
                    ? null
                    : (valeur) => setState(() {
                        statut = valeur!;
                      }),
              ),
              const SizedBox(height: 12),
              const Text(
                'Un espace inactif ou en maintenance ne figure pas dans le catalogue. Ses abonnements sont conservés.',
              ),
              if (erreur != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    erreur!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: enregistrement ? null : enregistrer,
                child: Text(enregistrement ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
