import '../../domain/valeurs.dart';
import 'enums.dart';

class EspaceSportif {
  final int? idEspace;
  final String nom;
  final String? description;
  final TypeEspace type;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final StatutEspace statut;
  final String? idGestionnaire;

  EspaceSportif({
    this.idEspace,
    required String nom,
    String? description,
    required this.type,
    required String adresse,
    this.latitude,
    this.longitude,
    String? telephone,
    String? email,
    String? siteWeb,
    this.statut = StatutEspace.inactif,
    this.idGestionnaire,
  }) : nom = texteRequis(nom),
       adresse = texteRequis(adresse),
       description = texteOptionnel(description),
       telephone = texteOptionnel(telephone),
       email = texteOptionnel(email),
       siteWeb = texteOptionnel(siteWeb) {
    if (idEspace != null) verifierIdentifiant(idEspace!);
    if ((latitude == null) != (longitude == null) ||
        (latitude != null &&
            (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) ||
        (longitude != null &&
            (!longitude!.isFinite || longitude! < -180 || longitude! > 180))) {
      throw const FormatException('Coordonnées invalides ou incomplètes.');
    }
  }

  factory EspaceSportif.fromJson(Map<String, dynamic> json) => EspaceSportif(
    idEspace: json['id_espace'] as int,
    nom: json['nom'] as String,
    description: json['description'] as String?,
    type: TypeEspace.depuisCode(json['type'] as String),
    adresse: json['adresse'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    telephone: json['telephone'] as String?,
    email: json['email'] as String?,
    siteWeb: json['site_web'] as String?,
    statut: StatutEspace.depuisCode(json['statut'] as String),
    idGestionnaire: json['id_gestionnaire'] as String,
  );

  // La base détermine le gestionnaire et conserve les identifiants.
  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'type': type.code,
    'adresse': adresse,
    'latitude': latitude,
    'longitude': longitude,
    'telephone': telephone,
    'email': email,
    'site_web': siteWeb,
    'statut': statut.code,
  };
}
