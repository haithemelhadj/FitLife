import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/espace_sportif.dart';
import 'espace_sportif_repository.dart';

class EspacePublicRepository extends EspaceSportifRepository {
  EspacePublicRepository(super.client);
  @override
  bool get lecturePublique => true;
  @override
  Stream<AuthState> get changementsConnexion => const Stream.empty();

  Future<List<EspaceSportif>> consulter({
    String recherche = '',
    TypeEspace? type,
    int? apresId,
    int limite = 20,
    int? id,
  }) async {
    final resultat = await client.rpc(
      'consulter_espaces_publics',
      params: {
        'p_recherche': recherche.trim(),
        'p_type': type?.code,
        'p_apres': apresId,
        'p_limite': limite,
        'p_id': id,
      },
    );
    return (resultat as List)
        .map(
          (ligne) =>
              EspaceSportif.fromJson(Map<String, dynamic>.from(ligne as Map)),
        )
        .toList();
  }

  @override
  Future<List<EspaceSportif>> rechercher({
    String recherche = '',
    TypeEspace? type,
    int? apresId,
    int limite = 20,
    bool mesEspaces = false,
  }) => consulter(
    recherche: recherche,
    type: type,
    apresId: apresId,
    limite: limite,
  );
  @override
  Future<EspaceSportif> getEspace(int id) async {
    final resultat = await consulter(id: id, limite: 1);
    if (resultat.isEmpty) {
      throw const PostgrestException(
        message: 'Espace indisponible.',
        code: 'PGRST116',
      );
    }
    return resultat.single;
  }

  @override
  Future<EspaceSportif> ajouter(EspaceSportif espace) async =>
      throw const AuthException('Lecture seule.');
  @override
  Future<EspaceSportif> modifier(EspaceSportif espace) async =>
      throw const AuthException('Lecture seule.');
  @override
  Future<EspaceSportif> changerStatut(int id, StatutEspace statut) async =>
      throw const AuthException('Lecture seule.');
}
