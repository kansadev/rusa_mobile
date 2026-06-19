/// Période pour `GET /api/Voyage/paged` (`periode` query).
enum VoyagePeriode {
  jour('Jour', "Aujourd'hui"),
  hebdomadaire('Hebdomadaire', 'Cette sem.'),
  mensuel('Mensuel', 'Ce mois');

  const VoyagePeriode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

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
  final double montAddPaieElectronique;
  final String? codeDeviseMontAddPaieElectronique;
  final List<VoyageTarif> tarifs;
  final List<CategorieSiegeDisponible> repartitionCategorieSiegesDisponible;
  final List<PhotoVehicule> photosVehicules;

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
    this.montAddPaieElectronique = 0,
    this.codeDeviseMontAddPaieElectronique,
    this.tarifs = const [],
    this.repartitionCategorieSiegesDisponible = const [],
    this.photosVehicules = const [],
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
      montAddPaieElectronique:
          (json['montAddPaieElectronique'] ?? 0).toDouble(),
      codeDeviseMontAddPaieElectronique:
          json['codeDeviseMontAddPaieElectronique']?.toString(),
      tarifs: (json['tarifs'] as List?)
              ?.map((e) => VoyageTarif.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      repartitionCategorieSiegesDisponible:
          (json['repartitionCategorieSiegesDisponible'] as List?)
                  ?.map(
                    (e) => CategorieSiegeDisponible.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList() ??
              const [],
      photosVehicules: (json['photosVehicules'] as List?)
              ?.map(
                (e) => PhotoVehicule.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
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
      'montAddPaieElectronique': montAddPaieElectronique,
      'codeDeviseMontAddPaieElectronique': codeDeviseMontAddPaieElectronique,
      'tarifs': tarifs.map((t) => t.toJson()).toList(),
      'repartitionCategorieSiegesDisponible':
          repartitionCategorieSiegesDisponible.map((r) => r.toJson()).toList(),
      'photosVehicules': photosVehicules.map((p) => p.toJson()).toList(),
    };
  }

  int get placesDisponiblesTotal {
    if (repartitionCategorieSiegesDisponible.isEmpty) return 0;
    return repartitionCategorieSiegesDisponible
        .map((r) => r.nombreSiege)
        .fold(0, (a, b) => a + b);
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

  /// Devise de la majoration paiement électronique (frais transaction / passager).
  String get deviseMajorationPaieElectronique {
    final m = codeDeviseMontAddPaieElectronique?.trim();
    if (m != null && m.isNotEmpty) return m;
    final p = codeDevisePrix?.trim();
    if (p != null && p.isNotEmpty) return p;
    final principale = codeDevisePrincipale?.trim();
    if (principale != null && principale.isNotEmpty) return principale;
    return 'FC';
  }

  bool get hasMajorationPaieElectronique => montAddPaieElectronique > 0;

  /// Majoration totale = montant unitaire × nombre de passagers.
  double majorationPaieElectroniquePour(int nombrePassagers) {
    if (nombrePassagers <= 0 || montAddPaieElectronique <= 0) return 0;
    return montAddPaieElectronique * nombrePassagers;
  }

  // Méthode pour formater la date et l'heure
  String get dateTimeFormatted {
    final dateParts = date.split('-');
    final timeParts = heure.split(':');
    return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} à ${timeParts[0]}:${timeParts[1]}';
  }
}

/// Réponse paginée de `GET /api/Voyage/paged`.
class VoyagePagedResponse {
  final List<Voyage> data;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  VoyagePagedResponse({
    required this.data,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory VoyagePagedResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final List<Voyage> rows = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          rows.add(Voyage.fromJson(item));
        } else if (item is Map) {
          rows.add(Voyage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    int asInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    return VoyagePagedResponse(
      data: rows,
      totalCount: asInt(json['totalCount'], 0),
      pageNumber: asInt(json['pageNumber'], 1),
      pageSize: asInt(json['pageSize'], 10),
      totalPages: asInt(json['totalPages'], 1),
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}

class CategorieSiegeDisponible {
  final int idCategorieSiege;
  final String codeCategorieSiege;
  final String libelle;
  final int nombreSiege;

  CategorieSiegeDisponible({
    required this.idCategorieSiege,
    required this.codeCategorieSiege,
    required this.libelle,
    required this.nombreSiege,
  });

  factory CategorieSiegeDisponible.fromJson(Map<String, dynamic> json) {
    return CategorieSiegeDisponible(
      idCategorieSiege: json['idCategorieSiege'] ?? 0,
      codeCategorieSiege: (json['codeCategorieSiege'] ?? '').toString(),
      libelle: (json['libelle'] ?? '').toString(),
      nombreSiege: json['nombreSiege'] is num
          ? (json['nombreSiege'] as num).toInt()
          : int.tryParse('${json['nombreSiege']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'idCategorieSiege': idCategorieSiege,
        'codeCategorieSiege': codeCategorieSiege,
        'libelle': libelle,
        'nombreSiege': nombreSiege,
      };
}

/// Photos véhicule renvoyées par `/api/Voyage/paged`.
class PhotoVehicule {
  final int idPhotoVehicule;
  final int idVehicule;
  final String photoBase64;
  final int ordre;
  final String originalFileName;
  final String typeMIME;
  final int fileSize;
  final bool statut;
  final String dateCreation;
  final String? dateModification;

  PhotoVehicule({
    required this.idPhotoVehicule,
    required this.idVehicule,
    required this.photoBase64,
    required this.ordre,
    required this.originalFileName,
    required this.typeMIME,
    required this.fileSize,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
  });

  factory PhotoVehicule.fromJson(Map<String, dynamic> json) {
    return PhotoVehicule(
      idPhotoVehicule: json['idPhotoVehicule'] ?? 0,
      idVehicule: json['idVehicule'] ?? 0,
      photoBase64: (json['photoBase64'] ?? '').toString(),
      ordre: json['ordre'] ?? 0,
      originalFileName: (json['originalFileName'] ?? '').toString(),
      typeMIME: (json['typeMIME'] ?? json['typeMime'] ?? '').toString(),
      fileSize: json['fileSize'] ?? 0,
      statut: json['statut'] ?? false,
      dateCreation: (json['dateCreation'] ?? '').toString(),
      dateModification: json['dateModification']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idPhotoVehicule': idPhotoVehicule,
        'idVehicule': idVehicule,
        'photoBase64': photoBase64,
        'ordre': ordre,
        'originalFileName': originalFileName,
        'typeMIME': typeMIME,
        'fileSize': fileSize,
        'statut': statut,
        'dateCreation': dateCreation,
        'dateModification': dateModification,
      };
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
