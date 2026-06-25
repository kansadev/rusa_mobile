import 'package:pdf/pdf.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/models/voyage_model.dart';

/// Données normalisées pour le reçu thermique (widget + PDF).
class ThermalReceiptViewData {
  final int idReservation;
  final String? villeDepart;
  final String? villeArrivee;
  final String? dateVoyage;
  final String? heureVoyage;
  final String? vehicule;
  final String? nomClient;
  final String? telephoneClient;
  final String? nomAgent;
  final double montantBillets;
  final double montantMajorationElectronique;
  final double montant;
  final String devise;
  final bool isPaiementElectronique;
  final double? montAddUnitaire;
  final String methodePaiement;
  final String referenceTransaction;
  final List<ThermalReceiptBilletLine> billets;
  final DateTime printedAt;

  const ThermalReceiptViewData({
    required this.idReservation,
    this.villeDepart,
    this.villeArrivee,
    this.dateVoyage,
    this.heureVoyage,
    this.vehicule,
    this.nomClient,
    this.telephoneClient,
    this.nomAgent,
    required this.montantBillets,
    this.montantMajorationElectronique = 0,
    required this.montant,
    this.devise = 'FC',
    this.isPaiementElectronique = false,
    this.montAddUnitaire,
    required this.methodePaiement,
    required this.referenceTransaction,
    required this.billets,
    required this.printedAt,
  });

  factory ThermalReceiptViewData.fromReservationResponse(
    ReservationWithPaiementResponse data, {
    required String passengerFallback,
    Voyage? voyage,
    DateTime? printedAt,
    String? methodePaiementOverride,
  }) {
    final reservation = data.reservation;
    final paiement = data.paiement;
    final billetsRaw = data.billets.isNotEmpty
        ? data.billets
        : (data.billet != null ? [data.billet!] : <BilletData>[]);

    final montantPaye = paiement.montantPaye;
    final montantAPaye = paiement.montantAPaye;
    final prixVoyage = reservation.prixVoyage ?? 0;
    final montantTotal = montantPaye > 0
        ? montantPaye
        : (montantAPaye > 0 ? montantAPaye : prixVoyage);

    final electronic = _isPaiementElectronique(
      _resolveMethodePaiement(
        paiement.methodePaiement,
        override: methodePaiementOverride,
      ),
    );
    final passagers = billetsRaw.length;
    var majoration = 0.0;
    double? montAddUnitaire;
    var devise = 'FC';

    if (voyage != null) {
      devise = _deviseAffichage(voyage);
      montAddUnitaire = voyage.montAddPaieElectronique;
      if (electronic && voyage.hasMajorationPaieElectronique && passagers > 0) {
        majoration = voyage.majorationPaieElectroniquePour(passagers);
      }
    }

    var montantBillets = montantTotal;
    if (majoration > 0 && montantTotal >= majoration) {
      montantBillets = montantTotal - majoration;
    }

    return ThermalReceiptViewData(
      idReservation: reservation.idReservation,
      villeDepart: reservation.villeDepart,
      villeArrivee: reservation.villeArrivee,
      dateVoyage: reservation.dateVoyage,
      heureVoyage: reservation.heureVoyage?.formattedTime,
      vehicule: reservation.numeroBus,
      nomClient: reservation.nomClient ?? passengerFallback,
      telephoneClient: reservation.telephoneClient,
      nomAgent: reservation.nomUtilisateur,
      montantBillets: montantBillets,
      montantMajorationElectronique: majoration,
      montant: montantTotal,
      devise: devise,
      isPaiementElectronique: electronic,
      montAddUnitaire: montAddUnitaire,
      methodePaiement: _resolveMethodePaiement(
        paiement.methodePaiement,
        override: methodePaiementOverride,
      ),
      referenceTransaction: paiement.referenceTransaction,
      billets: billetsRaw
          .map(
            (b) => ThermalReceiptBilletLine(
              idBillet: b.id,
              nomPassager: (b.nomPassager?.trim().isNotEmpty ?? false)
                  ? b.nomPassager!.trim()
                  : passengerFallback,
              codeSiege: b.codeSiege ?? 'N/A',
              qrCode: b.qrCode,
              isUsed: b.isUsed,
            ),
          )
          .toList(),
      printedAt: printedAt ?? DateTime.now(),
    );
  }

