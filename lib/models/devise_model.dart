class Devise {
  final String codeDevise;
  final String? libelle;
  final bool statut;

  Devise({
    required this.codeDevise,
    this.libelle,
    required this.statut,
  });

  factory Devise.fromJson(Map<String, dynamic> json) {
    return Devise(
      codeDevise: (json['codeDevise'] ?? '').toString(),
      libelle: json['libelle']?.toString(),
      statut: json['statut'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeDevise': codeDevise,
      'libelle': libelle,
      'statut': statut,
    };
  }
}

class TauxChange {
  final int idSociete;
  final String codeDeviseSource;
  final String codeDeviseCible;
  final double taux;
  final String? dateEffet;

  TauxChange({
    required this.idSociete,
    required this.codeDeviseSource,
    required this.codeDeviseCible,
    required this.taux,
    this.dateEffet,
  });

  factory TauxChange.fromJson(Map<String, dynamic> json) {
    return TauxChange(
      idSociete: json['idSociete'] ?? 0,
      codeDeviseSource: (json['codeDeviseSource'] ?? '').toString(),
      codeDeviseCible: (json['codeDeviseCible'] ?? '').toString(),
      taux: (json['taux'] ?? 0).toDouble(),
      dateEffet: json['dateEffet']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSociete': idSociete,
      'codeDeviseSource': codeDeviseSource,
      'codeDeviseCible': codeDeviseCible,
      'taux': taux,
      'dateEffet': dateEffet,
    };
  }
}

class ConversionPreview {
  final int idSociete;
  final String codeDeviseSource;
  final String codeDevisePrincipale;
  final String datePaiement;
  final double taux;
  final double montantSource;
  final double montantConverti;

  ConversionPreview({
    required this.idSociete,
    required this.codeDeviseSource,
    required this.codeDevisePrincipale,
    required this.datePaiement,
    required this.taux,
    required this.montantSource,
    required this.montantConverti,
  });

  factory ConversionPreview.fromJson(Map<String, dynamic> json) {
    return ConversionPreview(
      idSociete: json['idSociete'] ?? 0,
      codeDeviseSource: (json['codeDeviseSource'] ?? '').toString(),
      codeDevisePrincipale: (json['codeDevisePrincipale'] ?? '').toString(),
      datePaiement: (json['datePaiement'] ?? '').toString(),
      taux: (json['taux'] ?? 0).toDouble(),
      montantSource: (json['montantSource'] ?? 0).toDouble(),
      montantConverti: (json['montantConverti'] ?? 0).toDouble(),
    );
  }
}
