import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/disponibilite_espace.dart';

class DisponibiliteEspaceRepository {
  final SupabaseClient client;
  DisponibiliteEspaceRepository(this.client);

  Future<List<DisponibiliteEspace>> getHoraires(int idEspace) async {
    final lignes = await client
        .from('disponibilite_espace')
        .select()
        .eq('id_espace', idEspace)
        .order('jour')
        .order('heure_ouverture');
    return lignes.map(DisponibiliteEspace.fromJson).toList();
  }

  Future<DisponibiliteEspace> ajouter(DisponibiliteEspace horaire) async =>
      DisponibiliteEspace.fromJson(
        await client
            .from('disponibilite_espace')
            .insert(horaire.toInsertJson())
            .select()
            .single(),
      );

  Future<DisponibiliteEspace> modifier(DisponibiliteEspace horaire) async {
    if (horaire.idDisponibilite == null) {
      throw ArgumentError('Identifiant requis.');
    }
    return DisponibiliteEspace.fromJson(
      await client
          .from('disponibilite_espace')
          .update(horaire.toJson())
          .eq('id_disponibilite', horaire.idDisponibilite!)
          .select()
          .single(),
    );
  }

  Future<void> supprimer(int id) async {
    await client
        .from('disponibilite_espace')
        .delete()
        .eq('id_disponibilite', id)
        .select('id_disponibilite')
        .single();
  }
}
