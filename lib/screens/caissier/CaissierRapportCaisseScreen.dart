import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/caissier_rapport_caisse.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/widgets/caissier_analytics_chart_card.dart';
import 'package:rusa/widgets/caissier_shimmer.dart';

enum _RapportMode { jour, periode }

class _ChannelStat {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final double amount;
  final int transactions;

  const _ChannelStat({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.amount,
    required this.transactions,
  });

  double shareOf(double total) => total <= 0 ? 0 : (amount / total) * 100;
}

/// Rapport de caisse caissier — vue statistiques (`GET /api/CaissierDashboard/rapport-caisse`).
class CaissierRapportCaisseScreen extends StatefulWidget {
  const CaissierRapportCaisseScreen({super.key});

  @override
  State<CaissierRapportCaisseScreen> createState() =>
      _CaissierRapportCaisseScreenState();
}

class _CaissierRapportCaisseScreenState extends State<CaissierRapportCaisseScreen> {
  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);
  static const _accent = Color(0xFF29F58B);
  static const _cashColor = Color(0xFFFFB74D);
  static const _electronicColor = Color(0xFF64B5F6);

  static const _frLocale = Locale('fr', 'FR');

  static const _weekdaysFr = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  static const _monthsFr = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  _RapportMode _mode = _RapportMode.jour;
  DateTime _selectedDay = DateTime.now();
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();

  CaissierRapportCaisse? _rapport;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRapport(initial: true);
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _count(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _fmt(dynamic value) => _num(value).toStringAsFixed(0);

  String _fmtPct(double value) => '${value.toStringAsFixed(1)} %';

  String _shortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _periodLabel(CaissierRapportCaisse rapport) {
    if (rapport.periodeDebut != null && rapport.periodeFin != null) {
      return '${_shortDate(rapport.periodeDebut!)} → '
          '${_shortDate(rapport.periodeFin!)}';
    }
    if (rapport.modePeriode.trim().isNotEmpty) return rapport.modePeriode;
    return _mode == _RapportMode.jour
        ? _shortDate(_selectedDay)
        : '${_shortDate(_rangeStart)} → ${_shortDate(_rangeEnd)}';
  }

  Map<String, dynamic> _detailBlock(Map<String, dynamic> detail, String key) {
    final block = detail[key];
    if (block is Map<String, dynamic>) return block;
    if (block is Map) return Map<String, dynamic>.from(block);
    return const {};
  }

  List<_ChannelStat> _electronicChannels(CaissierRapportCaisse rapport) {
    final detail = rapport.detailElectronique ?? const {};
    return [
      _ChannelStat(
        label: 'Mobile Money',
        shortLabel: 'M-Money',
        icon: Icons.phone_android_rounded,
        color: _accent,
        amount: _num(_detailBlock(detail, 'mobileMoney')['montantDevisePrincipale']),
        transactions: _count(
          _detailBlock(detail, 'mobileMoney')['nombreTransactions'],
        ),
      ),
      _ChannelStat(
        label: 'Carte bancaire',
        shortLabel: 'Carte',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF7E57C2),
        amount: _num(_detailBlock(detail, 'carte')['montantDevisePrincipale']),
        transactions: _count(
          _detailBlock(detail, 'carte')['nombreTransactions'],
        ),
      ),
      _ChannelStat(
        label: 'Virement',
        shortLabel: 'Virement',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF4FC3F7),
        amount: _num(_detailBlock(detail, 'virement')['montantDevisePrincipale']),
        transactions: _count(
          _detailBlock(detail, 'virement')['nombreTransactions'],
        ),
      ),
      _ChannelStat(
        label: 'Autre',
        shortLabel: 'Autre',
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFF90A4AE),
        amount: _num(_detailBlock(detail, 'autre')['montantDevisePrincipale']),
        transactions: _count(
          _detailBlock(detail, 'autre')['nombreTransactions'],
        ),
      ),
    ];
  }

  Future<void> _loadRapport({bool initial = false}) async {
    if (initial || _rapport == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    final result = _mode == _RapportMode.jour
        ? await ApiService.getCaissierRapportCaisse(datePrecise: _selectedDay)
        : await ApiService.getCaissierRapportCaisse(
            dateDebut: _rangeStart,
            dateFin: _rangeEnd,
          );

    if (!mounted) return;

    setState(() {
      _rapport = result.data;
      _loading = false;
      _refreshing = false;
      _error = result.data == null ? result.error : null;
    });
  }

  String _monthFr(int month) => _monthsFr[month - 1];

  String _weekdayFr(DateTime d) => _weekdaysFr[d.weekday - 1];

  String _longDateFr(DateTime d) {
    return '${_weekdayFr(d)} ${d.day} ${_monthFr(d.month)} ${d.year}';
  }

  String _rangeLabelFr() {
    if (_isSameDay(_rangeStart, _rangeEnd)) {
      return _longDateFr(_rangeStart);
    }
    return 'Du ${_rangeStart.day} ${_monthFr(_rangeStart.month)} '
        'au ${_rangeEnd.day} ${_monthFr(_rangeEnd.month)} ${_rangeEnd.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  bool _isYesterday(DateTime d) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(d, yesterday);
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Widget _frenchPickerBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          onPrimary: Colors.black,
          surface: _card,
          onSurface: Colors.white,
          secondary: _accent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: _bg,
          headerBackgroundColor: _accent.withValues(alpha: 0.14),
          headerForegroundColor: Colors.white,
          weekdayStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          dayStyle: const TextStyle(color: Colors.white),
          yearStyle: const TextStyle(color: Colors.white70),
          todayForegroundColor: WidgetStateProperty.all(_accent),
          todayBackgroundColor: WidgetStateProperty.all(
            _accent.withValues(alpha: 0.18),
          ),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.black;
            if (states.contains(WidgetState.disabled)) return Colors.white24;
            return Colors.white;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _accent;
            return Colors.transparent;
          }),
          rangeSelectionBackgroundColor: _accent.withValues(alpha: 0.22),
          rangeSelectionOverlayColor: WidgetStateProperty.all(
            _accent.withValues(alpha: 0.1),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _accent,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Localizations(
        locale: _frLocale,
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      locale: _frLocale,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Choisir une date',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: _frenchPickerBuilder,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDay = _startOfDay(picked));
    await _loadRapport();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      locale: _frLocale,
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Choisir une période',
      cancelText: 'Annuler',
      saveText: 'Valider',
      builder: _frenchPickerBuilder,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rangeStart = _startOfDay(picked.start);
      _rangeEnd = _startOfDay(picked.end);
    });
    await _loadRapport();
  }

  void _selectToday() {
    final today = _startOfDay(DateTime.now());
    setState(() {
      if (_mode == _RapportMode.jour) {
        _selectedDay = today;
      } else {
        _rangeStart = today;
        _rangeEnd = today;
      }
    });
    _loadRapport();
  }

  void _selectYesterday() {
    final yesterday = _startOfDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    setState(() {
      if (_mode == _RapportMode.jour) {
        _selectedDay = yesterday;
      } else {
        _rangeStart = yesterday;
        _rangeEnd = yesterday;
      }
    });
    _loadRapport();
  }

  void _selectLastSevenDays() {
    final today = _startOfDay(DateTime.now());
    setState(() {
      _mode = _RapportMode.periode;
      _rangeEnd = today;
      _rangeStart = today.subtract(const Duration(days: 6));
    });
    _loadRapport();
  }

  void _selectCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _mode = _RapportMode.periode;
      _rangeStart = DateTime(now.year, now.month, 1);
      _rangeEnd = _startOfDay(now);
    });
    _loadRapport();
  }

  void _onModeChanged(_RapportMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _loadRapport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: Text(
          'Statistiques caisse',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRapport(),
        color: _accent,
        child: _buildScrollableContent(),
      ),
    );
  }

  Widget _buildScrollableContent() {
    if (_loading && _rapport == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 8),
          CaissierStatsDetailsShimmer(),
        ],
      );
    }

    if (_error != null && _rapport == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => _loadRapport(initial: true),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Réessayer'),
            ),
          ),
        ],
      );
    }

    final rapport = _rapport;
    if (rapport == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Aucune donnée pour cette période.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_refreshing)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              color: _accent,
              backgroundColor: Colors.white12,
              minHeight: 2,
            ),
          ),
        _buildFilters(),
        const SizedBox(height: 16),
        ..._buildStatsContent(rapport),
      ],
    );
  }

  Widget _buildFilters() {
    final isDayMode = _mode == _RapportMode.jour;
    final displayDate = isDayMode ? _selectedDay : _rangeEnd;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période d\'analyse',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Affinez les statistiques par jour ou par intervalle.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A211E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _modeToggle(
                    mode: _RapportMode.jour,
                    label: 'Jour',
                    subtitle: 'Une date précise',
                    icon: Icons.today_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _modeToggle(
                    mode: _RapportMode.periode,
                    label: 'Période',
                    subtitle: 'Plusieurs jours',
                    icon: Icons.date_range_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: const Color(0xFF1A211E),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isDayMode ? _pickDay : _pickRange,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.22),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.28),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isDayMode
                                  ? '${displayDate.day}'
                                  : '${_rangeStart.day}-${_rangeEnd.day}',
                              style: GoogleFonts.caveat(
                                color: _accent,
                                fontSize: isDayMode ? 26 : 20,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            if (isDayMode)
                              Text(
                                _monthFr(displayDate.month).substring(0, 3),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  height: 1.1,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDayMode ? 'Date sélectionnée' : 'Période sélectionnée',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDayMode
                                  ? _longDateFr(_selectedDay)
                                  : _rangeLabelFr(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDayMode
                                  ? (_isToday(_selectedDay)
                                      ? 'Aujourd\'hui'
                                      : _isYesterday(_selectedDay)
                                      ? 'Hier'
                                      : 'Appuyez pour modifier')
                                  : '${_rangeEnd.difference(_rangeStart).inDays + 1} jour(s)',
                              style: TextStyle(
                                color: _accent.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_calendar_rounded,
                          color: _accent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickFilterChip(
                label: 'Aujourd\'hui',
                selected: isDayMode && _isToday(_selectedDay),
                onTap: _selectToday,
              ),
              _quickFilterChip(
                label: 'Hier',
                selected: isDayMode && _isYesterday(_selectedDay),
                onTap: _selectYesterday,
              ),
              _quickFilterChip(
                label: '7 derniers jours',
                selected: !isDayMode &&
                    _isSameDay(_rangeEnd, _startOfDay(DateTime.now())) &&
                    _rangeEnd.difference(_rangeStart).inDays == 6,
                onTap: _selectLastSevenDays,
              ),
              _quickFilterChip(
                label: 'Ce mois',
                selected: !isDayMode &&
                    _rangeStart.day == 1 &&
                    _rangeStart.month == DateTime.now().month &&
                    _rangeStart.year == DateTime.now().year &&
                    _isSameDay(_rangeEnd, _startOfDay(DateTime.now())),
                onTap: _selectCurrentMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeToggle({
    required _RapportMode mode,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _mode == mode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onModeChanged(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.black : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: selected ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: selected
                              ? Colors.black.withValues(alpha: 0.62)
                              : Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? _accent.withValues(alpha: 0.16)
          : const Color(0xFF1A211E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? _accent : Colors.white60,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStatsContent(CaissierRapportCaisse rapport) {
    final devise = rapport.codeDevisePrincipale;
    final synthese = rapport.synthese;
    final cashAmount = _num(rapport.especes['montantDevisePrincipale']);
    final cashTx = _count(rapport.especes['nombreTransactions']);
    final electronicAmount =
        _num(rapport.electronique['montantDevisePrincipale']);
    final electronicTx =
        _count(rapport.electronique['nombreTransactions']);
    final totalAmount = _num(synthese['totalEncaisse']);
    final totalTx = _count(synthese['nombreTransactions']);
    final cashPct = _num(synthese['partEspecesPourcentage']);
    final electronicPct = _num(synthese['partElectroniquePourcentage']);
    final channels = _electronicChannels(rapport);
    final maxChannelAmount = channels
        .map((c) => c.amount)
        .fold<double>(0, (a, b) => math.max(a, b));

    return [
      _heroCard(
        rapport: rapport,
        totalAmount: totalAmount,
        totalTx: totalTx,
        devise: devise,
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _miniStatCard(
              label: 'Espèces',
              amount: cashAmount,
              transactions: cashTx,
              devise: devise,
              color: _cashColor,
              icon: Icons.payments_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStatCard(
              label: 'Électronique',
              amount: electronicAmount,
              transactions: electronicTx,
              devise: devise,
              color: _electronicColor,
              icon: Icons.contactless_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      CaissierAnalyticsChartCard(
        title: 'Répartition des encaissements',
        subtitle: _periodLabel(rapport),
        chart: Column(
          children: [
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _DonutChart(
                      segments: [
                        _DonutSegment(
                          label: 'Espèces',
                          value: cashAmount,
                          color: _cashColor,
                          percentage: cashPct,
                        ),
                        _DonutSegment(
                          label: 'Électronique',
                          value: electronicAmount,
                          color: _electronicColor,
                          percentage: electronicPct,
                        ),
                      ],
                      centerLabel: _fmt(totalAmount),
                      centerSubLabel: devise,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem(
                          color: _cashColor,
                          label: 'Espèces',
                          value: '${_fmtPct(cashPct)} • $cashTx tx',
                        ),
                        const SizedBox(height: 12),
                        _legendItem(
                          color: _electronicColor,
                          label: 'Électronique',
                          value: '${_fmtPct(electronicPct)} • $electronicTx tx',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _comparisonBar(
              leftLabel: 'Espèces',
              leftValue: cashAmount,
              leftColor: _cashColor,
              rightLabel: 'Électronique',
              rightValue: electronicAmount,
              rightColor: _electronicColor,
              total: totalAmount,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      CaissierAnalyticsChartCard(
        title: 'Paiements électroniques',
        subtitle: 'Par canal de règlement',
        chart: channels.isEmpty || maxChannelAmount <= 0
            ? _emptyChart('Aucun paiement électronique sur la période')
            : Column(
                children: [
                  for (final channel in channels)
                    _channelBar(
                      channel: channel,
                      maxAmount: maxChannelAmount,
                      devise: devise,
                      totalElectronic: electronicAmount,
                    ),
                ],
              ),
      ),
      if (rapport.parDevise.isNotEmpty) ...[
        const SizedBox(height: 14),
        CaissierAnalyticsChartCard(
          title: 'Répartition par devise',
          subtitle: 'Espèces vs électronique',
          chart: Column(
            children: rapport.parDevise.map((row) {
              return _deviseBreakdownTile(row, devise);
            }).toList(),
          ),
        ),
      ],
    ];
  }

  Widget _heroCard({
    required CaissierRapportCaisse rapport,
    required double totalAmount,
    required int totalTx,
    required String devise,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.18),
            _card,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodLabel(rapport),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(totalAmount)} $devise',
            style: GoogleFonts.caveat(
              color: _accent,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalTx transaction${totalTx > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard({
    required String label,
    required double amount,
    required int transactions,
    required String devise,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(amount)} $devise',
            style: GoogleFonts.caveat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$transactions tx',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonBar({
    required String leftLabel,
    required double leftValue,
    required Color leftColor,
    required String rightLabel,
    required double rightValue,
    required Color rightColor,
    required double total,
  }) {
    final leftFlex = total <= 0 ? 1.0 : leftValue / total;
    final rightFlex = total <= 0 ? 1.0 : rightValue / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (leftFlex > 0)
                  Expanded(
                    flex: (leftFlex * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: leftColor),
                  ),
                if (rightFlex > 0)
                  Expanded(
                    flex: (rightFlex * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: rightColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: TextStyle(color: leftColor, fontSize: 10)),
            Text(rightLabel, style: TextStyle(color: rightColor, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _channelBar({
    required _ChannelStat channel,
    required double maxAmount,
    required String devise,
    required double totalElectronic,
  }) {
    final ratio = maxAmount <= 0 ? 0.0 : channel.amount / maxAmount;
    final share = channel.shareOf(totalElectronic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(channel.icon, color: channel.color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Text(
                '${_fmt(channel.amount)} $devise',
                style: GoogleFonts.caveat(
                  color: channel.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: channel.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${channel.transactions} transaction${channel.transactions > 1 ? 's' : ''} '
            '• ${_fmtPct(share)} du électronique',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _deviseBreakdownTile(
    Map<String, dynamic> row,
    String mainDevise,
  ) {
    final code = row['codeDevisePaiement']?.toString() ?? '—';
    final especes = row['especes'] is Map
        ? Map<String, dynamic>.from(row['especes'] as Map)
        : const <String, dynamic>{};
    final electronique = row['electronique'] is Map
        ? Map<String, dynamic>.from(row['electronique'] as Map)
        : const <String, dynamic>{};
    final cash = _num(especes['montantPaye']);
    final elec = _num(electronique['montantPaye']);
    final total = cash + elec;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A211E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _comparisonBar(
            leftLabel: 'Espèces (${especes['count'] ?? 0})',
            leftValue: cash,
            leftColor: _cashColor,
            rightLabel: 'Électronique (${electronique['count'] ?? 0})',
            rightValue: elec,
            rightColor: _electronicColor,
            total: total,
          ),
          if (code != mainDevise) ...[
            const SizedBox(height: 4),
            Text(
              'Total devise : ${_fmt(total)} $code',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A211E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white54)),
    );
  }
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  final double percentage;

  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });
}

class _DonutChart extends StatelessWidget {
  final List<_DonutSegment> segments;
  final String centerLabel;
  final String centerSubLabel;

  const _DonutChart({
    required this.segments,
    required this.centerLabel,
    required this.centerSubLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutChartPainter(segments: segments),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              centerLabel,
              style: GoogleFonts.caveat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              centerSubLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
