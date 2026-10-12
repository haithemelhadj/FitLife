class MontantTnd {
  final int millimes;

  MontantTnd(this.millimes) {
    if (millimes < 0 || millimes > 999999999999) {
      throw ArgumentError.value(millimes, 'millimes', 'Montant hors limites.');
    }
  }

  factory MontantTnd.parse(String texte) {
    final valeur = texte.trim();
    if (!RegExp(r'^\d{1,9}(\.\d{1,3})?$').hasMatch(valeur)) {
      throw const FormatException('Montant TND invalide.');
    }
    final parties = valeur.split('.');
    return MontantTnd(
      int.parse(parties[0]) * 1000 +
          int.parse((parties.length == 2 ? parties[1] : '').padRight(3, '0')),
    );
  }

  @override
  String toString() =>
      '${millimes ~/ 1000}.${(millimes % 1000).toString().padLeft(3, '0')}';

  @override
  bool operator ==(Object other) =>
      other is MontantTnd && millimes == other.millimes;

  @override
  int get hashCode => millimes.hashCode;
}

class DateCivile implements Comparable<DateCivile> {
  final int annee;
  final int mois;
  final int jour;

  DateCivile(this.annee, this.mois, this.jour) {
    final date = DateTime.utc(annee, mois, jour);
    if (annee < 1 ||
        annee > 9999 ||
        date.year != annee ||
        date.month != mois ||
        date.day != jour) {
      throw const FormatException('Date civile invalide.');
    }
  }

  factory DateCivile.parse(String texte) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(texte)) {
      throw const FormatException('Date attendue au format ISO.');
    }
    final parties = texte.split('-').map(int.parse).toList();
    return DateCivile(parties[0], parties[1], parties[2]);
  }

  int get jourSemaine => DateTime.utc(annee, mois, jour).weekday;

  DateCivile ajouterJours(int nombre) {
    final date = DateTime.utc(annee, mois, jour).add(Duration(days: nombre));
    return DateCivile(date.year, date.month, date.day);
  }

  @override
  int compareTo(DateCivile autre) => toString().compareTo(autre.toString());

  @override
  String toString() =>
      '${annee.toString().padLeft(4, '0')}-${mois.toString().padLeft(2, '0')}-${jour.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is DateCivile && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(annee, mois, jour);
}

class HeureLocale implements Comparable<HeureLocale> {
  final int minutes;

  HeureLocale(this.minutes) {
    if (minutes < 0 || minutes > 1440) {
      throw const FormatException('Heure invalide.');
    }
  }

  factory HeureLocale.parse(String texte) {
    if (!RegExp(r'^\d{2}:\d{2}(:00)?$').hasMatch(texte)) {
      throw const FormatException('Heure attendue à la minute près.');
    }
    final parties = texte.split(':');
    final heure = int.parse(parties[0]);
    final minute = int.parse(parties[1]);
    if (minute > 59 || heure > 24 || (heure == 24 && minute != 0)) {
      throw const FormatException('Heure invalide.');
    }
    return HeureLocale(heure * 60 + minute);
  }

  @override
  int compareTo(HeureLocale autre) => minutes.compareTo(autre.minutes);

  @override
  String toString() =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';
}

String texteRequis(String valeur) {
  final texte = valeur.trim();
  if (texte.isEmpty) {
    throw const FormatException('Un texte non vide est requis.');
  }
  return texte;
}

String? texteOptionnel(String? valeur) {
  final texte = valeur?.trim();
  return texte == null || texte.isEmpty ? null : texte;
}

void verifierIdentifiant(int valeur) {
  if (valeur <= 0) throw ArgumentError.value(valeur, 'identifiant');
}
