import 'package:rusa/models/voyage_model.dart';

/// Filtre local sur [Voyage.dateDepart] (jour civil) pour coller à la période UI.
class VoyagePeriodeFilter {
  VoyagePeriodeFilter._();

  static DateTime? parseDateDepartCalendaire(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final parsed = DateTime.tryParse(t);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    if (t.length >= 10) {
      final d = DateTime.tryParse(t.substring(0, 10));
      if (d != null) return DateTime(d.year, d.month, d.day);
    }
    return null;
  }

  static bool matches(Voyage voyage, VoyagePeriode periode, {DateTime? now}) {
    final dep = parseDateDepartCalendaire(voyage.dateDepart);
    if (dep == null) return false;

    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);

    switch (periode) {
      case VoyagePeriode.jour:
        return dep == today;
      case VoyagePeriode.hebdomadaire:
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return !dep.isBefore(start) && !dep.isAfter(end);
      case VoyagePeriode.mensuel:
        return dep.year == today.year && dep.month == today.month;
    }
  }

  static List<Voyage> apply(List<Voyage> voyages, VoyagePeriode periode) {
    return sortByDateDepartRecentFirst(
      voyages.where((v) => matches(v, periode)).toList(),
    );
  }

  /// Date + heure de départ pour le tri.
  static DateTime? parseDateTimeDepart(Voyage voyage) {
    final day = parseDateDepartCalendaire(voyage.dateDepart);
    if (day == null) return null;

    final raw = voyage.heureDepart.trim();
    if (raw.isEmpty) return day;

    final parts = raw.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(day.year, day.month, day.day, hour, minute);
    }
    return day;
  }

  /// Plus récent en premier (date de départ décroissante).
  static List<Voyage> sortByDateDepartRecentFirst(List<Voyage> voyages) {
    final sorted = List<Voyage>.from(voyages);
    sorted.sort((a, b) {
      final da = parseDateTimeDepart(a);
      final db = parseDateTimeDepart(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return sorted;
  }
}
