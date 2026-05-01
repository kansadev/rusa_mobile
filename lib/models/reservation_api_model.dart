class Reservation {
  final int idReservation;
  final int idUtilisateur;
  final int idClient;
  final int idVoyage;
  final String statutReservation;
  final bool statut;
  final String dateReservation;
  final int idSociete;
  final String dateCreation;
  final String? dateModification;
  final String nomUtilisateur;
  final String emailUtilisateur;
  final String? nomClient;
  final String? prenomClient;
  final String? telephoneClient;
  final String dateVoyage;
  final TimeOfDay heureVoyage;
  final double prixVoyage;
  final String numeroBus;
  final String villeDepart;
  final String villeArrivee;

  Reservation({
    required this.idReservation,
    required this.idUtilisateur,
    required this.idClient,
    required this.idVoyage,
    required this.statutReservation,
    required this.statut,
    required this.dateReservation,
    required this.idSociete,
    required this.dateCreation,
    this.dateModification,
    required this.nomUtilisateur,
    required this.emailUtilisateur,
    this.nomClient,
    this.prenomClient,
    this.telephoneClient,
    required this.dateVoyage,
    required this.heureVoyage,
    required this.prixVoyage,
    required this.numeroBus,
    required this.villeDepart,
    required this.villeArrivee,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      idReservation: json['idReservation'] ?? 0,
      idUtilisateur: json['idUtilisateur'] ?? 0,
      idClient: json['idClient'] ?? 0,
      idVoyage: json['idVoyage'] ?? 0,
      statutReservation: json['statutReservation'] ?? '',
      statut: json['statut'] ?? false,
      dateReservation: json['dateReservation'] ?? '',
      idSociete: json['idSociete'] ?? 0,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
      nomUtilisateur: json['nomUtilisateur'] ?? '',
      emailUtilisateur: json['emailUtilisateur'] ?? '',
      nomClient: json['nomClient'] as String?,
      prenomClient: json['prenomClient'] as String?,
      telephoneClient: json['telephoneClient'] as String?,
      dateVoyage: json['dateVoyage'] ?? '',
      heureVoyage: _parseHeureVoyage(json['heureVoyage']),
      prixVoyage: (json['prixVoyage'] ?? 0).toDouble(),
      numeroBus: json['numeroBus'] ?? '',
      villeDepart: json['villeDepart'] ?? '',
      villeArrivee: json['villeArrivee'] ?? '',
    );
  }

  static TimeOfDay _parseHeureVoyage(dynamic heureVoyage) {
    if (heureVoyage is String) {
      final parts = heureVoyage.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          ticks: 0,
          days: 0,
          hours: int.tryParse(parts[0]) ?? 0,
          milliseconds: 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0,
          totalDays: 0,
          totalHours: 0,
          totalMilliseconds: 0,
          totalMinutes: 0,
          totalSeconds: 0,
        );
      }
    } else if (heureVoyage is Map<String, dynamic>) {
      return TimeOfDay.fromJson(heureVoyage);
    }
    return  TimeOfDay(
      ticks: 0,
      days: 0,
      hours: 0,
      milliseconds: 0,
      minutes: 0,
      seconds: 0,
      totalDays: 0,
      totalHours: 0,
      totalMilliseconds: 0,
      totalMinutes: 0,
      totalSeconds: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idReservation': idReservation,
      'idUtilisateur': idUtilisateur,
      'idClient': idClient,
      'idVoyage': idVoyage,
      'statutReservation': statutReservation,
      'statut': statut,
      'dateReservation': dateReservation,
      'idSociete': idSociete,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
      'nomUtilisateur': nomUtilisateur,
      'emailUtilisateur': emailUtilisateur,
      'nomClient': nomClient,
      'prenomClient': prenomClient,
      'telephoneClient': telephoneClient,
      'dateVoyage': dateVoyage,
      'heureVoyage': heureVoyage.toJson(),
      'prixVoyage': prixVoyage,
      'numeroBus': numeroBus,
      'villeDepart': villeDepart,
      'villeArrivee': villeArrivee,
    };
  }

  // Getters pour faciliter l'accès aux données
  String get clientFullName {
    final fullName = [prenomClient, nomClient]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty) return fullName;
    return nomUtilisateur.trim().isNotEmpty ? nomUtilisateur : 'Client';
  }

  String get clientPhoneSafe {
    final phone = telephoneClient?.trim() ?? '';
    return phone.isNotEmpty ? phone : '-';
  }
  String get route => '$villeDepart - $villeArrivee';
  String get formattedPrice => '${prixVoyage.toStringAsFixed(0)} FC';
  String get formattedDate => _formatDate(dateVoyage);
  String get formattedTime =>
      '${heureVoyage.hours.toString().padLeft(2, '0')}:${heureVoyage.minutes.toString().padLeft(2, '0')}';

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String get formattedReservationDate => _formatDate(dateReservation);
}

class TimeOfDay {
  final int ticks;
  final int days;
  final int hours;
  final int milliseconds;
  final int minutes;
  final int seconds;
  final double totalDays;
  final double totalHours;
  final double totalMilliseconds;
  final double totalMinutes;
  final double totalSeconds;

  TimeOfDay({
    required this.ticks,
    required this.days,
    required this.hours,
    required this.milliseconds,
    required this.minutes,
    required this.seconds,
    required this.totalDays,
    required this.totalHours,
    required this.totalMilliseconds,
    required this.totalMinutes,
    required this.totalSeconds,
  });

  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      ticks: json['ticks'] ?? 0,
      days: json['days'] ?? 0,
      hours: json['hours'] ?? 0,
      milliseconds: json['milliseconds'] ?? 0,
      minutes: json['minutes'] ?? 0,
      seconds: json['seconds'] ?? 0,
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      totalHours: (json['totalHours'] ?? 0).toDouble(),
      totalMilliseconds: (json['totalMilliseconds'] ?? 0).toDouble(),
      totalMinutes: (json['totalMinutes'] ?? 0).toDouble(),
      totalSeconds: (json['totalSeconds'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticks': ticks,
      'days': days,
      'hours': hours,
      'milliseconds': milliseconds,
      'minutes': minutes,
      'seconds': seconds,
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalMilliseconds': totalMilliseconds,
      'totalMinutes': totalMinutes,
      'totalSeconds': totalSeconds,
    };
  }
}
