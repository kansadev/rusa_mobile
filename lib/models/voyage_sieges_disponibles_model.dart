/// Réponse `GET /api/Voyage/{id}/sieges-disponibles`.
class VoyageSiegesDisponibles {
  final int idVoyage;
  final int nombreSiegesDisponibles;
  final List<CategorieSiegesDisponiblesDetail> repartitionCategorieSieges;

  VoyageSiegesDisponibles({
    required this.idVoyage,
    required this.nombreSiegesDisponibles,
    required this.repartitionCategorieSieges,
  });

  factory VoyageSiegesDisponibles.fromJson(Map<String, dynamic> json) {
    return VoyageSiegesDisponibles(
      idVoyage: _asInt(json['idVoyage']),
      nombreSiegesDisponibles: _asInt(json['nombreSiegesDisponibles']),
      repartitionCategorieSieges:
          (json['repartitionCategorieSieges'] as List?)
                  ?.map(
                    (e) => CategorieSiegesDisponiblesDetail.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList() ??
              const [],
    );
  }
}

class CategorieSiegesDisponiblesDetail {
  final int idCategorieSiege;
  final String codeCategorieSiege;
  final String libelle;
  final int nombreSiege;
  final List<SiegeDisponible> sieges;

  CategorieSiegesDisponiblesDetail({
    required this.idCategorieSiege,
    required this.codeCategorieSiege,
    required this.libelle,
    required this.nombreSiege,
    required this.sieges,
  });

  factory CategorieSiegesDisponiblesDetail.fromJson(Map<String, dynamic> json) {
    return CategorieSiegesDisponiblesDetail(
      idCategorieSiege: _asInt(json['idCategorieSiege']),
      codeCategorieSiege: (json['codeCategorieSiege'] ?? '').toString(),
      libelle: (json['libelle'] ?? '').toString(),
      nombreSiege: _asInt(json['nombreSiege']),
      sieges: (json['sieges'] as List?)
              ?.map(
                (e) => SiegeDisponible.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  String get label {
    if (libelle.trim().isNotEmpty) return libelle;
    if (codeCategorieSiege.trim().isNotEmpty) return codeCategorieSiege;
    return 'Catégorie';
  }
}

class SiegeDisponible {
  final int idSiege;
  final int numeroOrdre;
  final String codeSiege;

  SiegeDisponible({
    required this.idSiege,
    required this.numeroOrdre,
    required this.codeSiege,
  });

  factory SiegeDisponible.fromJson(Map<String, dynamic> json) {
    return SiegeDisponible(
      idSiege: _asInt(json['idSiege']),
      numeroOrdre: _asInt(json['numeroOrdre']),
      codeSiege: (json['codeSiege'] ?? '').toString(),
    );
  }

  String get displayLabel =>
      codeSiege.trim().isNotEmpty ? codeSiege : '$numeroOrdre';
}

/// Entrée `GET /api/Voyage/{id}/sieges-indisponibles`.
class SiegeIndisponible {
  final int idSiege;
  final int numeroOrdre;
  final String codeSiege;
  final int idVoyageSeatAllocation;
  final int idReservationPassenger;
  final String nomPassager;

  SiegeIndisponible({
    required this.idSiege,
    required this.numeroOrdre,
    required this.codeSiege,
    required this.idVoyageSeatAllocation,
    required this.idReservationPassenger,
    required this.nomPassager,
  });

  factory SiegeIndisponible.fromJson(Map<String, dynamic> json) {
    return SiegeIndisponible(
      idSiege: _asInt(json['idSiege']),
      numeroOrdre: _asInt(json['numeroOrdre']),
      codeSiege: (json['codeSiege'] ?? '').toString(),
      idVoyageSeatAllocation: _asInt(json['idVoyageSeatAllocation']),
      idReservationPassenger: _asInt(json['idReservationPassenger']),
      nomPassager: (json['nomPassager'] ?? '').toString(),
    );
  }

  String get displayLabel =>
      codeSiege.trim().isNotEmpty ? codeSiege : '$numeroOrdre';
}

int _asInt(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
