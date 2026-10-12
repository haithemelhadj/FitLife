enum TypeEspace {
  salle('SALLE'),
  clubSportif('CLUB_SPORTIF'),
  stade('STADE'),
  terrain('TERRAIN'),
  parc('PARC'),
  centreSportif('CENTRE_SPORTIF'),
  piscine('PISCINE'),
  autre('AUTRE');

  final String code;
  const TypeEspace(this.code);

  static TypeEspace depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum StatutEspace {
  actif('ACTIF'),
  inactif('INACTIF'),
  enMaintenance('EN_MAINTENANCE');

  final String code;
  const StatutEspace(this.code);

  static StatutEspace depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum EtatEquipement {
  bon('BON'),
  endommage('ENDOMMAGE'),
  enMaintenance('EN_MAINTENANCE'),
  horsService('HORS_SERVICE');

  final String code;
  const EtatEquipement(this.code);

  static EtatEquipement depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum JourSemaine {
  lundi('LUNDI'),
  mardi('MARDI'),
  mercredi('MERCREDI'),
  jeudi('JEUDI'),
  vendredi('VENDREDI'),
  samedi('SAMEDI'),
  dimanche('DIMANCHE');

  final String code;
  const JourSemaine(this.code);

  static JourSemaine depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum TypeOffre {
  abonnement('ABONNEMENT'),
  pack('PACK'),
  seance('SEANCE');

  final String code;
  const TypeOffre(this.code);

  static TypeOffre depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum StatutOffre {
  active('ACTIVE'),
  inactive('INACTIVE'),
  expiree('EXPIREE');

  final String code;
  const StatutOffre(this.code);

  static StatutOffre depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum StatutAbonnement {
  actif('ACTIF'),
  expire('EXPIRE'),
  suspendu('SUSPENDU'),
  annule('ANNULE');

  final String code;
  const StatutAbonnement(this.code);

  static StatutAbonnement depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}

enum RoleEspace {
  athlete('ATHLETE'),
  gestionnaire('GESTIONNAIRE_ESPACE'),
  coach('COACH'),
  nutritionniste('NUTRITIONNISTE'),
  admin('ADMIN');

  final String code;
  const RoleEspace(this.code);

  static RoleEspace depuisCode(String code) =>
      values.firstWhere((valeur) => valeur.code == code);
}
