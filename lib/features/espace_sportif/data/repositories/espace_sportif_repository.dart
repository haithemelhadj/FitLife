import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contexte_espace.dart';
import '../models/enums.dart';
import '../models/espace_sportif.dart';

class EspaceSportifRepository {
  final SupabaseClient client;

  EspaceSportifRepository(this.client);

  Future<ContexteEspace> getContexte() async {
    final resultat = await client.rpc('contexte_espaces');
    return ContexteEspace.fromJson(Map<String, dynamic>.from(resultat as Map));
  }

  Future<List<EspaceSportif>> rechercher({
    String recherche = '',
    TypeEspace? type,
    int? apresId,
    int limite = 20,
    bool mesEspaces = false,
  }) async {
    if (limite < 1 || limite > 100 || (apresId != null && apresId < 1)) {
      throw ArgumentError('Pagination invalide.');
    }
    final lignes = await client.rpc(
      'rechercher_espaces',
      params: {
        'p_recherche': recherche.trim(),
        'p_type': type?.code,
        'p_apres': apresId,
        'p_limite': limite,
        'p_mes_espaces': mesEspaces,
      },
    );
    return (lignes as List)
        .map(
          (ligne) =>
              EspaceSportif.fromJson(Map<String, dynamic>.from(ligne as Map)),
        )
        .toList();
  }

  Future<EspaceSportif> getEspace(int id) async => EspaceSportif.fromJson(
    await client.from('espace_sportif').select().eq('id_espace', id).single(),
  );

  Future<EspaceSportif> ajouter(EspaceSportif espace) async =>
      EspaceSportif.fromJson(
        await client
            .from('espace_sportif')
            .insert(espace.toJson())
            .select()
            .single(),
      );

  Future<EspaceSportif> modifier(EspaceSportif espace) async {
    if (espace.idEspace == null) throw ArgumentError('Identifiant requis.');
    return EspaceSportif.fromJson(
      await client
          .from('espace_sportif')
          .update(espace.toJson())
          .eq('id_espace', espace.idEspace!)
          .select()
          .single(),
    );
  }
}
