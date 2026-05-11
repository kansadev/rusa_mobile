class Voyage {
  final int id;
  final String dateDepart;
  final String heureDepart;
  final double prix;
  final String? codeDevisePrix;
  final String? codeDevisePrincipale;
  final double? tauxVersDevisePrincipale;
  final double? prixDevisePrincipale;
  final int idBus;
  final int idDestination;
  final int idSociete;
  final int idSite;
  final bool statut;
  final String dateCreation;
  final String? dateModification;
  final String numeroBus;
  final String libelleTypeBus;
  final String? nomSociete;
  final String? nomSite;
  final String villeDepart;
  final String villeArrivee;
  final List<VoyageTarif> tarifs;

  Voyage({
    required this.id,
    required this.dateDepart,
    required this.heureDepart,
    required this.prix,
    this.codeDevisePrix,
    this.codeDevisePrincipale,
    this.tauxVersDevisePrincipale,
    this.prixDevisePrincipale,
    required this.idBus,
    required this.idDestination,
    required this.idSociete,
    this.idSite = 0,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
    required this.numeroBus,
    required this.libelleTypeBus,
    this.nomSociete,
    this.nomSite,
    required this.villeDepart,
    required this.villeArrivee,
    this.tarifs = const [],
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
      codeDevisePrix: json['codeDevisePrix']?.toString(),
      codeDevisePrincipale: json['codeDevisePrincipale']?.toString(),
      tauxVersDevisePrincipale: json['tauxVersDevisePrincipale'] != null
          ? (json['tauxVersDevisePrincipale']).toDouble()
          : null,
      prixDevisePrincipale: json['prixDevisePrincipale'] != null
          ? (json['prixDevisePrincipale']).toDouble()
          : null,
      idBus: json['idVehicule'] ?? json['idBus'] ?? 0,
      idDestination: json['idDestination'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      idSite: json['idSite'] ?? 0,
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      dateModification: json['dateModification'],
      numeroBus: json['numeroBus'] ?? json['aliasVehicule'] ?? '',
      libelleTypeBus: json['libelleTypeBus'] ?? json['libelleTypeVehicule'] ?? '',
      nomSociete: json['nomSociete'],
      nomSite: json['nomSite']?.toString(),
      villeDepart: json['villeDepart'] ?? '',
      villeArrivee: json['villeArrivee'] ?? '',
      tarifs: (json['tarifs'] as List?)
              ?.map((e) => VoyageTarif.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateDepart': dateDepart,
      'heureDepart': heureDepart,
      'prix': prix,
      'codeDevisePrix': codeDevisePrix,
      'codeDevisePrincipale': codeDevisePrincipale,
      'tauxVersDevisePrincipale': tauxVersDevisePrincipale,
      'prixDevisePrincipale': prixDevisePrincipale,
      'idVehicule': idBus,
      'idBus': idBus,
      'idDestination': idDestination,
      'idSociete': idSociete,
      'idSite': idSite,
      'statut': statut,
      'dateCreation': dateCreation,
      'dateModification': dateModification,
      'numeroBus': numeroBus,
      'libelleTypeBus': libelleTypeBus,
      'nomSociete': nomSociete,
      'nomSite': nomSite,
      'villeDepart': villeDepart,
      'villeArrivee': villeArrivee,
      'tarifs': tarifs.map((t) => t.toJson()).toList(),
    };
  }

  // Getters pour un accès facile aux informations
  String get route => '$villeDepart - $villeArrivee';
  String get heure => heureDepart.length >= 5 ? heureDepart.substring(0, 5) : '--:--';
  String get date => dateDepart.substring(0, 10); // Format YYYY-MM-DD
  String get typeBus => libelleTypeBus;
  String get busNumero => numeroBus;
  int get idVehicule => idBus;
  bool get estActif => statut;
  String get prixFormatted => '${prix.toStringAsFixed(0)} FC';

  // Méthode pour formater la date et l'heure
  String get dateTimeFormatted {
    final dateParts = date.split('-');
    final timeParts = heure.split(':');
    return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} à ${timeParts[0]}:${timeParts[1]}';
  }
}

class VoyageTarif {
  final int idCategorieSiege;
  final String libelle;
  final double prix;

  VoyageTarif({
    required this.idCategorieSiege,
    required this.libelle,
    required this.prix,
  });

  factory VoyageTarif.fromJson(Map<String, dynamic> json) {
    return VoyageTarif(
      idCategorieSiege: json['idCategorieSiege'] ?? 0,
      libelle: (json['libelle'] ?? '').toString(),
      prix: (json['prix'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCategorieSiege': idCategorieSiege,
      'libelle': libelle,
      'prix': prix,
    };
  }
}
