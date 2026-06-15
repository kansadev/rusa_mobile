import 'package:printing/printing.dart';
import 'package:rusa/models/thermal_receipt_view_data.dart';
import 'package:rusa/services/app_logger.dart';
import 'package:rusa/services/rusa_thermal_receipt_pdf.dart';

/// Impression directe du PDF thermique Rusa (sans capture widget).
class ThermalPrintService {
  ThermalPrintService._();

  static const _tag = '[ThermalPrint]';

  static Future<bool> printReceipt(ThermalReceiptViewData data) async {
    AppLogger.debug('$_tag Génération PDF reçu #${data.idReservation}');

    try {
      final doc = await RusaThermalReceiptPdf.buildDocument(data);
      final bytes = await doc.save();
      AppLogger.debug('$_tag PDF prêt: ${bytes.length} octets');

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        dynamicLayout: false,
        format: ThermalReceiptFormat.pdfPageFormat,
        name: 'recu_rusa_${data.idReservation}',
      );

      AppLogger.debug('$_tag Impression terminée');
      return true;
    } catch (e, stack) {
      AppLogger.error('$_tag ÉCHEC impression PDF', e, stack);
      return false;
    }
  }
}
