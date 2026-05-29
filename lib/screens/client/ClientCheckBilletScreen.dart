import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rusa/models/billet_check_response.dart';
import 'package:rusa/services/api_service.dart';

class ClientCheckBilletScreen extends StatefulWidget {
  const ClientCheckBilletScreen({super.key});

  @override
  State<ClientCheckBilletScreen> createState() =>
      _ClientCheckBilletScreenState();
}

class _ClientCheckBilletScreenState extends State<ClientCheckBilletScreen>
    with SingleTickerProviderStateMixin {
  static const double _frameSize = 260;

  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _scanAnimController;
  late final Animation<double> _scanY;

  bool _isHandling = false;
  String? _lastCode;
  Timer? _slowVerifyTimer;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scanY = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slowVerifyTimer?.cancel();
    _scanAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Ferme le dialogue « Vérification en cours » s’il est encore ouvert (navigator racine).
  void _popVerificationLoadingDialogIfAny() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  /// Ferme d’abord tout overlay de chargement racine, puis la bottom sheet résultat.
  void _closeResultSheetAndVerificationDialog(BuildContext sheetCtx) {
    _popVerificationLoadingDialogIfAny();
    //Navigator.pop(sheetCtx);
  }

  void _setScanningPaused(bool paused) {
    if (paused) {
      _scanAnimController.stop();
    } else {
      _scanAnimController.repeat(reverse: true);
    }
  }

  String _formatDepart(BilletCheckResponse r) {
    final m = r.momentDepart;
    if (m == null) return '—';
    final d =
        '${m.day.toString().padLeft(2, '0')}/${m.month.toString().padLeft(2, '0')}/${m.year}';
    final t =
        '${m.hour.toString().padLeft(2, '0')}:${m.minute.toString().padLeft(2, '0')}';
    return '$d à $t';
  }

  ({Color color, IconData icon, String title, String subtitle}) _verdict(
    BilletCheckResponse r,
  ) {
    if (r.voyageDejaPasse) {
      return (
        color: const Color(0xFFFF9800),
        icon: Icons.event_busy_rounded,
        title: 'Date de voyage dépassée',
        subtitle:
            'Le départ associé à ce billet est dans le passé. Départ prévu : ${_formatDepart(r)}.',
      );
    }
    if (r.isUsed) {
      return (
        color: const Color(0xFFE53935),
        icon: Icons.cancel_rounded,
        title: 'Billet déjà utilisé',
        subtitle: r.message?.trim().isNotEmpty == true
            ? r.message!.trim()
            : 'Ce billet a déjà été scanné ou enregistré comme utilisé.',
      );
    }
    if (!r.embarquementAutorise) {
      return (
        color: const Color(0xFFFFB300),
        icon: Icons.warning_amber_rounded,
        title: 'Embarquement non autorisé pour le moment',
        subtitle: r.message?.trim().isNotEmpty == true
            ? r.message!.trim()
            : 'Vérifiez le statut de votre réservation (${r.statutReservation ?? "—"}).',
      );
    }
    return (
      color: const Color(0xFF00E676),
      icon: Icons.verified_rounded,
      title: 'Votre billet est valide',
      subtitle:
          'Départ prévu le ${_formatDepart(r)}. '
          'Réservation : ${r.statutReservation ?? "—"}.',
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (_lastCode == raw) return;
    _lastCode = raw;
    _isHandling = true;
    _setScanningPaused(true);
    await _controller.stop();

    var slowDialogShown = false;
    _slowVerifyTimer?.cancel();
    _slowVerifyTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || !_isHandling) return;
      slowDialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Vérification en cours…',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });

    late final BilletCheckApiResult result;
    try {
      result = await ApiService.checkBillet(raw);
    } finally {
      _slowVerifyTimer?.cancel();
      _slowVerifyTimer = null;
    }

    if (!mounted) return;

    if (slowDialogShown) {
      _popVerificationLoadingDialogIfAny();
    }

    if (!result.success || result.data == null) {
      await HapticFeedback.heavyImpact();
      if (!mounted) return;
      await _showResultSheet(
        errorOnly: true,
        errorMessage:
            result.errorMessage ?? 'Impossible de vérifier ce billet.',
      );
    } else {
      await HapticFeedback.mediumImpact();
      final v = _verdict(result.data!);
      if (!mounted) return;
      await _showResultSheet(data: result.data!, verdict: v);
    }

    _lastCode = null;
    _isHandling = false;
    if (mounted) {
      _setScanningPaused(false);
      await _controller.start();
    }
  }

  Future<void> _showResultSheet({
    BilletCheckResponse? data,
    ({Color color, IconData icon, String title, String subtitle})? verdict,
    bool errorOnly = false,
    String? errorMessage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        if (errorOnly) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Échec de la vérification',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _closeResultSheetAndVerificationDialog(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        final d = data!;
        final v = verdict!;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: v.color.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    Icon(v.icon, color: v.color, size: 52),
                    const SizedBox(height: 12),
                    Text(
                      v.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      v.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (d.message != null && d.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  d.message!.trim(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _detailRow('N° réservation', '${d.idReservation}'),
              _detailRow('Statut réservation', d.statutReservation ?? '—'),
              _detailRow('Billet', '#${d.idBillet}'),
              _detailRow('Statut', d.statut ?? '—'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _closeResultSheetAndVerificationDialog(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cadre type « scanner » : bordure lumineuse + ligne laser animée verticalement.
  Widget _buildScanFrame() {
    const green = Color(0xFF00E676);
    const radius = 16.0;
    const borderW = 3.0;
    final innerSide = _frameSize - 2 * borderW;

    return SizedBox(
      width: _frameSize,
      height: _frameSize,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: green, width: borderW),
          boxShadow: [
            BoxShadow(
              color: green.withValues(alpha: 0.38),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - borderW),
          child: SizedBox(
            width: innerSide,
            height: innerSide,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          green.withValues(alpha: 0.07),
                          Colors.transparent,
                          green.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scanY,
                  builder: (context, _) {
                    const lineH = 4.0;
                    final travel = (innerSide - lineH).clamp(
                      0.0,
                      double.infinity,
                    );
                    final top = _scanY.value * travel;
                    return Positioned(
                      left: 12,
                      right: 12,
                      top: top,
                      height: lineH,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              green.withValues(alpha: 0.2),
                              green,
                              green.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: green.withValues(alpha: 0.85),
                              blurRadius: 14,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Vérifier mon billet',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Placez le QR code du billet dans le cadre pour vérifier sa validité.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(child: Center(child: _buildScanFrame())),
        ],
      ),
    );
  }
}
