import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';

/// Charge les billets complets après confirmation de la réservation.
class CaissierBilletLoader {
  CaissierBilletLoader._();

  static bool _hasBillets(ReservationWithPaiementResponse data) {
    if (data.billets.isNotEmpty) {
      return data.billets.any((b) => b.qrCode.trim().isNotEmpty);
    }
    final billet = data.billet;
    return billet != null && billet.qrCode.trim().isNotEmpty;
  }

  /// Réessaie tant que les billets ne sont pas émis (délai backend / FlexPay).
  static Future<ReservationWithPaiementResponse?> fetchWhenReady({
    required int idReservation,
    int maxAttempts = 10,
    Duration interval = const Duration(seconds: 2),
    PaiementData? paiementHint,
  }) async {
    if (idReservation <= 0) return null;

    ReservationWithPaiementResponse? lastResponse;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final response = await ApiService.getBilletByReservation(idReservation);
      if (response != null) {
        lastResponse = _mergePaiementHint(response, paiementHint);
        if (_hasBillets(lastResponse)) {
          return lastResponse;
        }
      }
      if (attempt < maxAttempts - 1) {
        await Future.delayed(interval);
      }
    }
    return lastResponse;
  }

  static ReservationWithPaiementResponse _mergePaiementHint(
    ReservationWithPaiementResponse data,
    PaiementData? hint,
  ) {
    if (hint == null) return data;
    final pay = data.paiement;
    final merged = PaiementData(
      idPaiement: pay.idPaiement > 0 ? pay.idPaiement : hint.idPaiement,
      montantAPaye: pay.montantAPaye > 0 ? pay.montantAPaye : hint.montantAPaye,
      montantPaye: pay.montantPaye > 0 ? pay.montantPaye : hint.montantPaye,
      resteAPaye: pay.resteAPaye,
      methodePaiement: pay.methodePaiement.trim().isNotEmpty
          ? pay.methodePaiement
          : hint.methodePaiement,
      referenceTransaction: pay.referenceTransaction.trim().isNotEmpty
          ? pay.referenceTransaction
          : hint.referenceTransaction,
      statut: pay.statut,
      dateCreation: pay.dateCreation.isNotEmpty
          ? pay.dateCreation
          : hint.dateCreation,
      dateEmissionBillet: pay.dateEmissionBillet.isNotEmpty
          ? pay.dateEmissionBillet
          : hint.dateEmissionBillet,
      idBilletEmis: pay.idBilletEmis > 0 ? pay.idBilletEmis : hint.idBilletEmis,
      idReservation: pay.idReservation > 0 ? pay.idReservation : hint.idReservation,
      idSociete: pay.idSociete > 0 ? pay.idSociete : hint.idSociete,
      estComplet: pay.estComplet,
      estPartiel: pay.estPartiel,
    );
    return ReservationWithPaiementResponse(
      reservation: data.reservation,
      paiement: merged,
      billet: data.billet,
      billets: data.billets,
      transactionId: data.transactionId,
      statut: data.statut,
      message: data.message,
      dateCreation: data.dateCreation,
    );
  }
}
