class ReservationWithPaiementRequest {
  final ReservationRequest reservation;
  final PaiementRequest paiement;

  ReservationWithPaiementRequest({
    required this.reservation,
    required this.paiement,
  });

  Map<String, dynamic> toJson() {
    return {'reservation': reservation.toJson(), 'paiement': paiement.toJson()};
  }
}

class ReservationRequest {
  final int idVoyage;
  final int idClient;
  final int nombreDePlace;
  final int idUtilisateur;
  final int idSociete;
  final String statutReservation;

  ReservationRequest({
    required this.idVoyage,
    required this.idClient,
    required this.nombreDePlace,
    required this.idUtilisateur,
    required this.idSociete,
    this.statutReservation = 'EN_ATTENTE',
  });

  Map<String, dynamic> toJson() {
    return {
      'idVoyage': idVoyage,
      'idClient': idClient,
      'nombreDePlace': nombreDePlace,
      'idUtilisateur': idUtilisateur,
      'idSociete': idSociete,
      'statutReservation': statutReservation,
    };
  }
}

class PaiementRequest {
  final double montantAPaye;
  final double montantPaye;
  final String methodePaiement;
  final String referenceTransaction;
  final int idUtilisateur;
  final int idSociete;

  PaiementRequest({
    required this.montantAPaye,
    required this.montantPaye,
    required this.methodePaiement,
    required this.referenceTransaction,
    required this.idUtilisateur,
    required this.idSociete,
  });

  Map<String, dynamic> toJson() {
    return {
      'montantAPaye': montantAPaye,
      'montantPaye': montantPaye,
      'methodePaiement': methodePaiement,
      'referenceTransaction': referenceTransaction,
      'idUtilisateur': idUtilisateur,
      'idSociete': idSociete,
    };
  }
}
