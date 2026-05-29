/// Ligne renvoyée par `GET /api/Voyage/passagers-embarques`.
class PassagerEmbarque {
  final int idEmbarquement;
  final DateTime? dateEmbarquementUtc;
  final int idBillet;
  final int idReservationPassenger;
  final int idReservation;
  final int idVoyage;
  final String nomComplet;
  final String telephone;
  final int idUtilisateurEnregistrement;

  PassagerEmbarque({
    required this.idEmbarquement,
    this.dateEmbarquementUtc,
    required this.idBillet,
    required this.idReservationPassenger,
    required this.idReservation,
    required this.idVoyage,
    required this.nomComplet,
    required this.telephone,
    required this.idUtilisateurEnregistrement,
  });

  /// Libellé principal (compatibilité écrans existants).
  String get titre {
    final n = nomComplet.trim();
    return n.isEmpty ? 'Passager' : n;
  }

  /// Détails secondaires (compatibilité écrans existants).
  String? get sousTitre {
    final t = telephone.trim();
    return t.isEmpty ? null : t;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static DateTime? _parseUtc(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory PassagerEmbarque.fromJson(Map<String, dynamic> json) {
    return PassagerEmbarque(
      idEmbarquement: _int(json['idEmbarquement']),
      dateEmbarquementUtc: _parseUtc(json['dateEmbarquementUtc']),
      idBillet: _int(json['idBillet']),
      idReservationPassenger: _int(json['idReservationPassenger']),
      idReservation: _int(json['idReservation']),
      idVoyage: _int(json['idVoyage']),
      nomComplet: _str(json['nomComplet']),
      telephone: _str(json['telephone']),
      idUtilisateurEnregistrement: _int(json['idUtilisateurEnregistrement']),
    );
  }
}
