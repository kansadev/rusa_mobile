class ReservationWithPaiementResponse {
  final ReservationData reservation;
  final PaiementData paiement;
  final BilletData? billet;
  /// Tous les billets (réservation multi-passagers). Si vide, utiliser [billet] seul.
  final List<BilletData> billets;
  final String transactionId;
  final String statut;
  final String message;
  final String dateCreation;

  ReservationWithPaiementResponse({
    required this.reservation,
    required this.paiement,
    this.billet,
    this.billets = const [],
    required this.transactionId,
    required this.statut,
    required this.message,
    required this.dateCreation,
  });

  factory ReservationWithPaiementResponse.fromJson(Map<String, dynamic> json) {
    final billet = json['billet'] != null
        ? BilletData.fromJson(json['billet'] as Map<String, dynamic>)
        : null;
    List<BilletData> billets;
    if (json['billets'] is List) {
      billets = (json['billets'] as List)
          .whereType<Map>()
          .map((e) => BilletData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (billet != null) {
      billets = [billet];
    } else {
      billets = const [];
    }
    return ReservationWithPaiementResponse(
      reservation: ReservationData.fromJson(json['reservation']),
      paiement: PaiementData.fromJson(json['paiement']),
      billet: billet ?? (billets.isNotEmpty ? billets.first : null),
      billets: billets,
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
      'billet': billet?.toJson(),
      'billets': billets.map((b) => b.toJson()).toList(),
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
  final String? dateModification;
  final String? nomUtilisateur;
  final String? emailUtilisateur;
  final String? nomClient;
  final String? prenomClient;
  final String? telephoneClient;
  final String? dateVoyage;
  final HeureVoyage? heureVoyage;
  final double? prixVoyage;
  final String? numeroBus;
  final String? villeDepart;
  final String? villeArrivee;

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
    this.dateModification,
    this.nomUtilisateur,
    this.emailUtilisateur,
    this.nomClient,
    this.prenomClient,
    this.telephoneClient,
    this.dateVoyage,
    this.heureVoyage,
    this.prixVoyage,
    this.numeroBus,
    this.villeDepart,
    this.villeArrivee,
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
      dateModification: json['dateModification'] as String?,
      nomUtilisateur: json['nomUtilisateur'] as String?,
      emailUtilisateur: json['emailUtilisateur'] as String?,
      nomClient: json['nomClient'] as String?,
      prenomClient: json['prenomClient'] as String?,
      telephoneClient: json['telephoneClient'] as String?,
      dateVoyage: json['dateVoyage'] as String?,
      heureVoyage: _parseHeureVoyage(json['heureVoyage']),
      prixVoyage: json['prixVoyage'] != null ? (json['prixVoyage']).toDouble() : null,
      numeroBus: json['numeroBus'] as String?,
      villeDepart: json['villeDepart'] as String?,
      villeArrivee: json['villeArrivee'] as String?,
    );
  }

  static HeureVoyage? _parseHeureVoyage(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return HeureVoyage(
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
      return null;
    }
    if (value is Map<String, dynamic>) {
      return HeureVoyage.fromJson(value);
    }
    return null;
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
      'heureVoyage': heureVoyage?.toJson(),
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
  /// Ligne passager (réservation multi-passagers) — requis pour `/embarquer`.
  final int idReservationPassenger;
  final bool isUsed;
  final String? nomPassager;
  final String? codeSiege;

  BilletData({
    required this.id,
    required this.qrCode,
    required this.dateGeneration,
    required this.idReservation,
    required this.idClient,
    required this.idSociete,
    required this.urlBillet,
    this.idReservationPassenger = 0,
    this.isUsed = false,
    this.nomPassager,
    this.codeSiege,
  });

  factory BilletData.fromJson(Map<String, dynamic> json) {
    return BilletData(
      id: json['idBillet'] ?? json['id'] ?? 0,
      qrCode: json['qrCode'] ?? '',
      dateGeneration: json['dateGeneration'] ?? '',
      idReservation: json['idReservation'] ?? 0,
      idClient: json['idClient'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      urlBillet: json['urlBillet'] ?? '',
      idReservationPassenger: json['idReservationPassenger'] ?? 0,
      isUsed: json['isUsed'] == true,
      nomPassager: json['nomPassager']?.toString(),
      codeSiege: json['codeSiege']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'idBillet': id,
      'qrCode': qrCode,
      'dateGeneration': dateGeneration,
      'idReservation': idReservation,
      'idClient': idClient,
      'idSociete': idSociete,
      'urlBillet': urlBillet,
      'idReservationPassenger': idReservationPassenger,
      'isUsed': isUsed,
    };
    if (nomPassager != null) m['nomPassager'] = nomPassager;
    if (codeSiege != null) m['codeSiege'] = codeSiege;
    return m;
  }
}

/// Résultat de `POST /api/Billet/societe/.../embarquer`
class EmbarquerBilletResult {
  final bool success;
  final String message;
  final BilletData? billet;

  const EmbarquerBilletResult({
    required this.success,
    required this.message,
    this.billet,
  });
}
