import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/screens/caissier/BilletQrScannerScreen.dart';
import 'package:rusa/screens/caissier/CaissierAddClientScreen.dart';
import 'package:rusa/screens/caissier/CaissierClientsListScreen.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';

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
    return n.toStringAsFixed(2);
  }

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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF29F58B)),
            )
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
                        _buildQuickActions(),
                        const SizedBox(height: 20),

                        _buildStatsModern(
                          moyenneTransaction: _fmt(stats['moyenneTransaction']),
                          nombrePassagers: '${stats['nombrePassagers'] ?? 0}',
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
              color: Colors.black.withOpacity(0.4),
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
      (icon: Icons.confirmation_num_outlined, onTap: () {}),
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildUserAvatar(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bonjour \u{1F44B}', // Emoji main qui fait coucou
                style: TextStyle(color: Color(0xFF093120), fontSize: 13),
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

  Widget _buildUserAvatar() {
    final rawPhoto = _userPhotoUrl?.trim() ?? '';
    final hasPhoto = rawPhoto.isNotEmpty;

    if (hasPhoto &&
        (rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://'))) {
      return ClipOval(
        child: Image.network(
          rawPhoto,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/profil.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    if (hasPhoto) {
      final bytes = _decodeBase64Image(rawPhoto);
      if (bytes != null) {
        return ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          ),
        );
      }
    }

    return ClipOval(
      child: Image.asset(
        'assets/images/profil.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
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
    required String moyenneTransaction,
    required String nombrePassagers,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistiques",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$moyenneTransaction FC",
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                "$nombrePassagers passagers",
                style: const TextStyle(color: Colors.white38),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => _buildBar(
                (i == 2) ? 45 : (10 + i * 5).toDouble(),
                i == 2 ? const Color(0xFF29F58B) : Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
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
