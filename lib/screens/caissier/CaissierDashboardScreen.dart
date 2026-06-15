import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/screens/caissier/BilletQrScannerScreen.dart';
import 'package:rusa/screens/caissier/CaissierAddClientScreen.dart';
import 'package:rusa/screens/caissier/CaissierClientsListScreen.dart';
import 'package:rusa/screens/caissier/CaissierDashboardStatsDetailsScreen.dart';
import 'package:rusa/screens/caissier/CaissierVoyagePassagersScreen.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/widgets/caissier_revenue_histogram.dart';
import 'package:rusa/widgets/caissier_shimmer.dart';
import 'package:rusa/widgets/password_change_reminder.dart';
import 'package:rusa/widgets/time_based_greeting.dart';

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({super.key});

  @override
  State<CaissierDashboardScreen> createState() =>
      _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboard;
  String _userDisplayName = 'Caissier';
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadConnectedUser();
    _loadDashboard();
  }

  Future<void> _loadConnectedUser() async {
    final auth = await CacheService.getAuthResponse();
    if (!mounted || auth == null) return;

    final fullName = auth.utilisateur.nomComplet.trim();
    final roleName = auth.nomRole.trim();
    setState(() {
      _userDisplayName = fullName.isNotEmpty
          ? fullName
          : (roleName.isNotEmpty ? roleName : 'Utilisateur');
      _userPhotoUrl = auth.utilisateur.photoUrl;
    });
  }

  Future<void> _loadDashboard() async {
    final data = await ApiService.getCaissierDashboard();
    if (!mounted) return;
    setState(() {
      _dashboard = data;
      _isLoading = false;
    });
  }

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

  String _devise() => (_dashboard?['codeDevisePrincipale'] ?? 'FC').toString();

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stats =
        (_dashboard?['statistiquesJournalieres'] as Map<String, dynamic>?) ??
        {};
    final resume = (_dashboard?['resumeCaisse'] as Map<String, dynamic>?) ?? {};
    final perf =
        (_dashboard?['performancesMensuelles'] as Map<String, dynamic>?) ?? {};
    final recettes =
        (_dashboard?['recettesJournalieres'] as List?)?.cast<dynamic>() ??
        const [];

    final paiements =
        (_dashboard?['paiementsRecents'] as List?)?.cast<dynamic>() ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BilletQrScannerScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF29F58B),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scanner billet'),
      ),
      body: _isLoading
          ? const CaissierDashboardShimmer()
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: const Color(0xFF29F58B),
              child: ListView(
                children: [
                  _buildTopSectionModern(
                    context: context,
                    soldeFinal: _fmt(resume['soldeFinal']),
                    totalEntrees: _fmt(resume['totalEntrees']),
                  ),

                  _buildFloatingCard(
                    totalRevenus: _fmt(stats['totalRevenusTransport']),
                    nombreTransactions: '${stats['nombreTransactions'] ?? 0}',
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const PasswordChangeReminder(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 20),

                        _buildStatsModern(
                          performancesMensuelles: perf,
                          recettesJournalieres: recettes,
                          devise: _devise(),
                          onDetails: _dashboard == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CaissierDashboardStatsDetailsScreen(
                                            dashboard: _dashboard!,
                                          ),
                                    ),
                                  );
                                },
                        ),

                        const SizedBox(height: 20),
                        _buildActivityList(paiements),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopSectionModern({
    required BuildContext context,
    required String soldeFinal,
    required String totalEntrees,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 54,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF29F58B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader()],
      ),
    );
  }

  Widget _buildFloatingCard({
    required String totalRevenus,
    required String nombreTransactions,
  }) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141A18),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Revenus aujourd’hui",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              "$totalRevenus FC",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$nombreTransactions transactions",
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <({IconData icon, VoidCallback onTap})>[
      (
        icon: Icons.person_add,
        onTap: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CaissierAddClientScreen(),
            ),
          );
          if (created == true && mounted) _loadDashboard();
        },
      ),
      (
        icon: Icons.groups_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CaissierClientsListScreen(),
            ),
          );
        },
      ),
      (
        icon: Icons.qr_code,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BilletQrScannerScreen(),
            ),
          );
        },
      ),
      (
        icon: Icons.people_outline,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CaissierVoyagePassagersScreen(),
            ),
          );
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF141A18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(a.icon, color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildAvatarFrame(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeBasedGreeting(
                style: const TextStyle(color: Color(0xFF093120), fontSize: 13),
              ),
              Text(
                _userDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.black,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFrame() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: SizedBox.expand(child: _buildUserAvatar()),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final rawPhoto = _userPhotoUrl?.trim() ?? '';
    final hasPhoto = rawPhoto.isNotEmpty;

    if (hasPhoto &&
        (rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://'))) {
      return Image.network(
        rawPhoto,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
      );
    }

    if (hasPhoto) {
      final bytes = _decodeBase64Image(rawPhoto);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
        );
      }
    }

    return _defaultAvatarIcon();
  }

  Widget _defaultAvatarIcon() {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF093120),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Uint8List? _decodeBase64Image(String input) {
    try {
      final cleaned = input.contains('base64,')
          ? input.split('base64,').last
          : input;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Widget _buildStatsModern({
    required Map<String, dynamic> performancesMensuelles,
    required List<dynamic> recettesJournalieres,
    required String devise,
    VoidCallback? onDetails,
  }) {
    final moisEnCours =
        (performancesMensuelles['moisEnCours'] as Map<String, dynamic>?) ?? {};
    final moisPrecedent =
        (performancesMensuelles['moisPrecedent'] as Map<String, dynamic>?) ??
        {};
    final synthese =
        (performancesMensuelles['synthese'] as Map<String, dynamic>?) ?? {};

    final encaissementsActuel = _fmt(moisEnCours['totalEncaissements']);
    final encaissementsPrecedent = _fmt(moisPrecedent['totalEncaissements']);
    final variation = _fmtPct(synthese['variationEncaissementsPourcentage']);
    final libelleActuel = (moisEnCours['libelle'] ?? 'Mois en cours')
        .toString();
    final libellePrecedent = (moisPrecedent['libelle'] ?? 'Mois précédent')
        .toString();
    final transactions = '${moisEnCours['nombreTransactions'] ?? 0}';
    final passagers = '${moisEnCours['nombrePassagers'] ?? 0}';

    final variationPositive = !variation.startsWith('-');
    final variationColor = variationPositive
        ? const Color(0xFF29F58B)
        : const Color(0xFFFF6B6B);

    final histogramBars = CaissierRevenueHistogram.fromRecettesJournalieres(
      recettesJournalieres,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Statistiques',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDetails != null)
                TextButton(
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF29F58B),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Détails'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            libelleActuel,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '$encaissementsActuel $devise',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: variationColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  variation,
                  style: TextStyle(
                    color: variationColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$libellePrecedent : $encaissementsPrecedent $devise',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$transactions transactions',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '$passagers passagers',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (histogramBars.isNotEmpty)
            CaissierRevenueHistogram(bars: histogramBars, devise: devise)
          else
            const Text(
              'Pas de recettes sur les derniers jours',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<dynamic> paiements) {
    if (paiements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141A18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Aucun paiement récent',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: [
        for (final p in paiements.take(5))
          _ActivityTile(
            title: (p['nomPassager'] ?? 'Paiement').toString(),
            subtitle:
                '${(p['voyageInfo'] ?? '').toString()} • ${_shortDate(p['datePaiement']?.toString())}',
            amount: '${_fmt(p['montantPaye'])} FC',
            subAmount: (p['reference'] ?? '').toString(),
            icon: Icons.payments_rounded,
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? amount;
  final String? subAmount;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    this.amount,
    this.subAmount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2621),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF29F58B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (amount != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount!,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (subAmount != null)
                  Text(
                    subAmount!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