  static String _resolveMethodePaiement(
    String raw, {
    String? override,
  }) {
    final forced = override?.trim() ?? '';
    if (forced.isNotEmpty) return forced;
    return raw.trim();
  }

  static bool _isPaiementElectronique(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'MOBILE_MONEY':
      case 'MOBILE MONEY':
      case 'CARTE_BANCAIRE':
      case 'CARTE BANCAIRE':
        return true;
      default:
        return false;
    }
  }

  static String _deviseAffichage(Voyage voyage) {
    final prix = voyage.codeDevisePrix?.trim();
    if (prix != null && prix.isNotEmpty) return prix;
    final principale = voyage.codeDevisePrincipale?.trim();
    if (principale != null && principale.isNotEmpty) return principale;
    return voyage.deviseMajorationPaieElectronique;
  }

  int get nombrePassagers => billets.length;

  String _formatMontant(double value) => '${value.toStringAsFixed(0)} $devise';

  String get montantLabel => _formatMontant(montant);

  String get montantBilletsLabel => _formatMontant(montantBillets);

  String get montantMajorationLabel => _formatMontant(montantMajorationElectronique);

  String get majorationDetailLabel {
    if (montantMajorationElectronique <= 0 || montAddUnitaire == null) {
      return montantMajorationLabel;
    }
    return '${nombrePassagers} x ${montAddUnitaire!.toStringAsFixed(0)} $devise';
  }

  String get routeLabel =>
      '${villeDepart?.trim().isNotEmpty == true ? villeDepart : 'N/A'} → '
      '${villeArrivee?.trim().isNotEmpty == true ? villeArrivee : 'N/A'}';

  String get dateLabel => _formatDate(dateVoyage);

  String get heureLabel => _formatTime(heureVoyage);

  String get paiementLabel => _formatPaymentMethod(methodePaiement);

  String get printedAtLabel {
    final d = printedAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  static String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }

  static String _formatPaymentMethod(String raw) {
    switch (raw.toUpperCase()) {
      case 'CASH':
      case 'ESPECES':
      case 'ESPÈCES':
        return 'Espèces';
      case 'MOBILE_MONEY':
      case 'MOBILE MONEY':
        return 'Mobile Money';
      case 'CARTE_BANCAIRE':
        return 'Carte bancaire';
      default:
        return raw.trim().isNotEmpty ? raw.trim() : 'N/A';
    }
  }
}

class ThermalReceiptBilletLine {
  final int idBillet;
  final String nomPassager;
  final String codeSiege;
  final String qrCode;
  final bool isUsed;

  const ThermalReceiptBilletLine({
    required this.idBillet,
    required this.nomPassager,
    required this.codeSiege,
    required this.qrCode,
    this.isUsed = false,
  });
}

/// Format thermique 70 mm (aligné invoice_generator).
class ThermalReceiptFormat {
  ThermalReceiptFormat._();

  static const double widthMm = 70;
  static const double heightMm = 350;
  static const double marginMm = 8;

  /// Largeur d'aperçu widget (~70 mm).
  static const double previewWidth = 265;

  static PdfPageFormat get pdfPageFormat => PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        heightMm * PdfPageFormat.mm,
        marginLeft: marginMm * PdfPageFormat.mm,
        marginRight: marginMm * PdfPageFormat.mm,
        marginTop: marginMm * PdfPageFormat.mm,
        marginBottom: marginMm * PdfPageFormat.mm,
      );
}
