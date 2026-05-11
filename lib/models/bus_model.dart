class Bus {
  final int idVehicule;
  final String marques;
  final String aliasVehicule;
  final int idTypeVehicule;
  final String? libelleTypeVehicule;
  final int nombreSiege;
  final int idSociete;
  final String nomSociete;
  final String numeroDePlaque;
  final String photo;
  final bool statut;
  final String dateCreation;
  final String? dateModification;

  Bus({
    required this.idVehicule,
    required this.marques,
    required this.aliasVehicule,
    required this.idTypeVehicule,
    this.libelleTypeVehicule,
    required this.nombreSiege,
    required this.idSociete,
    required this.nomSociete,
    required this.numeroDePlaque,
    required this.photo,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      idVehicule: json['idVehicule'] ?? json['idBus'] ?? 0,
      marques: json['marques'] ?? '',
      aliasVehicule: json['aliasVehicule'] ?? '',
      idTypeVehicule: json['idTypeVehicule'] ?? json['idTypeBus'] ?? 0,
      libelleTypeVehicule: json['libelleTypeVehicule'] ?? json['libelleTypeBus'],
      nombreSiege: json['nombreSiege'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      nomSociete: json['nomSociete'] ?? '',
      numeroDePlaque: json['numeroDePlaque'] ?? '',
      photo: json['photo'] ?? '',
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idVehicule': idVehicule,
      'idBus': idVehicule,
      'marques': marques,
      'aliasVehicule': aliasVehicule,
      'idTypeVehicule': idTypeVehicule,
      'libelleTypeVehicule': libelleTypeVehicule,
      'nombreSiege': nombreSiege,
      'idSociete': idSociete,
      'nomSociete': nomSociete,
      'numeroDePlaque': numeroDePlaque,
      'photo': photo,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
    };
  }

  // Getters de compatibilite pour l'UI existante
  int get idBus => idVehicule;
  int get numeroBus => idVehicule;
  int get idTypeBus => idTypeVehicule;
  String? get libelleTypeBus => libelleTypeVehicule;
  String get marque => marques;
  int get numero => idVehicule;
  String? get typeBus => libelleTypeVehicule;
  int get nombreSieges => nombreSiege;
  String get plaque => numeroDePlaque;
  String get societe => nomSociete;
  bool get estActif => statut;
}
