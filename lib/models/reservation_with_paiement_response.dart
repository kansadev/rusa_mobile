class ReservationWithPaiementResponse {
  final ReservationData reservation;
  final PaiementData paiement;
  final BilletData billet;
  final String transactionId;
  final String statut;
  final String message;
  final String dateCreation;

  ReservationWithPaiementResponse({
    required this.reservation,
    required this.paiement,
    required this.billet,
    required this.transactionId,
    required this.statut,
    required this.message,
    required this.dateCreation,
  });

  factory ReservationWithPaiementResponse.fromJson(Map<String, dynamic> json) {
    return ReservationWithPaiementResponse(
      reservation: ReservationData.fromJson(json['reservation']),
      paiement: PaiementData.fromJson(json['paiement']),
      billet: BilletData.fromJson(json['billet']),
      transactionId: json['transactionId'] ?? '',
      statut: json['statut'] ?? '',
      message: json['message'] ?? '',
      dateCreation: json['dateCreation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation': reservation.toJson(),
      'paiement': paiement.toJson(),
      'billet': billet.toJson(),
      'transactionId': transactionId,
      'statut': statut,
      'message': message,
      'dateCreation': dateCreation,
    };
  }
}

class ReservationData {
  final int idReservation;
  final int idUtilisateur;
  final int idClient;
  final int idVoyage;
  final String statutReservation;
  final bool statut;
  final String dateReservation;
  final int idSociete;
  final String dateCreation;
  final String dateModification;
  final String nomUtilisateur;
  final String emailUtilisateur;
  final String nomClient;
  final String prenomClient;
  final String telephoneClient;
  final String dateVoyage;
  final HeureVoyage heureVoyage;
  final double prixVoyage;
  final String numeroBus;
  final String villeDepart;
  final String villeArrivee;

  ReservationData({
    required this.idReservation,
    required this.idUtilisateur,
    required this.idClient,
    required this.idVoyage,
    required this.statutReservation,
    required this.statut,
    required this.dateReservation,
    required this.idSociete,
    required this.dateCreation,
    required this.dateModification,
    required this.nomUtilisateur,
    required this.emailUtilisateur,
    required this.nomClient,
    required this.prenomClient,
    required this.telephoneClient,
    required this.dateVoyage,
    required this.heureVoyage,
    required this.prixVoyage,
    required this.numeroBus,
    required this.villeDepart,
    required this.villeArrivee,
  });

  factory ReservationData.fromJson(Map<String, dynamic> json) {
    return ReservationData(
      idReservation: json['idReservation'] ?? 0,
      idUtilisateur: json['idUtilisateur'] ?? 0,
      idClient: json['idClient'] ?? 0,
      idVoyage: json['idVoyage'] ?? 0,
      statutReservation: json['statutReservation'] ?? '',
      statut: json['statut'] ?? false,
      dateReservation: json['dateReservation'] ?? '',
      idSociete: json['idSociete'] ?? 0,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'] ?? '',
      nomUtilisateur: json['nomUtilisateur'] ?? '',
      emailUtilisateur: json['emailUtilisateur'] ?? '',
      nomClient: json['nomClient'] ?? '',
      prenomClient: json['prenomClient'] ?? '',
      telephoneClient: json['telephoneClient'] ?? '',
      dateVoyage: json['dateVoyage'] ?? '',
      heureVoyage: HeureVoyage.fromJson(json['heureVoyage'] ?? {}),
      prixVoyage: (json['prixVoyage'] ?? 0).toDouble(),
      numeroBus: json['numeroBus'] ?? '',
      villeDepart: json['villeDepart'] ?? '',
      villeArrivee: json['villeArrivee'] ?? '',
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
}

class HeureVoyage {
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

  HeureVoyage({
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

  factory HeureVoyage.fromJson(Map<String, dynamic> json) {
    return HeureVoyage(
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

  String get formattedTime {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class PaiementData {
  final int idPaiement;
  final double montantAPaye;
  final double montantPaye;
  final double resteAPaye;
  final String methodePaiement;
  final String referenceTransaction;
  final bool statut;
  final String dateCreation;
  final String dateEmissionBillet;
  final int idBilletEmis;
  final int idReservation;
  final int idSociete;
  final bool estComplet;
  final bool estPartiel;

  PaiementData({
    required this.idPaiement,
    required this.montantAPaye,
    required this.montantPaye,
    required this.resteAPaye,
    required this.methodePaiement,
    required this.referenceTransaction,
    required this.statut,
    required this.dateCreation,
    required this.dateEmissionBillet,
    required this.idBilletEmis,
    required this.idReservation,
    required this.idSociete,
    required this.estComplet,
    required this.estPartiel,
  });

  factory PaiementData.fromJson(Map<String, dynamic> json) {
    return PaiementData(
      idPaiement: json['idPaiement'] ?? 0,
      montantAPaye: (json['montantAPaye'] ?? 0).toDouble(),
      montantPaye: (json['montantPaye'] ?? 0).toDouble(),
      resteAPaye: (json['resteAPaye'] ?? 0).toDouble(),
      methodePaiement: json['methodePaiement'] ?? '',
      referenceTransaction: json['referenceTransaction'] ?? '',
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateEmissionBillet: json['dateEmissionBillet'] ?? '',
      idBilletEmis: json['idBilletEmis'] ?? 0,
      idReservation: json['idReservation'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      estComplet: json['estComplet'] ?? false,
      estPartiel: json['estPartiel'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPaiement': idPaiement,
      'montantAPaye': montantAPaye,
      'montantPaye': montantPaye,
      'resteAPaye': resteAPaye,
      'methodePaiement': methodePaiement,
      'referenceTransaction': referenceTransaction,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateEmissionBillet': dateEmissionBillet,
      'idBilletEmis': idBilletEmis,
      'idReservation': idReservation,
      'idSociete': idSociete,
      'estComplet': estComplet,
      'estPartiel': estPartiel,
    };
  }
}

class BilletData {
  final int id;
  final String qrCode;
  final String dateGeneration;
  final int idReservation;
  final int idClient;
  final int idSociete;
  final String urlBillet;

  BilletData({
    required this.id,
    required this.qrCode,
    required this.dateGeneration,
    required this.idReservation,
    required this.idClient,
    required this.idSociete,
    required this.urlBillet,
  });

  factory BilletData.fromJson(Map<String, dynamic> json) {
    return BilletData(
      id: json['id'] ?? 0,
      qrCode: json['qrCode'] ?? '',
      dateGeneration: json['dateGeneration'] ?? '',
      idReservation: json['idReservation'] ?? 0,
      idClient: json['idClient'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      urlBillet: json['urlBillet'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qrCode': qrCode,
      'dateGeneration': dateGeneration,
      'idReservation': idReservation,
      'idClient': idClient,
      'idSociete': idSociete,
      'urlBillet': urlBillet,
    };
  }
}
