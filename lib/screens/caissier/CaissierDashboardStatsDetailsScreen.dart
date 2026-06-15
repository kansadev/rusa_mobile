import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/widgets/caissier_analytics_chart_card.dart';
import 'package:rusa/widgets/caissier_metric_line_chart.dart';
import 'package:rusa/widgets/caissier_revenue_histogram.dart';
import 'package:rusa/widgets/caissier_shimmer.dart';
import 'package:rusa/widgets/caissier_trend_insight.dart';

/// Détails complets du dashboard caissier (performances, graphiques, caisse).
class CaissierDashboardStatsDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? dashboard;
  final bool embeddedInNav;

  const CaissierDashboardStatsDetailsScreen({
    super.key,
    this.dashboard,
    this.embeddedInNav = false,
  });

  @override
  State<CaissierDashboardStatsDetailsScreen> createState() =>
      _CaissierDashboardStatsDetailsScreenState();
}

class _CaissierDashboardStatsDetailsScreenState
    extends State<CaissierDashboardStatsDetailsScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.dashboard;
    if (_needsFetch(_dashboard)) {
      _loadDashboard();
    }
  }

  @override
  void didUpdateWidget(
    covariant CaissierDashboardStatsDetailsScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.dashboard != oldWidget.dashboard && widget.dashboard != null) {
      _dashboard = widget.dashboard;
    }
  }

  bool _needsFetch(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return true;
    return !data.containsKey('performancesMensuelles') &&
        !data.containsKey('recettesJournalieres');
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = await ApiService.getCaissierDashboard();

    if (!mounted) return;

    setState(() {
      _dashboard = data;
      _loading = false;
      _error = data == null ? 'Impossible de charger les statistiques.' : null;
    });
  }

  String get _devise =>
      (_dashboard?['codeDevisePrincipale'] ?? 'FC').toString();

  String _fmt(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(0);
  }

  String _fmtPct(dynamic value) {
    if (value == null) return '—';
    final n = value is num ? value.toDouble() : double.tryParse('$value');
    if (n == null) return '—';
    final sign = n >= 0 ? '+' : '';
    return '$sign${n.toStringAsFixed(1)}%';
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F0D),
        elevation: 0,
        automaticallyImplyLeading: !widget.embeddedInNav,
        leading: widget.embeddedInNav
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
        title: Text(
          'Statistiques détaillées',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _dashboard == null) {
      return const CaissierStatsDetailsShimmer();
    }

    if (_error != null && _dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadDashboard,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF29F58B),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboard ?? {};
    final stats =
        (data['statistiquesJournalieres'] as Map<String, dynamic>?) ?? {};
    final resume = (data['resumeCaisse'] as Map<String, dynamic>?) ?? {};
    final perf =
        (data['performancesMensuelles'] as Map<String, dynamic>?) ?? {};
    final moisEnCours = (perf['moisEnCours'] as Map<String, dynamic>?) ?? {};
    final moisPrecedent =
        (perf['moisPrecedent'] as Map<String, dynamic>?) ?? {};
    final synthese = (perf['synthese'] as Map<String, dynamic>?) ?? {};
    final recettes =
        (data['recettesJournalieres'] as List?)?.cast<dynamic>() ?? const [];
    final paiementsEnCours = (data['paiementsEnCours'] as List?)?.length ?? 0;
    final alertes = (data['alertesCaissier'] as List?)?.length ?? 0;

    final histogramBars = CaissierRevenueHistogram.fromRecettesJournalieres(
      recettes,
    );
    final billetsPoints = CaissierDashboardInsightBuilder.billetsPoints(data);
    final transactionsPoints =
        CaissierDashboardInsightBuilder.transactionsPoints(data);

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF29F58B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _sectionTitle('Vue analytique'),
          CaissierAnalyticsChartCard(
            title: 'Encaissements journaliers',
            subtitle: '7 derniers jours',
            insight: CaissierDashboardInsightBuilder.encaissementsMensuels(
              data,
            ),
            chart: histogramBars.isEmpty
                ? _emptyBox('Aucune recette sur la période')
                : CaissierRevenueHistogram(
                    bars: histogramBars,
                    devise: _devise,
                    height: 120,
                  ),
          ),
          const SizedBox(height: 14),
          CaissierAnalyticsChartCard(
            title: 'Billets vendus',
            subtitle: 'Évolution sur la période',
            insight: CaissierDashboardInsightBuilder.embarquementSemaine(data),
            chart: CaissierMetricLineChart(
              points: billetsPoints,
              lineColor: const Color(0xFF29F58B),
            ),
          ),
          const SizedBox(height: 14),
          CaissierAnalyticsChartCard(
            title: 'Transactions',
            subtitle: 'Évolution sur la période',
            insight: CaissierDashboardInsightBuilder.transactionsSemaine(data),
            chart: CaissierMetricLineChart(
              points: transactionsPoints,
              lineColor: const Color(0xFF64B5F6),
            ),
          ),
          const SizedBox(height: 14),
          CaissierAnalyticsChartCard(
            title: 'Réservations & remplissage',
            subtitle: 'Indicateurs du mois et du jour',
            insight: CaissierDashboardInsightBuilder.reservationsMensuelles(
              data,
            ),
            chart: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _insightRow(
                  CaissierDashboardInsightBuilder.billetsMensuels(data),
                ),
                const SizedBox(height: 8),
                _insightRow(
                  CaissierDashboardInsightBuilder.tauxRemplissage(data),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Comparaison mensuelle'),
          _comparisonCard(
            labelActuel: (moisEnCours['libelle'] ?? 'Mois en cours').toString(),
            labelPrecedent: (moisPrecedent['libelle'] ?? 'Mois précédent')
                .toString(),
            encaissementsActuel: _fmt(moisEnCours['totalEncaissements']),
            encaissementsPrecedent: _fmt(moisPrecedent['totalEncaissements']),
            variation: _fmtPct(synthese['variationEncaissementsPourcentage']),
            transactionsActuel: '${moisEnCours['nombreTransactions'] ?? 0}',
            transactionsPrecedent:
                '${moisPrecedent['nombreTransactions'] ?? 0}',
            variationTransactions: _fmtPct(
              synthese['variationTransactionsPourcentage'],
            ),
            passagersActuel: '${moisEnCours['nombrePassagers'] ?? 0}',
            passagersPrecedent: '${moisPrecedent['nombrePassagers'] ?? 0}',
          ),
          const SizedBox(height: 20),
          _sectionTitle('Aujourd\'hui'),
          _kvCard([
            _Kv(
              'Revenus transport',
              '${_fmt(stats['totalRevenusTransport'])} $_devise',
            ),
            _Kv('Transactions', '${stats['nombreTransactions'] ?? 0}'),
            _Kv(
              'Moyenne / transaction',
              '${_fmt(stats['moyenneTransaction'])} $_devise',
            ),
            _Kv('Passagers', '${stats['nombrePassagers'] ?? 0}'),
            _Kv('Billets vendus', '${stats['nombreBilletsVendus'] ?? 0}'),
            _Kv(
              'Réservations confirmées',
              '${stats['reservationsConfirmeesJour'] ?? 0}',
            ),
            _Kv('Taux remplissage', '${_fmt(stats['tauxRemplissageMoyen'])} %'),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Caisse'),
          _kvCard([
            _Kv('Statut', (resume['statutCaisse'] ?? '—').toString()),
            _Kv(
              'Total entrées (jour)',
              '${_fmt(resume['totalEntrees'])} $_devise',
            ),
            _Kv(
              'Billets vendus (jour)',
              '${resume['totalBilletsVendus'] ?? 0}',
            ),
            _Kv(
              'Réservations confirmées',
              '${resume['reservationsConfirmees'] ?? 0}',
            ),
            _Kv('En attente', '${resume['reservationsEnAttente'] ?? 0}'),
            _Kv('Paiements en cours', '$paiementsEnCours'),
            _Kv('Alertes', '$alertes'),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Recettes par jour (période)'),
          if (recettes.isEmpty)
            _emptyBox('Aucune recette sur la période')
          else
            ...recettes.map((r) {
              final map = r is Map
                  ? Map<String, dynamic>.from(r)
                  : <String, dynamic>{};
              return _recetteTile(map);
            }),
          const SizedBox(height: 20),
          _sectionTitle('Répartition mois en cours'),
          _kvCard([
            _Kv('Espèces', '${_fmt(moisEnCours['recetteEspece'])} $_devise'),
            _Kv(
              'Mobile Money',
              '${_fmt(moisEnCours['recetteMobileMoney'])} $_devise',
            ),
            _Kv('Carte', '${_fmt(moisEnCours['recetteCarte'])} $_devise'),
            _Kv('Virement', '${_fmt(moisEnCours['recetteVirement'])} $_devise'),
            _Kv(
              'Moy. journalière',
              '${_fmt(moisEnCours['moyenneEncaissementsJournaliers'])} $_devise',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _insightRow(CaissierTrendInsight insight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A211E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.message,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.caveat(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A211E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _comparisonCard({
    required String labelActuel,
    required String labelPrecedent,
    required String encaissementsActuel,
    required String encaissementsPrecedent,
    required String variation,
    required String transactionsActuel,
    required String transactionsPrecedent,
    required String variationTransactions,
    required String passagersActuel,
    required String passagersPrecedent,
  }) {
    final variationPositive = !variation.startsWith('-');
    final variationColor = variationPositive
        ? const Color(0xFF29F58B)
        : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelActuel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$encaissementsActuel $_devise',
                      style: GoogleFonts.caveat(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: variationColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      variationPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: variationColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      variation,
                      style: TextStyle(
                        color: variationColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$labelPrecedent : $encaissementsPrecedent $_devise',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Transactions',
                  transactionsActuel,
                  '$transactionsPrecedent mois préc.',
                  variationTransactions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  'Passagers',
                  passagersActuel,
                  '$passagersPrecedent mois préc.',
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    String subtitle,
    String? variation,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A211E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.caveat(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          if (variation != null) ...[
            const SizedBox(height: 4),
            Text(
              variation,
              style: TextStyle(
                color: variation.startsWith('-')
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF29F58B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvCard(List<_Kv> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(color: Colors.white10, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    items[i].label,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                Text(
                  items[i].value,
                  style: GoogleFonts.caveat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _recetteTile(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDate(r['date']?.toString()),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '${r['nombreTransactions'] ?? 0} transaction(s) • '
                  '${r['nombreBilletsVendus'] ?? 0} billet(s)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt(r['montantTotal'])} $_devise',
            style: GoogleFonts.caveat(
              color: const Color(0xFF29F58B),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Kv {
  final String label;
  final String value;
  const _Kv(this.label, this.value);
}
