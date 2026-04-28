class ReservationModel {
  final int idReservation;
  final int idVoyage;
  final int idClient;
  final String statutReservation;
  final bool statut;
  final String dateReservation;
  final VoyageInfo voyage;
  final ClientInfo client;
  final PaiementInfo paiement;

  ReservationModel({
    required this.idReservation,
    required this.idVoyage,
    required this.idClient,
    required this.statutReservation,
    required this.statut,
    required this.dateReservation,
    required this.voyage,
    required this.client,
    required this.paiement,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      idReservation: json['idReservation'],
      idVoyage: json['idVoyage'],
      idClient: json['idClient'],
      statutReservation: json['statutReservation'],
      statut: json['statut'],
      dateReservation: json['dateReservation'],
      voyage: VoyageInfo.fromJson(json['voyage']),
      client: ClientInfo.fromJson(json['client']),
      paiement: PaiementInfo.fromJson(json['paiement']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idReservation': idReservation,
      'idVoyage': idVoyage,
      'idClient': idClient,
      'statutReservation': statutReservation,
      'statut': statut,
      'dateReservation': dateReservation,
      'voyage': voyage.toJson(),
      'client': client.toJson(),
      'paiement': paiement.toJson(),
    };
  }
}

class VoyageInfo {
  final int id;
  final String dateDepart;
  final double prix;

  VoyageInfo({required this.id, required this.dateDepart, required this.prix});

  factory VoyageInfo.fromJson(Map<String, dynamic> json) {
    return VoyageInfo(
      id: json['id'],
      dateDepart: json['dateDepart'],
      prix: json['prix'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'dateDepart': dateDepart, 'prix': prix};
  }
}

class ClientInfo {
  final int idClient;
  final String nom;
  final String email;

  ClientInfo({required this.idClient, required this.nom, required this.email});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      idClient: json['idClient'],
      nom: json['nom'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idClient': idClient, 'nom': nom, 'email': email};
  }
}

class PaiementInfo {
  final int idPaiement;
  final double montant;
  final String methodePaiement;
  final bool statut;

  PaiementInfo({
    required this.idPaiement,
    required this.montant,
    required this.methodePaiement,
    required this.statut,
  });

  factory PaiementInfo.fromJson(Map<String, dynamic> json) {
    return PaiementInfo(
      idPaiement: json['idPaiement'],
      montant: json['montant'].toDouble(),
      methodePaiement: json['methodePaiement'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPaiement': idPaiement,
      'montant': montant,
      'methodePaiement': methodePaiement,
      'statut': statut,
    };
  }
}
