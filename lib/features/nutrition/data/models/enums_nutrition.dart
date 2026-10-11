// ignore_for_file: constant_identifier_names

/// Énumération des objectifs nutritionnels d'un athlète.
enum ObjectifNutrition {
  PERTE_POIDS,
  PRISE_MASSE,
  MAINTIEN,
  PERFORMANCE,
}

/// Énumération du statut d'une consultation nutritionnelle.
enum StatutConsultation {
  DEMANDEE,
  CONFIRMEE,
  TERMINEE,
  ANNULEE,
}

/// Énumération du statut d'un programme nutritionnel.
enum StatutProgramme {
  ACTIF,
  TERMINE,
  SUSPENDU,
  ANNULE,
}

/// Énumération des types de repas au cours de la journée.
enum TypeRepas {
  PETIT_DEJEUNER,
  DEJEUNER,
  DINER,
  COLLATION,
}

/// Convertit une valeur d'énumération en texte lisible pour l'interface utilisateur.
/// Exemple : PERTE_POIDS -> "Perte de poids", PETIT_DEJEUNER -> "Petit-déjeuner".
String formatEnumNutrition(Enum valeur) {
  switch (valeur) {
    // Objectifs nutritionnels
    case ObjectifNutrition.PERTE_POIDS:
      return 'Perte de poids';
    case ObjectifNutrition.PRISE_MASSE:
      return 'Prise de masse';
    case ObjectifNutrition.MAINTIEN:
      return 'Maintien';
    case ObjectifNutrition.PERFORMANCE:
      return 'Performance';

    // Statuts de consultation
    case StatutConsultation.DEMANDEE:
      return 'Demandée';
    case StatutConsultation.CONFIRMEE:
      return 'Confirmée';
    case StatutConsultation.TERMINEE:
      return 'Terminée';
    case StatutConsultation.ANNULEE:
      return 'Annulée';

    // Statuts de programme
    case StatutProgramme.ACTIF:
      return 'Actif';
    case StatutProgramme.TERMINE:
      return 'Terminé';
    case StatutProgramme.SUSPENDU:
      return 'Suspendu';
    case StatutProgramme.ANNULE:
      return 'Annulé';

    // Types de repas
    case TypeRepas.PETIT_DEJEUNER:
      return 'Petit-déjeuner';
    case TypeRepas.DEJEUNER:
      return 'Déjeuner';
    case TypeRepas.DINER:
      return 'Dîner';
    case TypeRepas.COLLATION:
      return 'Collation';

    default:
      return valeur.name.replaceAll('_', ' ');
  }
}
