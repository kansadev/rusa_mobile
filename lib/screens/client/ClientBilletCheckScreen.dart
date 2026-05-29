import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rusa/models/billet_check_response.dart';
import 'package:rusa/services/api_service.dart';

class ClientBilletCheckScreen extends StatefulWidget {
  const ClientBilletCheckScreen({super.key});

  @override
  State<ClientBilletCheckScreen> createState() =>
      _ClientBilletCheckScreenState();
}

class _ClientBilletCheckScreenState extends State<ClientBilletCheckScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingScan = false;
  String? _lastCode;

  Future<void> _resetAndRestartScanner() async {
    _lastCode = null;
    _isHandlingScan = false;
    if (!mounted) return;
    await _controller.stop();
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetectBarcode(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (_lastCode == raw) return;

    _lastCode = raw;
    _isHandlingScan = true;

    await _controller.stop();

    final result = await ApiService.checkBillet(raw);
    if (!mounted) return;

    if (!result.success || result.data == null) {
      await _triggerInvalidFeedback();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Billet invalide'),
          content: Text(
            result.errorMessage ??
                'Billet invalide ou introuvable pour ce QR code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      await _resetAndRestartScanner();
      return;
    }

    await _showBilletStatus(result.data!);
    await _resetAndRestartScanner();
  }

  Future<void> _triggerInvalidFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.vibrate();
  }

  String _formatMoment(BilletCheckResponse r) {
    final m = r.momentDepart;
    if (m == null) return '-';
    final local = m.isUtc ? m.toLocal() : m;
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy à $hh:$min';
  }

  Future<void> _showBilletStatus(BilletCheckResponse data) async {
    final messenger = ScaffoldMessenger.of(context);
    final estUtilise = data.isUsed;
    final autorise = data.embarquementAutorise && !data.voyageDejaPasse;
    final texteStatut = data.statutReservation ?? data.statut ?? '';
    final dateTexte = _formatMoment(data);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: const Color(0xFF141A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            16 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  autorise && !estUtilise
                      ? 'Billet valide'
                      : 'Statut du billet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    estUtilise
                        ? Icons.cancel_outlined
                        : (autorise ? Icons.check_circle : Icons.info_outline),
                    color: estUtilise
                        ? Colors.redAccent
                        : (autorise ? const Color(0xFF00E676) : Colors.orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      estUtilise
                          ? 'Ce billet a déjà été utilisé.'
                          : (autorise
                                ? 'Votre billet est valide.'
                                : (data.voyageDejaPasse
                                      ? 'Le voyage associé à ce billet est déjà passé.'
                                      : (data.message ??
                                            'Ce billet ne peut pas être utilisé pour l’instant.'))),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 4),
              Text(
                'Départ prévu : $dateTexte',
                style: const TextStyle(color: Colors.white70),
              ),
              if (texteStatut.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Statut réservation : $texteStatut',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              if (data.message != null && data.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.message!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _resetAndRestartScanner();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Vérification terminée.'),
                        backgroundColor: Color(0xFF00E676),
                      ),
                    );
                  },
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vérifier mon billet',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF121212),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetectBarcode,
                ),
                IgnorePointer(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF29F58B),
                          width: 3,
                        ),
                        color: Colors.transparent,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300E676),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Place ton QR code de billet dans le cadre vert pour vérifier sa validité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
