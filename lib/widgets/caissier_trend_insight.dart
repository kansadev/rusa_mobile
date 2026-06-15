import 'package:flutter/material.dart';

/// Direction d'une tendance affichée sur les graphiques caissier.
enum CaissierTrendDirection { up, down, stable }

/// Indication contextuelle (hausse, baisse, stabilité).
class CaissierTrendInsight {
  final String message;
  final CaissierTrendDirection direction;
  final double? variationPercent;

  const CaissierTrendInsight({
    required this.message,
    required this.direction,
    this.variationPercent,
  });

  Color get color => switch (direction) {
        CaissierTrendDirection.up => const Color(0xFF29F58B),
        CaissierTrendDirection.down => const Color(0xFFFF6B6B),
        CaissierTrendDirection.stable => const Color(0xFFB0BEC5),
      };

  IconData get icon => switch (direction) {
        CaissierTrendDirection.up => Icons.trending_up_rounded,
        CaissierTrendDirection.down => Icons.trending_down_rounded,
        CaissierTrendDirection.stable => Icons.trending_flat_rounded,
      };

  String? get badge {
    if (variationPercent == null) return null;
    final sign = variationPercent! >= 0 ? '+' : '';
    return '$sign${variationPercent!.toStringAsFixed(1)}%';
  }
}

/// Génère les messages d'analyse à partir des données dashboard API.
class CaissierDashboardInsightBuilder {
  static CaissierTrendInsight encaissementsMensuels(
    Map<String, dynamic> dashboard,
  ) {
    final perf =
        (dashboard['performancesMensuelles'] as Map<String, dynamic>?) ?? {};
    final synthese = (perf['synthese'] as Map<String, dynamic>?) ?? {};
    final pct = _toDouble(synthese['variationEncaissementsPourcentage']);

    if (pct == null) {
      return const CaissierTrendInsight(
        message: 'Pas assez de données pour comparer les encaissements mensuels.',
        direction: CaissierTrendDirection.stable,
      );
    }

    if (pct.abs() < 1) {
      return CaissierTrendInsight(
        message: 'Vos encaissements sont stables par rapport au mois dernier.',
        direction: CaissierTrendDirection.stable,
        variationPercent: pct,
      );
    }

    if (pct > 0) {
      return CaissierTrendInsight(
        message:
            'Vos encaissements sont en hausse de ${pct.toStringAsFixed(1)} % ce mois.',
        direction: CaissierTrendDirection.up,
        variationPercent: pct,
      );
    }

    return CaissierTrendInsight(
      message:
          'Vos encaissements sont en baisse de ${pct.abs().toStringAsFixed(1)} % ce mois.',
      direction: CaissierTrendDirection.down,
      variationPercent: pct,
    );
  }

  static CaissierTrendInsight reservationsMensuelles(
    Map<String, dynamic> dashboard,
  ) {
    final perf =
        (dashboard['performancesMensuelles'] as Map<String, dynamic>?) ?? {};
    final synthese = (perf['synthese'] as Map<String, dynamic>?) ?? {};
    final pct = _toDouble(synthese['variationReservationsPourcentage']);

    if (pct == null) {
      return const CaissierTrendInsight(
        message: 'Évolution des réservations indisponible pour le moment.',
        direction: CaissierTrendDirection.stable,
      );
    }

    if (pct.abs() < 1) {
      return CaissierTrendInsight(
        message: 'Le volume de réservations est stable par rapport au mois dernier.',
        direction: CaissierTrendDirection.stable,
        variationPercent: pct,
      );
    }

    if (pct > 0) {
      return CaissierTrendInsight(
        message:
            'Le taux de réservations est en hausse de ${pct.toStringAsFixed(1)} % ce mois.',
        direction: CaissierTrendDirection.up,
        variationPercent: pct,
      );
    }

    return CaissierTrendInsight(
      message:
          'Le taux de réservations est en chute de ${pct.abs().toStringAsFixed(1)} % ce mois.',
      direction: CaissierTrendDirection.down,
      variationPercent: pct,
    );
  }

