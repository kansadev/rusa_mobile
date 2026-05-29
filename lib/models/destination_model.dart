class Destination {
  final int idDestination;
  final String villeDepart;
  final String villeArrivee;
  final double montant;
  final String? jourDepart;
  final bool statut;
  final String dateCreation;
  final String? dateModification;
  final int idSociete;
  final String nomSociete;
  final String? deviseSociete;

  Destination({
    required this.idDestination,
    required this.villeDepart,
    required this.villeArrivee,
    required this.montant,
    this.jourDepart,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
    required this.idSociete,
    required this.nomSociete,
    required this.deviseSociete,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      idDestination: json['idDestination'] ?? 0,
      villeDepart: json['villeDepart'] ?? '',
      villeArrivee: json['villeArrivee'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      jourDepart: json['jourDepart']?.toString(),
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
      idSociete: json['idSociete'] ?? 0,
      nomSociete: json['nomSociete'] ?? '',
      deviseSociete: json['deviseSociete'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idDestination': idDestination,
      'villeDepart': villeDepart,
      'villeArrivee': villeArrivee,
      'montant': montant,
      if (jourDepart != null) 'jourDepart': jourDepart,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
      'idSociete': idSociete,
      'nomSociete': nomSociete,
      'deviseSociete': deviseSociete,
    };
  }
}

class DestinationResponse {
  final List<Destination> data;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  DestinationResponse({
    required this.data,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory DestinationResponse.fromJson(Map<String, dynamic> json) {
    return DestinationResponse(
      data: (json['data'] as List?)
              ?.map((item) => Destination.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}
