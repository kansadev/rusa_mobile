import 'package:rusa/models/reservation_with_paiement_response.dart';

/// Réponse de `GET /api/Billet/{qrCode}/check`
class BilletCheckResponse {
  final int idBillet;
  final bool isUsed;
  final String? statut;
  final String? message;
  final bool embarquementAutorise;
  final String? statutReservation;
  final int idReservation;
  final DateTime? dateDepartVoyage;
  final HeureVoyage? heureDepartVoyage;

  BilletCheckResponse({
    required this.idBillet,
    required this.isUsed,
    this.statut,
    this.message,
    required this.embarquementAutorise,
    this.statutReservation,
    required this.idReservation,
    this.dateDepartVoyage,
    this.heureDepartVoyage,
  });

  factory BilletCheckResponse.fromJson(Map<String, dynamic> json) {
    HeureVoyage? heure;
    final h = json['heureDepartVoyage'];
    if (h is Map<String, dynamic>) {
      heure = HeureVoyage.fromJson(h);
    } else if (h is String && h.trim().isNotEmpty) {
      final parsed = _parseHeureString(h);
      if (parsed != null) {
        heure = parsed;
      }
    }

    DateTime? dateDepart;
    final d = json['dateDepartVoyage'];
    if (d != null) {
      if (d is String && d.isNotEmpty) {
        dateDepart = DateTime.tryParse(d);
      }
    }

    return BilletCheckResponse(
      idBillet: json['idBillet'] ?? 0,
      isUsed: json['isUsed'] == true,
      statut: json['statut']?.toString(),
      message: json['message']?.toString(),
      embarquementAutorise: json['embarquementAutorise'] == true,
      statutReservation: json['statutReservation']?.toString(),
      idReservation: json['idReservation'] ?? 0,
      dateDepartVoyage: dateDepart,
      heureDepartVoyage: heure,
    );
  }

  /// Moment de départ combiné (date + heure locale si fournie).
  DateTime? get momentDepart {
    final raw = dateDepartVoyage;
    if (raw == null) return null;
    final h = heureDepartVoyage;
    if (h != null &&
        (h.hours != 0 || h.minutes != 0 || h.seconds != 0)) {
      return DateTime(
        raw.year,
        raw.month,
        raw.day,
        h.hours,
        h.minutes,
        h.seconds,
      );
    }
    return raw.isUtc ? raw.toLocal() : raw;
  }

  bool get voyageDejaPasse {
    final m = momentDepart;
    if (m == null) return false;
    return m.isBefore(DateTime.now());
  }

  /// Le billet est expiré (validité dépassée) d'après le backend ou la date.
  bool get estExpire {
    final s = statut?.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '') ?? '';
    if (s.contains('expir')) return true;
    return voyageDejaPasse;
  }

  /// Le billet peut être réaffecté : expiré et jamais utilisé.
  bool get peutEtreReaffecte => estExpire && !isUsed;
}

HeureVoyage? _parseHeureString(String value) {
  final raw = value.trim();
  final match = RegExp(r'^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$').firstMatch(raw);
  if (match == null) return null;

  final hours = int.tryParse(match.group(1) ?? '');
  final minutes = int.tryParse(match.group(2) ?? '');
  final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
  if (hours == null || minutes == null) return null;

  final valid =
      hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59 && seconds >= 0 && seconds <= 59;
  if (!valid) return null;

  final totalSeconds = hours * 3600 + minutes * 60 + seconds;
  final totalMinutes = totalSeconds / 60.0;
  final totalHours = totalMinutes / 60.0;
  final totalDays = totalHours / 24.0;

  return HeureVoyage(
    ticks: totalSeconds * 10000000,
    days: 0,
    hours: hours,
    milliseconds: 0,
    minutes: minutes,
    seconds: seconds,
    totalDays: totalDays,
    totalHours: totalHours,
    totalMilliseconds: totalSeconds * 1000.0,
    totalMinutes: totalMinutes,
    totalSeconds: totalSeconds.toDouble(),
  );
}

/// Résultat de l'appel `POST .../billet/{idBillet}/reaffecter`.
class ReaffectationResult {
  final bool success;
  final String message;
  final int? statusCode;

  const ReaffectationResult({
    required this.success,
    required this.message,
    this.statusCode,
  });
}

/// Résultat de l'appel API check (succès HTTP + corps, ou erreur).
class BilletCheckApiResult {
  final bool success;
  final BilletCheckResponse? data;
  final String? errorMessage;
  final int? statusCode;

  const BilletCheckApiResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });
}
