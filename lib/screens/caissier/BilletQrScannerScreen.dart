import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/widgets/camera_scanner_shell.dart';

/// Début de la fenêtre côté app : embarquement autorisé au plus tôt avant le départ.
const Duration _kEmbarquementMaxAvantDepart = Duration(hours: 6);

/// Fin de la fenêtre : tolérance après l’heure prévue du trajet.
const Duration _kEmbarquementMaxApresDepart = Duration(minutes: 45);

String _formatDateHeureCourt(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final y = d.year;
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$y à $hh:$min';
}

/// Date/heure de départ prévue pour le contrôle d’embarquement (QR caissier).
DateTime? _parseDepartPrevuePourEmbarquement(ReservationData r) {
  final raw = r.dateVoyage?.trim();
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final local = parsed.isUtc ? parsed.toLocal() : parsed;
  final hv = r.heureVoyage;
  if (hv != null && local.hour == 0 && local.minute == 0 && local.second == 0) {
    return DateTime(
      local.year,
      local.month,
      local.day,
      hv.hours,
      hv.minutes,
      hv.seconds,
    );
  }
  return local;
}

/// Règle locale : hors fenêtre → pas de bouton « embarquer » (l’API peut aussi refuser).
({bool autorise, String? message}) _evaluerFenetreEmbarquement(
  ReservationData r,
) {
  final depart = _parseDepartPrevuePourEmbarquement(r);
  if (depart == null) {
    return (autorise: true, message: null);
  }
  final now = DateTime.now();
  final debutFenetre = depart.subtract(_kEmbarquementMaxAvantDepart);
  final finFenetre = depart.add(_kEmbarquementMaxApresDepart);
  if (now.isBefore(debutFenetre)) {
    return (
      autorise: false,
      message:
          'Trop tôt pour embarquer ce passager. '
          'Ouverture à partir du ${_formatDateHeureCourt(debutFenetre)} '
          '(départ prévu ${_formatDateHeureCourt(depart)}).',
    );
  }
  if (now.isAfter(finFenetre)) {
    return (
      autorise: false,
      message:
          'Fenêtre d’embarquement dépassée pour ce trajet '
          '(le départ prévu était ${_formatDateHeureCourt(depart)}).',
    );
  }
  return (autorise: true, message: null);
}

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
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF141A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var embarquementLoading = false;
        var embarquementOk = false;
        var embarquementErreur = '';
        var billetCourant = data.billet;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              final b = billetCourant;
              final idSociete = (b?.idSociete ?? 0) > 0
                  ? b!.idSociete
                  : reservation.idSociete;
              final idPassager = b?.idReservationPassenger ?? 0;
              final idBillet = b?.id ?? 0;
              final dejaUtilise = b?.isUsed == true;
              final fenetreEmb = _evaluerFenetreEmbarquement(reservation);
              final peutEmbarquer =
                  b != null &&
                  !dejaUtilise &&
                  !embarquementOk &&
                  idSociete > 0 &&
                  idPassager > 0 &&
                  idBillet > 0 &&
                  fenetreEmb.autorise;

              Future<void> onEmbarquer() async {
                setModal(() {
                  embarquementLoading = true;
                  embarquementErreur = '';
                });
                final result = await ApiService.embarquerPassagerBillet(
                  idSociete: idSociete,
                  idReservationPassenger: idPassager,
                  idBillet: idBillet,
                );
                if (!mounted) return;
                setModal(() {
                  embarquementLoading = false;
                  if (result.success) {
                    embarquementOk = true;
                    if (result.billet != null) {
                      billetCourant = result.billet;
                    } else {
                      final prev = billetCourant;
                      if (prev != null) {
                        billetCourant = BilletData(
                          id: prev.id,
                          qrCode: prev.qrCode,
                          dateGeneration: prev.dateGeneration,
                          idReservation: prev.idReservation,
                          idClient: prev.idClient,
                          idSociete: prev.idSociete,
                          urlBillet: prev.urlBillet,
                          idReservationPassenger: prev.idReservationPassenger,
                          isUsed: true,
                        );
                      }
                    }
                  } else {
                    embarquementErreur = result.message;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              }

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141A18),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Billet vérifié',
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
                        'Téléphone: ${reservation.telephoneClient ?? '-'}',
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
                        'Montant payé: ${paiement.montantPaye.toStringAsFixed(2)} FC',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Statut réservation: ${reservation.statutReservation}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (b != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Billet n° $idBillet${dejaUtilise ? ' — déjà utilisé' : ''}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (b == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Détail billet absent : embarquement impossible depuis cet écran.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else if (idPassager <= 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Identifiant passager (réservation) absent : '
                            'l’API doit renvoyer idReservationPassenger sur le billet.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else if (!fenetreEmb.autorise &&
                          fenetreEmb.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            fenetreEmb.message!,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (embarquementOk) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF00E676)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Passager marqué comme embarqué.',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (embarquementErreur.isNotEmpty && !embarquementOk)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            embarquementErreur,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      if (peutEmbarquer)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: embarquementLoading ? null : onEmbarquer,
                            icon: embarquementLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.directions_bus_filled),
                            label: Text(
                              embarquementLoading
                                  ? 'Enregistrement…'
                                  : 'Marquer comme embarqué',
                            ),
                          ),
                        ),
                      if (peutEmbarquer) const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Recommencer'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
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
              );
            },
          ),
        );
      },
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
            child: CameraScannerShell(
              controller: _controller,
              onDetect: _onDetectBarcode,
              permissionRationale:
                  'Pour contrôler les billets à l\'embarquement, l\'application '
                  'a besoin d\'accéder à la caméra pour lire les QR codes.',
              overlays: [
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
