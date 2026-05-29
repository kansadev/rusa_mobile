import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rusa/models/flexpay_verify_result.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef FlexPayConfirmedHandler = void Function(
  ReservationWithPaiementResponse? reservation,
  String? message,
);

typedef FlexPayFailedHandler = void Function(String message);

typedef FlexPayExpiredHandler = void Function(String message);

/// Suivi temps réel d'un paiement FlexPay (SignalR + polling de secours).
class FlexPayPaymentTracker {
  FlexPayPaymentTracker({
    required this.orderNumberFlexPay,
    this.holdExpireAt,
    required this.onConfirmed,
    required this.onFailed,
    this.onExpired,
    this.pollInterval = const Duration(seconds: 4),
    this.initialPollDelay = const Duration(seconds: 8),
  });

  final String orderNumberFlexPay;
  final DateTime? holdExpireAt;
  final FlexPayConfirmedHandler onConfirmed;
  final FlexPayFailedHandler onFailed;
  final FlexPayExpiredHandler? onExpired;
  final Duration pollInterval;

  /// Délai avant le 1er appel verifier (laisser le temps de valider sur le téléphone).
  final Duration initialPollDelay;

  HubConnection? _hub;
  Timer? _pollTimer;
  bool _completed = false;
  bool _polling = false;

  Future<void> start() async {
    await _connectSignalR();
    _schedulePoll(immediate: false);
    Future.delayed(initialPollDelay, () {
      if (!_completed) unawaited(_pollOnce());
    });
  }

  void dispose() {
    _completed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      hub.stop().catchError((_) {});
    }
  }

  bool get _isExpired {
    final expire = holdExpireAt;
    if (expire == null) return false;
    return DateTime.now().toUtc().isAfter(expire.toUtc());
  }

  Future<void> _connectSignalR() async {
    final token = await ApiService.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('FlexPay tracker: pas de JWT, SignalR ignoré (polling seul).');
      return;
    }

    try {
      final options = HttpConnectionOptions(
        accessTokenFactory: () async =>
            await ApiService.getAccessToken() ?? '',
      );

      final hub = HubConnectionBuilder()
          .withUrl(ApiService.signalRHubUrl, options: options)
          .withAutomaticReconnect()
          .build();

      hub.on('FlexPayPaymentConfirmed', _onSignalRConfirmed);
      hub.on('FlexPayPaymentFailed', _onSignalRFailed);

      hub.onclose(({error}) {
        debugPrint('FlexPay SignalR fermé: $error');
      });

      await hub.start();
      _hub = hub;
      debugPrint('FlexPay SignalR connecté: ${ApiService.signalRHubUrl}');
    } catch (e, stack) {
      debugPrint('FlexPay SignalR indisponible: $e\n$stack');
    }
  }

  void _schedulePoll({bool immediate = false}) {
    if (_completed) return;

    if (_isExpired) {
      _completeExpired();
      return;
    }

    if (immediate) {
      unawaited(_pollOnce());
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_completed || _polling) return;

    if (_isExpired) {
      _completeExpired();
      return;
    }

    _polling = true;
    try {
      final result = await ApiService.verifyFlexPayOrder(orderNumberFlexPay);
      if (_completed) return;
      _handleVerifyResult(result);
    } finally {
      _polling = false;
    }
  }

  void _onSignalRConfirmed(List<Object?>? arguments) {
    if (_completed) return;
    final payload = arguments != null && arguments.isNotEmpty
        ? arguments[0]
        : null;
    if (!_matchesOrder(payload)) return;

    final reservation = ApiService.reservationFromFlexPayPayload(payload);
    final message = ApiService.signalRPayloadMessage(payload);
    _completeConfirmed(reservation: reservation, message: message);
  }

  void _onSignalRFailed(List<Object?>? arguments) {
    if (_completed) return;
    final payload = arguments != null && arguments.isNotEmpty
        ? arguments[0]
        : null;
    if (!_matchesOrder(payload)) return;

    final message = ApiService.signalRPayloadMessage(payload) ??
        'Le paiement n\'a pas abouti. Veuillez réessayer.';
    _completeFailed(message);
  }

  /// N'accepte que les événements ciblant explicitement cette commande.
  bool _matchesOrder(dynamic payload) {
    final fromPayload = ApiService.signalRPayloadOrderNumber(payload);
    if (fromPayload == null || fromPayload.isEmpty) {
      debugPrint(
        'FlexPay SignalR: événement ignoré (orderNumber absent ou global).',
      );
      return false;
    }
    if (fromPayload != orderNumberFlexPay) {
      debugPrint(
        'FlexPay SignalR: événement ignoré (order=$fromPayload, '
        'attendu=$orderNumberFlexPay).',
      );
      return false;
    }
    return true;
  }

  void _handleVerifyResult(FlexPayVerifyResult result) {
    switch (result.state) {
      case FlexPayPaymentState.confirmed:
        _completeConfirmed(
          reservation: result.reservation,
          message: result.message,
        );
      case FlexPayPaymentState.failed:
        _completeFailed(
          result.message ??
              'Le paiement n\'a pas abouti. Veuillez réessayer.',
        );
      case FlexPayPaymentState.expired:
        _completeExpired(
          result.message ??
              'Délai de paiement expiré. Les places ont été libérées.',
        );
      case FlexPayPaymentState.pending:
        break;
    }
  }

  void _completeConfirmed({
    ReservationWithPaiementResponse? reservation,
    String? message,
  }) {
    if (_completed) return;
    _completed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      hub.stop().catchError((_) {});
    }
    onConfirmed(reservation, message);
  }

  void _completeFailed(String message) {
    if (_completed) return;
    _completed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      hub.stop().catchError((_) {});
    }
    onFailed(message);
  }

  void _completeExpired([String? message]) {
    if (_completed) return;
    _completed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      hub.stop().catchError((_) {});
    }
    final msg = message ??
        'Délai de paiement expiré. Les places ont été libérées.';
    if (onExpired != null) {
      onExpired!(msg);
    } else {
      onFailed(msg);
    }
  }
}
