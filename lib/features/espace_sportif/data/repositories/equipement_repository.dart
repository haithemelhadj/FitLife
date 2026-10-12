import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipement.dart';

class EquipementRepository {
  final SupabaseClient client;
  EquipementRepository(this.client);

  Future<List<Equipement>> getEquipements(int idEspace) async {
    final lignes = await client
        .from('equipement')
        .select()
        .eq('id_espace', idEspace)
        .order('id_equipement');
    return lignes.map(Equipement.fromJson).toList();
  }

  Future<Equipement> ajouter(Equipement equipement) async =>
      Equipement.fromJson(
        await client
            .from('equipement')
            .insert(equipement.toInsertJson())
            .select()
            .single(),
      );

  Future<Equipement> modifier(Equipement equipement) async {
    if (equipement.idEquipement == null) {
      throw ArgumentError('Identifiant requis.');
    }
    return Equipement.fromJson(
      await client
          .from('equipement')
          .update(equipement.toJson())
          .eq('id_equipement', equipement.idEquipement!)
          .select()
          .single(),
    );
  }
}
