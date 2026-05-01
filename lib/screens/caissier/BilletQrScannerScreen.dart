import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';

class BilletQrScannerScreen extends StatefulWidget {
  const BilletQrScannerScreen({super.key});

  @override
  State<BilletQrScannerScreen> createState() => _BilletQrScannerScreenState();
}

class _BilletQrScannerScreenState extends State<BilletQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingScan = false;
  String? _lastCode;

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

    final billet = await ApiService.getBilletByQrCode(raw);
    if (!mounted) return;

    if (billet == null) {
      await _triggerInvalidFeedback();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Billet invalide'),
          content: const Text(
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
      _isHandlingScan = false;
      await _controller.start();
      return;
    }

    await _showBilletResult(billet);
    _isHandlingScan = false;
    await _controller.start();
  }

  Future<void> _triggerInvalidFeedback() async {
    // Double impulsion pour bien différencier un scan invalide d'un scan valide.
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.vibrate();
  }

  Future<void> _showBilletResult(ReservationWithPaiementResponse data) async {
    final reservation = data.reservation;
    final paiement = data.paiement;
    final trajet =
        '${reservation.villeDepart ?? '-'} -> ${reservation.villeArrivee ?? '-'}';

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF141A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141A18),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Billet verifie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Client: ${reservation.nomClient ?? '-'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Telephone: ${reservation.telephoneClient ?? '-'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Trajet: $trajet',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Date voyage: ${reservation.dateVoyage ?? '-'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Bus: ${reservation.numeroBus ?? '-'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Montant paye: ${paiement.montantPaye.toStringAsFixed(2)} FC',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Statut reservation: ${reservation.statutReservation}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Scanner encore'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Terminer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Scanner billet',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A0F0D),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0A0F0D),
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
              'Placez le QR code du billet dans le cadre vert',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
