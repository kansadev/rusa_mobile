/// Réponse de `GET /api/CaissierDashboard/rapport-caisse`.
class CaissierRapportCaisse {
  final int idSociete;
  final int idUtilisateur;
  final String modePeriode;
  final DateTime? periodeDebut;
  final DateTime? periodeFin;
  final String codeDevisePrincipale;
  final Map<String, dynamic> synthese;
  final Map<String, dynamic> especes;
  final Map<String, dynamic> electronique;
  final List<Map<String, dynamic>> parDevise;

  const CaissierRapportCaisse({
    required this.idSociete,
    required this.idUtilisateur,
    required this.modePeriode,
    this.periodeDebut,
    this.periodeFin,
    required this.codeDevisePrincipale,
    required this.synthese,
    required this.especes,
    required this.electronique,
    required this.parDevise,
  });

  factory CaissierRapportCaisse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    Map<String, dynamic> mapOf(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return const {};
    }

    final rawParDevise = json['parDevise'];
    final List<Map<String, dynamic>> devises = [];
    if (rawParDevise is List) {
      for (final item in rawParDevise) {
        if (item is Map) {
          devises.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return CaissierRapportCaisse(
      idSociete: _asInt(json['idSociete']),
      idUtilisateur: _asInt(json['idUtilisateur']),
      modePeriode: json['modePeriode']?.toString() ?? '',
      periodeDebut: parseDate(json['periodeDebut']),
      periodeFin: parseDate(json['periodeFin']),
      codeDevisePrincipale:
          json['codeDevisePrincipale']?.toString().trim().isNotEmpty == true
          ? json['codeDevisePrincipale'].toString()
          : 'FC',
      synthese: mapOf(json['synthese']),
      especes: mapOf(json['especes']),
      electronique: mapOf(json['electronique']),
      parDevise: devises,
    );
  }

  Map<String, dynamic>? get detailElectronique {
    final detail = electronique['detail'];
    if (detail is Map<String, dynamic>) return detail;
    if (detail is Map) return Map<String, dynamic>.from(detail);
    return null;
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
