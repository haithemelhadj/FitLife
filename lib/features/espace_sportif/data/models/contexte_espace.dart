import '../../domain/valeurs.dart';
import 'enums.dart';

class ContexteEspace {
  final String? idUtilisateur;
  final RoleEspace? role;
  final DateCivile dateServeur;

  const ContexteEspace({
    required this.idUtilisateur,
    required this.role,
    required this.dateServeur,
  });

  factory ContexteEspace.fromJson(Map<String, dynamic> json) => ContexteEspace(
    idUtilisateur: json['id_utilisateur'] as String?,
    role: json['role'] == null
        ? null
        : RoleEspace.depuisCode(json['role'] as String),
    dateServeur: DateCivile.parse(json['date'] as String),
  );

  bool get accessible => idUtilisateur != null && role != null;
  bool peutGerer(String idGestionnaire) =>
      accessible &&
      (role == RoleEspace.admin ||
          (role == RoleEspace.gestionnaire && idUtilisateur == idGestionnaire));
}
