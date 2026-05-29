import 'package:rusa/models/reservation_with_paiement_response.dart';

enum FlexPayPaymentState { pending, confirmed, failed, expired }

class FlexPayVerifyResult {
  final FlexPayPaymentState state;
  final String? message;
  final ReservationWithPaiementResponse? reservation;
  final Map<String, dynamic>? raw;

  const FlexPayVerifyResult({
    required this.state,
    this.message,
    this.reservation,
    this.raw,
  });

  bool get isTerminal =>
      state == FlexPayPaymentState.confirmed ||
      state == FlexPayPaymentState.failed ||
      state == FlexPayPaymentState.expired;
}
