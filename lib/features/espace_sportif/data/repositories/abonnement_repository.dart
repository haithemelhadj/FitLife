import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/abonnement.dart';
import '../models/enums.dart';

class AbonnementRepository {
  final SupabaseClient client;
  AbonnementRepository(this.client);

  Future<List<Abonnement>> getAbonnements({
    int? idOffre,
    int? apresId,
    int limite = 20,
  }) async {
    if (limite < 1 || limite > 100 || (apresId != null && apresId < 1)) {
      throw ArgumentError('Pagination invalide.');
    }
    var requete = client.from('abonnements_lecture').select();
    if (idOffre != null) requete = requete.eq('id_offre', idOffre);
    if (apresId != null) requete = requete.gt('id_abonnement', apresId);
    final lignes = await requete.order('id_abonnement').limit(limite);
    return lignes.map(Abonnement.fromJson).toList();
  }

  // Le serveur calcule l’identité, le montant et les dates de souscription.
  Future<Abonnement> souscrire(int idOffre) async {
    final resultat = await client.rpc(
      'souscrire_offre',
      params: {'p_offre': idOffre},
    );
    return Abonnement.fromJson(Map<String, dynamic>.from(resultat as Map));
  }

  Future<Abonnement> changerStatut(
    int idAbonnement,
    StatutAbonnement statut,
  ) async {
    final resultat = await client.rpc(
      'changer_statut_abonnement',
      params: {'p_abonnement': idAbonnement, 'p_statut': statut.code},
    );
    return Abonnement.fromJson(Map<String, dynamic>.from(resultat as Map));
  }
}
