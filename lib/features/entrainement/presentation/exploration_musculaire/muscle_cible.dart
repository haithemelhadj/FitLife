import 'muscle_mapper/muscle_mapper.dart';

// Nom du muscle dans ExerciseDB (À VÉRIFIER avec la réponse réelle de l'API).
String cibleExerciseDb(MuscleGroup groupe) {
  switch (groupe) {
    case MuscleGroup.chest:
      return 'pectorals';
    case MuscleGroup.abs:
    case MuscleGroup.obliques:
      return 'abs';
    case MuscleGroup.groin:
    case MuscleGroup.innerThigh:
      return 'adductors';
    case MuscleGroup.biceps:
      return 'biceps';
    case MuscleGroup.triceps:
      return 'triceps';
    case MuscleGroup.forearms:
    case MuscleGroup.hands:
      return 'forearms';
    case MuscleGroup.deltoids:
      return 'delts';
    case MuscleGroup.quads:
      return 'quads';
    case MuscleGroup.hamstrings:
      return 'hamstrings';
    case MuscleGroup.glutes:
      return 'glutes';
    case MuscleGroup.calves:
    case MuscleGroup.tibialis:
    case MuscleGroup.feet:
      return 'calves';
    case MuscleGroup.traps:
      return 'traps';
    case MuscleGroup.lats:
      return 'lats';
    case MuscleGroup.lowerBack:
      return 'spine';
    case MuscleGroup.neck:
      return 'levator scapulae';
  }
}

// Libellé affiché à l'utilisateur.
String libelleGroupe(MuscleGroup groupe) {
  switch (groupe) {
    case MuscleGroup.chest:
      return 'Pectoraux';
    case MuscleGroup.abs:
      return 'Abdominaux';
    case MuscleGroup.obliques:
      return 'Obliques';
    case MuscleGroup.groin:
      return 'Aine';
    case MuscleGroup.biceps:
      return 'Biceps';
    case MuscleGroup.triceps:
      return 'Triceps';
    case MuscleGroup.forearms:
      return 'Avant-bras';
    case MuscleGroup.hands:
      return 'Mains';
    case MuscleGroup.deltoids:
      return 'Épaules';
    case MuscleGroup.quads:
      return 'Quadriceps';
    case MuscleGroup.hamstrings:
      return 'Ischio-jambiers';
    case MuscleGroup.glutes:
      return 'Fessiers';
    case MuscleGroup.calves:
      return 'Mollets';
    case MuscleGroup.tibialis:
      return 'Tibial';
    case MuscleGroup.innerThigh:
      return 'Intérieur des cuisses';
    case MuscleGroup.feet:
      return 'Pieds';
    case MuscleGroup.traps:
      return 'Trapèzes';
    case MuscleGroup.lats:
      return 'Dorsaux';
    case MuscleGroup.lowerBack:
      return 'Bas du dos';
    case MuscleGroup.neck:
      return 'Cou';
  }
}