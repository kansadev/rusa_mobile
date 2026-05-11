class ReservationWithPassengersAndPaiementRequest {
  final ReservationWithPassengersData reservation;
  final PaiementWithSiteData paiement;

  ReservationWithPassengersAndPaiementRequest({
    required this.reservation,
    required this.paiement,
  });

  Map<String, dynamic> toJson() {
    return {'reservation': reservation.toJson(), 'paiement': paiement.toJson()};
  }
}

class ReservationWithPassengersData {
  final int idVoyage;
  final int idClient;
  final int nombreDePlace;
  final int idUtilisateur;
  final int idSociete;
  final int idSite;
  final List<ReservationPassengerData> passagers;

  ReservationWithPassengersData({
    required this.idVoyage,
    required this.idClient,
    required this.nombreDePlace,
    required this.idUtilisateur,
    required this.idSociete,
    required this.idSite,
    required this.passagers,
  });

  Map<String, dynamic> toJson() {
    return {
      'idVoyage': idVoyage,
      'idClient': idClient,
      'nombreDePlace': nombreDePlace,
      'idUtilisateur': idUtilisateur,
      'idSociete': idSociete,
      'idSite': idSite,
      'passagers': passagers.map((p) => p.toJson()).toList(),
    };
  }
}

/// Une entrée = **un** passager avec **sa** catégorie de siège (`idCategorieSiege` peut différer pour chaque ligne).
class ReservationPassengerData {
  /// Renseigné seulement pour le **titulaire** (client connecté). Les autres passagers : laisser `null` (clé absente du JSON).
  final int? idClient;

  /// Catégorie de siège pour ce passager uniquement (contrat API : une valeur par objet `passagers[]`).
  final int idCategorieSiege;
  final String nomComplet;
  final String telephone;
  final String? email;
  final String documentType;
  final String documentNumero;
  final String genre;

  ReservationPassengerData({
    this.idClient,
    required this.idCategorieSiege,
    required this.nomComplet,
    required this.telephone,
    this.email,
    this.documentType = '',
    this.documentNumero = '',
    this.genre = '',
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'idCategorieSiege': idCategorieSiege,
      'nomComplet': nomComplet,
      'telephone': telephone,
      'email': email,
      'documentType': documentType,
      'documentNumero': documentNumero,
      'genre': genre,
    };
    if (idClient != null) {
      m['idClient'] = idClient;
    }
    return m;
  }
}

class PaiementWithSiteData {
  final double montantAPaye;
  final double montantPaye;
  final String methodePaiement;
  final String referenceTransaction;
  final int idUtilisateur;
  final int idSociete;
  final int idSite;

  PaiementWithSiteData({
    required this.montantAPaye,
    required this.montantPaye,
    required this.methodePaiement,
    String? referenceTransaction,
    required this.idUtilisateur,
    required this.idSociete,
    required this.idSite,
  }) : referenceTransaction =
           (referenceTransaction != null &&
               referenceTransaction.trim().isNotEmpty)
           ? referenceTransaction.trim()
           : 'TXN-${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() {
    return {
      'montantAPaye': montantAPaye,
      'montantPaye': montantPaye,
      'methodePaiement': methodePaiement,
      'referenceTransaction': referenceTransaction,
      'idUtilisateur': idUtilisateur,
      'idSociete': idSociete,
      'idSite': idSite,
    };
  }
}
