/// Passager lié à un voyage (liste caissier).
class VoyagePassager {
  final int idReservationPassenger;
  final int idReservation;
  final int idBillet;
  final String nomComplet;
  final String telephone;
  final String? email;
  final String? codeSiege;
  final String? categorieSiege;
  final bool estEmbarque;

  VoyagePassager({
    this.idReservationPassenger = 0,
    this.idReservation = 0,
    this.idBillet = 0,
    required this.nomComplet,
    this.telephone = '',
    this.email,
    this.codeSiege,
    this.categorieSiege,
    this.estEmbarque = false,
  });

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'oui' || s == 'yes';
  }

  factory VoyagePassager.fromJson(Map<String, dynamic> json) {
    final nom = _str(
      json['nomComplet'] ??
          json['nomPassager'] ??
          json['nomClient'] ??
          [
            json['prenomClient'],
            json['nomClient'],
          ].where((e) => _str(e).isNotEmpty).join(' '),
    );
    return VoyagePassager(
      idReservationPassenger: _int(
        json['idReservationPassenger'] ?? json['idReservationPassager'],
      ),
      idReservation: _int(json['idReservation']),
      idBillet: _int(json['idBillet'] ?? json['idBilletEmis']),
      nomComplet: nom.isEmpty ? 'Passager' : nom,
      telephone: _str(
        json['telephone'] ?? json['telephoneClient'] ?? json['phone'],
      ),
      email: _str(json['email'] ?? json['emailClient']).isEmpty
          ? null
          : _str(json['email'] ?? json['emailClient']),
      codeSiege: _str(json['codeSiege']).isEmpty ? null : _str(json['codeSiege']),
      categorieSiege: _str(
        json['categorieSiege'] ??
            json['libelleCategorieSiege'] ??
            json['codeCategorieSiege'],
      ).isEmpty
          ? null
          : _str(
              json['categorieSiege'] ??
                  json['libelleCategorieSiege'] ??
                  json['codeCategorieSiege'],
            ),
      estEmbarque: _bool(
        json['estEmbarque'] ??
            json['embarque'] ??
            json['isEmbarque'] ??
            json['isUsed'],
      ),
    );
  }
}
