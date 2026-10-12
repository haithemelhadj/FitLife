import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/offre.dart';

class OffreRepository {
  final SupabaseClient client;
  OffreRepository(this.client);

  Future<List<Offre>> getOffres(int idEspace) async {
    final lignes = await client
        .from('offres_lecture')
        .select()
        .eq('id_espace', idEspace)
        .order('id_offre');
    return lignes.map(Offre.fromJson).toList();
  }

  Future<Offre> getOffre(int id) async => Offre.fromJson(
    await client.from('offres_lecture').select().eq('id_offre', id).single(),
  );

  Future<Offre> ajouter(Offre offre) async {
    final ligne = await client
        .from('offre')
        .insert(offre.toInsertJson())
        .select('id_offre')
        .single();
    return getOffre(ligne['id_offre'] as int);
  }

  Future<Offre> modifier(Offre offre) async {
    if (offre.idOffre == null) throw ArgumentError('Identifiant requis.');
    final ligne = await client
        .from('offre')
        .update(offre.toJson())
        .eq('id_offre', offre.idOffre!)
        .select('id_offre')
        .single();
    return getOffre(ligne['id_offre'] as int);
  }
}