  static CaissierTrendInsight billetsMensuels(Map<String, dynamic> dashboard) {
    final perf =
        (dashboard['performancesMensuelles'] as Map<String, dynamic>?) ?? {};
    final synthese = (perf['synthese'] as Map<String, dynamic>?) ?? {};
    final pct = _toDouble(synthese['variationBilletsEmisPourcentage']);

    if (pct == null) {
      return const CaissierTrendInsight(
        message: 'Évolution des billets émis indisponible.',
        direction: CaissierTrendDirection.stable,
      );
    }

    if (pct > 0) {
      return CaissierTrendInsight(
        message:
            'Les billets émis progressent de ${pct.toStringAsFixed(1)} % vs le mois dernier.',
        direction: CaissierTrendDirection.up,
        variationPercent: pct,
      );
    }
    if (pct < -1) {
      return CaissierTrendInsight(
        message:
            'Les billets émis reculent de ${pct.abs().toStringAsFixed(1)} % vs le mois dernier.',
        direction: CaissierTrendDirection.down,
        variationPercent: pct,
      );
    }

    return CaissierTrendInsight(
      message: 'Le nombre de billets émis reste stable ce mois.',
      direction: CaissierTrendDirection.stable,
      variationPercent: pct,
    );
  }

  /// Compare la 1re moitié vs la 2e moitié de la période `recettesJournalieres`.
  static CaissierTrendInsight embarquementSemaine(
    Map<String, dynamic> dashboard,
  ) {
    final recettes = _parseRecettes(dashboard);
    if (recettes.length < 2) {
      return const CaissierTrendInsight(
        message: 'Données insuffisantes pour analyser l\'embarquement cette semaine.',
        direction: CaissierTrendDirection.stable,
      );
    }

    final mid = recettes.length ~/ 2;
    final debut = _sumField(recettes, 0, mid, 'nombreBilletsVendus');
    final fin = _sumField(recettes, mid, recettes.length, 'nombreBilletsVendus');
    return _halfPeriodInsight(
      label: 'embarquement',
      unit: 'billets vendus',
      firstValue: debut,
      secondValue: fin,
      upMessage: (pct) =>
          'Votre taux d\'embarquement progresse cette semaine (+${pct.toStringAsFixed(0)} %, $fin vs $debut billets).',
      downMessage: (pct) =>
          'Votre taux d\'embarquement a baissé cette semaine (−${pct.abs().toStringAsFixed(0)} %, $fin vs $debut billets).',
      stableMessage:
          'L\'embarquement reste stable sur la période analysée ($fin billets récents).',
    );
  }

  static CaissierTrendInsight transactionsSemaine(
    Map<String, dynamic> dashboard,
  ) {
    final recettes = _parseRecettes(dashboard);
    if (recettes.length < 2) {
      return const CaissierTrendInsight(
        message: 'Données insuffisantes pour analyser les transactions cette semaine.',
        direction: CaissierTrendDirection.stable,
      );
    }

    final mid = recettes.length ~/ 2;
    final debut =
        _sumField(recettes, 0, mid, 'nombreTransactions');
    final fin = _sumField(recettes, mid, recettes.length, 'nombreTransactions');

    return _halfPeriodInsight(
      label: 'transactions',
      unit: 'transactions',
      firstValue: debut,
      secondValue: fin,
      upMessage: (pct) =>
          'L\'activité transactionnelle accélère (+${pct.toStringAsFixed(0)} % cette semaine).',
      downMessage: (pct) =>
          'L\'activité transactionnelle ralentit (−${pct.abs().toStringAsFixed(0)} % cette semaine).',
      stableMessage: 'Le rythme des transactions est constant sur la période.',
    );
  }

