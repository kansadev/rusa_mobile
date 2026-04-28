class Voyage {
  final int id;
  final String dateDepart;
  final String heureDepart;
  final double prix;
  final int idBus;
  final int idDestination;
  final int idSociete;
  final bool statut;
  final String dateCreation;
  final String? dateModification;
  final String numeroBus;
  final String libelleTypeBus;
  final String? nomSociete;
  final String villeDepart;
  final String villeArrivee;

  Voyage({
    required this.id,
    required this.dateDepart,
    required this.heureDepart,
    required this.prix,
    required this.idBus,
    required this.idDestination,
    required this.idSociete,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
    required this.numeroBus,
    required this.libelleTypeBus,
    this.nomSociete,
    required this.villeDepart,
    required this.villeArrivee,
  });

  factory Voyage.fromJson(Map<String, dynamic> json) {
    String heureDepart = '';
    if (json['heureDepart'] != null) {
      if (json['heureDepart'] is String) {
        heureDepart = json['heureDepart'];
      } else if (json['heureDepart'] is Map) {
        // L'API renvoie un objet HeureVoyage
        final h = json['heureDepart'];
        final hours = h['hours'] ?? 0;
        final minutes = h['minutes'] ?? 0;
        heureDepart = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
      }
    }
    return Voyage(
      id: json['id'] ?? 0,
      dateDepart: json['dateDepart'] ?? '',
      heureDepart: heureDepart,
      prix: (json['prix'] ?? 0).toDouble(),
      idBus: json['idBus'] ?? 0,
      idDestination: json['idDestination'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
      numeroBus: json['numeroBus'] ?? '',
      libelleTypeBus: json['libelleTypeBus'] ?? '',
      nomSociete: json['nomSociete'],
      villeDepart: json['villeDepart'] ?? '',
      villeArrivee: json['villeArrivee'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateDepart': dateDepart,
      'heureDepart': heureDepart,
      'prix': prix,
      'idBus': idBus,
      'idDestination': idDestination,
      'idSociete': idSociete,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
      'numeroBus': numeroBus,
      'libelleTypeBus': libelleTypeBus,
      'nomSociete': nomSociete,
      'villeDepart': villeDepart,
      'villeArrivee': villeArrivee,
    };
  }

  // Getters pour un accès facile aux informations
  String get route => '$villeDepart - $villeArrivee';
  String get heure => heureDepart.substring(0, 5); // Format HH:mm
  String get date => dateDepart.substring(0, 10); // Format YYYY-MM-DD
  String get typeBus => libelleTypeBus;
  String get busNumero => numeroBus;
  bool get estActif => statut;
  String get prixFormatted => '${prix.toStringAsFixed(0)} FC';

  // Méthode pour formater la date et l'heure
  String get dateTimeFormatted {
    final dateParts = date.split('-');
    final timeParts = heure.split(':');
    return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} à ${timeParts[0]}:${timeParts[1]}';
  }
}
