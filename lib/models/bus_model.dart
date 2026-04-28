class Bus {
  final int idBus;
  final String marques;
  final int numeroBus;
  final int idTypeBus;
  final String? libelleTypeBus;
  final int nombreSiege;
  final int idSociete;
  final String numeroDePlaque;
  final String photo;
  final bool statut;
  final String dateCreation;
  final String? dateModification;
  final String nomSociete;

  Bus({
    required this.idBus,
    required this.marques,
    required this.numeroBus,
    required this.idTypeBus,
    this.libelleTypeBus,
    required this.nombreSiege,
    required this.idSociete,
    required this.numeroDePlaque,
    required this.photo,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
    required this.nomSociete,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      idBus: json['idBus'] ?? 0,
      marques: json['marques'] ?? '',
      numeroBus: json['numeroBus'] ?? 0,
      idTypeBus: json['idTypeBus'] ?? 0,
      libelleTypeBus: json['libelleTypeBus'],
      nombreSiege: json['nombreSiege'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      numeroDePlaque: json['numeroDePlaque'] ?? '',
      photo: json['photo'] ?? '',
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
      nomSociete: json['nomSociete'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idBus': idBus,
      'marques': marques,
      'numeroBus': numeroBus,
      'idTypeBus': idTypeBus,
      'libelleTypeBus': libelleTypeBus,
      'nombreSiege': nombreSiege,
      'idSociete': idSociete,
      'numeroDePlaque': numeroDePlaque,
      'photo': photo,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
      'nomSociete': nomSociete,
    };
  }

  // Getters pour un accès facile aux informations
  String get marque => marques;
  int get numero => numeroBus;
  String? get typeBus => libelleTypeBus;
  int get nombreSieges => nombreSiege;
  String get plaque => numeroDePlaque;
  String get societe => nomSociete;
  bool get estActif => statut;
}
