class CategorieSiege {
  final int idCategorieSiege;
  final int idSociete;
  final String codeCategorieSiege;
  final String libelle;
  final bool statut;

  CategorieSiege({
    required this.idCategorieSiege,
    required this.idSociete,
    required this.codeCategorieSiege,
    required this.libelle,
    required this.statut,
  });

  factory CategorieSiege.fromJson(Map<String, dynamic> json) {
    return CategorieSiege(
      idCategorieSiege: json['idCategorieSiege'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      codeCategorieSiege: (json['codeCategorieSiege'] ?? '').toString(),
      libelle: (json['libelle'] ?? '').toString(),
      statut: json['statut'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCategorieSiege': idCategorieSiege,
      'idSociete': idSociete,
      'codeCategorieSiege': codeCategorieSiege,
      'libelle': libelle,
      'statut': statut,
    };
  }
}