  static CaissierTrendInsight tauxRemplissage(Map<String, dynamic> dashboard) {
    final stats =
        (dashboard['statistiquesJournalieres'] as Map<String, dynamic>?) ?? {};
    final resume = (dashboard['resumeCaisse'] as Map<String, dynamic>?) ?? {};
    final jour = _toDouble(stats['tauxRemplissageMoyen']);
    final caisse = _toDouble(resume['tauxRemplissageMoyen']);
    final taux = jour ?? caisse;

    if (taux == null) {
      return const CaissierTrendInsight(
        message: 'Taux de remplissage non disponible aujourd\'hui.',
        direction: CaissierTrendDirection.stable,
      );
    }

    if (taux >= 70) {
      return CaissierTrendInsight(
        message:
            'Excellent taux de remplissage aujourd\'hui (${taux.toStringAsFixed(1)} %).',
        direction: CaissierTrendDirection.up,
        variationPercent: taux,
      );
    }
    if (taux < 30) {
      return CaissierTrendInsight(
        message:
            'Taux de remplissage faible aujourd\'hui (${taux.toStringAsFixed(1)} %).',
        direction: CaissierTrendDirection.down,
        variationPercent: taux,
      );
    }

    return CaissierTrendInsight(
      message:
          'Taux de remplissage moyen à ${taux.toStringAsFixed(1)} % aujourd\'hui.',
      direction: CaissierTrendDirection.stable,
      variationPercent: taux,
    );
  }

  static List<MetricChartPoint> recettesPoints(Map<String, dynamic> dashboard) {
    return _parseRecettes(dashboard).map((r) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      final label = dt != null
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
          : '';
      return MetricChartPoint(
        label: label,
        value: _toDouble(r['montantTotal']) ?? 0,
      );
    }).toList();
  }

  static List<MetricChartPoint> billetsPoints(Map<String, dynamic> dashboard) {
    return _parseRecettes(dashboard).map((r) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      final label = dt != null
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
          : '';
      return MetricChartPoint(
        label: label,
        value: _toDouble(r['nombreBilletsVendus']) ?? 0,
      );
    }).toList();
  }

  static List<MetricChartPoint> transactionsPoints(
    Map<String, dynamic> dashboard,
  ) {
    return _parseRecettes(dashboard).map((r) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      final label = dt != null
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
          : '';
      return MetricChartPoint(
        label: label,
        value: _toDouble(r['nombreTransactions']) ?? 0,
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _parseRecettes(
    Map<String, dynamic> dashboard,
  ) {
    final raw =
        (dashboard['recettesJournalieres'] as List?)?.cast<dynamic>() ??
        const [];
    return raw
        .map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .where((m) => m.isNotEmpty)
        .toList();
  }

  static double _sumField(
    List<Map<String, dynamic>> items,
    int start,
    int end,
    String field,
  ) {
    var sum = 0.0;
    for (var i = start; i < end && i < items.length; i++) {
      sum += _toDouble(items[i][field]) ?? 0;
    }
    return sum;
  }

  static CaissierTrendInsight _halfPeriodInsight({
    required String label,
    required String unit,
    required double firstValue,
    required double secondValue,
    required String Function(double pct) upMessage,
    required String Function(double pct) downMessage,
    required String stableMessage,
  }) {
    if (firstValue <= 0 && secondValue <= 0) {
      return CaissierTrendInsight(
        message: 'Aucun $unit enregistré sur la période récente.',
        direction: CaissierTrendDirection.stable,
      );
    }

    final base = firstValue <= 0 ? 1.0 : firstValue;
    final pct = ((secondValue - firstValue) / base) * 100;

    if (pct.abs() < 5) {
      return CaissierTrendInsight(
        message: stableMessage,
        direction: CaissierTrendDirection.stable,
        variationPercent: pct,
      );
    }
    if (pct > 0) {
      return CaissierTrendInsight(
        message: upMessage(pct),
        direction: CaissierTrendDirection.up,
        variationPercent: pct,
      );
    }
    return CaissierTrendInsight(
      message: downMessage(pct),
      direction: CaissierTrendDirection.down,
      variationPercent: pct,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

/// Point de données pour les courbes caissier.
class MetricChartPoint {
  final String label;
  final double value;

  const MetricChartPoint({required this.label, required this.value});
}
