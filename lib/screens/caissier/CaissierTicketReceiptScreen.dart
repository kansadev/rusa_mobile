import 'package:flutter/material.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/models/thermal_receipt_view_data.dart';
import 'package:rusa/services/app_logger.dart';
import 'package:rusa/services/caissier_billet_loader.dart';
import 'package:rusa/services/thermal_print_service.dart';
import 'package:rusa/widgets/app_message.dart';
import 'package:rusa/widgets/thermal_ticket_receipt_card.dart';

/// Reçu caissier : charge les billets via API puis impression thermique directe.
class CaissierTicketReceiptScreen extends StatefulWidget {
  final int idReservation;
  final PaiementData? paiementHint;

  const CaissierTicketReceiptScreen({
    super.key,
    required this.idReservation,
    this.paiementHint,
  });

  @override
  State<CaissierTicketReceiptScreen> createState() =>
      _CaissierTicketReceiptScreenState();
}

class _CaissierTicketReceiptScreenState
    extends State<CaissierTicketReceiptScreen> {
  bool _isLoading = true;
  bool _isPrinting = false;
  String? _error;
  ReservationWithPaiementResponse? _data;
  ThermalReceiptViewData? _receiptViewData;

  @override
  void initState() {
    super.initState();
    _loadBillets();
  }

  Future<void> _loadBillets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await CaissierBilletLoader.fetchWhenReady(
      idReservation: widget.idReservation,
      paiementHint: widget.paiementHint,
    );

    if (!mounted) return;

    if (response == null) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de récupérer le billet. La réservation est peut-être encore en cours de traitement.';
      });
      return;
    }

    final billets = response.billets.isNotEmpty
        ? response.billets
        : (response.billet != null ? [response.billet!] : <BilletData>[]);

    if (billets.isEmpty || billets.every((b) => b.qrCode.trim().isEmpty)) {
      setState(() {
        _isLoading = false;
        _error =
            'Le billet n\'est pas encore disponible. Réessayez dans quelques instants.';
        _data = response;
      });
      return;
    }

    final passengerFallback =
        response.reservation.nomClient ??
        response.reservation.nomUtilisateur ??
        'N/A';

    setState(() {
      _isLoading = false;
      _data = response;
      _receiptViewData = ThermalReceiptViewData.fromReservationResponse(
        response,
        passengerFallback: passengerFallback,
      );
      _error = null;
    });
  }

  List<BilletData> get _billetsAffichage {
    final data = _data;
    if (data == null) return const [];
    if (data.billets.isNotEmpty) return data.billets;
    if (data.billet != null) return [data.billet!];
    return const [];
  }

  Future<void> _printReceipt() async {
    final receipt = _receiptViewData;
    if (_isPrinting || receipt == null) return;

    AppLogger.debug(
      '[CaissierReceipt] Impression PDF — '
      'idReservation=${widget.idReservation}, '
      'billets=${receipt.billets.length}',
    );

    setState(() => _isPrinting = true);
    try {
      final ok = await ThermalPrintService.printReceipt(receipt);
      if (!mounted) return;
      if (ok) {
        _showSnack('Reçu envoyé à l\'imprimante.');
      } else {
        _showSnack('Échec de l\'impression. Consultez les logs.', isError: true);
      }
    } catch (e, stack) {
      AppLogger.error('[CaissierReceipt] Exception impression', e, stack);
      if (mounted) {
        _showSnack('Erreur impression: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E8E3E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: const Text(
          'Reçu caisse',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00E676)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Récupération du billet...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : _error != null && _billetsAffichage.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppMessageState(
                    type: AppMessageType.error,
                    title: 'Billet indisponible',
                    message: _error!,
                    actions: [
                      FilledButton(
                        onPressed: _loadBillets,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _receiptViewData != null
                            ? ThermalTicketReceiptCard(data: _receiptViewData!)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: (_isPrinting || _receiptViewData == null)
                            ? null
                            : _printReceipt,
                        icon: _isPrinting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: Text(
                          _isPrinting ? 'Impression...' : 'Imprimer',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
