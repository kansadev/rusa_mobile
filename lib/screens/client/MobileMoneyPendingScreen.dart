import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/reservation_with_passengers_request.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/flexpay_payment_tracker.dart';

import 'CardPaymentWebViewScreen.dart';
import 'TicketReceiptScreen.dart';

class MobileMoneyPendingScreen extends StatefulWidget {
  final ReservationWithPassengersAndPaiementRequest request;
  final bool isVenteCaissier;

  const MobileMoneyPendingScreen({
    super.key,
    required this.request,
    required this.isVenteCaissier,
  });

  @override
  State<MobileMoneyPendingScreen> createState() =>
      _MobileMoneyPendingScreenState();
}

class _MobileMoneyPendingScreenState extends State<MobileMoneyPendingScreen> {
  bool _isLoading = true;
  bool _isTrackingPayment = false;
  String? _error;
  dynamic _response;
  Map<String, dynamic>? _pending;
  bool _paymentUrlOpenedAuto = false;
  FlexPayPaymentTracker? _paymentTracker;
  String? _orderNumberFlexPay;
  DateTime? _holdExpireAt;

  String get _paymentMethodTitle {
    final method = widget.request.paiement.methodePaiement.trim().toUpperCase();
    switch (method) {
      case 'CARTE_BANCAIRE':
      case 'CARTE BANCAIRE':
        return 'Paiement Carte';
      case 'MOBILE_MONEY':
      case 'MOBILE MONEY':
        return 'Paiement Mobile Money';
      case 'CASH':
      case 'ESPECES':
      case 'ESPÈCES':
        return 'Paiement Cash';
      default:
        return 'Paiement';
    }
  }

  @override
  void initState() {
    super.initState();
    _submit();
  }

  @override
  void dispose() {
    _paymentTracker?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _paymentTracker?.dispose();
    _paymentTracker = null;
    setState(() {
      _isLoading = true;
      _isTrackingPayment = false;
      _error = null;
      _orderNumberFlexPay = null;
      _holdExpireAt = null;
    });

    final result = await ApiService.reservationWithPassengersAndPaiement(
      widget.request,
    );

    if (!mounted) return;

    if (!result.isSuccess || result.response == null) {
      if (result.pendingData != null) {
        setState(() {
          _isLoading = false;
          _pending = result.pendingData;
          _response = null;
        });
        _tryOpenPaymentUrlAuto();
        _startFlexPayTracking(result.pendingData!);
        return;
      }
      setState(() {
        _isLoading = false;
        _error = result.errorMessage ?? 'Échec du paiement Mobile Money.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _response = result.response;
      _pending = result.pendingData;
    });
    _tryOpenPaymentUrlAuto();
    if (result.pendingData != null) {
      _startFlexPayTracking(result.pendingData!);
    }
  }

  void _startFlexPayTracking(Map<String, dynamic> pending) {
    final order = pending['orderNumberFlexPay']?.toString().trim();
    if (order == null || order.isEmpty) {
      debugPrint('FlexPay: orderNumberFlexPay absent, suivi temps réel ignoré.');
      return;
    }

    final holdRaw = pending['holdExpireAt']?.toString();
    DateTime? holdExpire;
    if (holdRaw != null && holdRaw.isNotEmpty) {
      holdExpire = DateTime.tryParse(holdRaw);
    }

    _orderNumberFlexPay = order;
    _holdExpireAt = holdExpire;

    _paymentTracker?.dispose();
    _paymentTracker = FlexPayPaymentTracker(
      orderNumberFlexPay: order,
      holdExpireAt: holdExpire,
      onConfirmed: _onPaymentConfirmed,
      onFailed: _onPaymentFailed,
      onExpired: _onPaymentExpired,
    );

    setState(() => _isTrackingPayment = true);
    _paymentTracker!.start();
  }

  Future<void> _onPaymentConfirmed(
    ReservationWithPaiementResponse? reservation,
    String? message,
  ) async {
    if (!mounted) return;

    var resolved = reservation;
    if (resolved == null && _orderNumberFlexPay != null) {
      final verify = await ApiService.verifyFlexPayOrder(_orderNumberFlexPay!);
      resolved = verify.reservation;
    }

    setState(() {
      _isTrackingPayment = false;
      if (resolved != null) {
        _response = resolved;
        _error = null;
      } else {
        _error = null;
        _pending = {
          ...?_pending,
          'message': ?message,
        };
      }
    });

    if (resolved != null) {
      _goToReceipt();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Paiement confirmé.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
    Navigator.pop(context, true);
  }

  void _onPaymentFailed(String message) {
    if (!mounted) return;
    setState(() {
      _isTrackingPayment = false;
      _error = message;
      _response = null;
    });
  }

  void _onPaymentExpired(String message) {
    if (!mounted) return;
    setState(() {
      _isTrackingPayment = false;
      _error = message;
      _response = null;
    });
  }

  void _goToReceipt() {
    final response = _response;
    if (response is! ReservationWithPaiementResponse) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketReceiptScreen(
          reservationData: response.reservation,
          paiementData: response.paiement,
          billetData: response.billet,
          billets: response.billets,
        ),
      ),
    );
  }

  String _pendingMessage() {
    final msg = _pending?['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return 'Validez le paiement sur votre téléphone. La réservation sera créée après confirmation.';
  }

  String? _holdExpireLabel() {
    final expire = _holdExpireAt;
    if (expire == null) return null;
    final local = expire.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return 'Expire à $h:$m';
  }

  String? get _paymentUrl {
    final raw = _pending?['paymentUrl']?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> _openPaymentUrl() async {
    final url = _paymentUrl;
    if (url == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPaymentWebViewScreen(paymentUrl: url),
      ),
    );
  }

  void _tryOpenPaymentUrlAuto() {
    if (_paymentUrlOpenedAuto) return;
    final url = _paymentUrl;
    if (url == null) return;
    _paymentUrlOpenedAuto = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPaymentUrl();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          _paymentMethodTitle,
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isTrackingPayment ? null : () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Préparation du paiement...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cela peut prendre quelques instants selon la qualité de votre connexion internet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Réessayer'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    ),
                  ],
                )
              : _response != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00E676),
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isVenteCaissier
                          ? 'Vente enregistrée avec succès.'
                          : 'Paiement confirmé.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _goToReceipt,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Voir le reçu'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTrackingPayment) ...[
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFF00E676),
                        size: 52,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _isTrackingPayment
                          ? 'Confirmation en cours...'
                          : 'Paiement en attente de confirmation',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTrackingPayment
                          ? 'Nous attendons la validation FlexPay. Ne fermez pas cette page.'
                          : _pendingMessage(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    if (_orderNumberFlexPay != null &&
                        _orderNumberFlexPay!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Commande: $_orderNumberFlexPay',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_holdExpireLabel() != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _holdExpireLabel()!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (_paymentUrl != null) ...[
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _openPaymentUrl,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Ouvrir le lien de paiement'),
                      ),
                    ],
                    if (!_isTrackingPayment) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
