import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rusa/models/thermal_receipt_view_data.dart';

/// Génère le PDF thermique Rusa (format 70 mm, aligné invoice_generator).
class RusaThermalReceiptPdf {
  RusaThermalReceiptPdf._();

  static Future<pw.Document> buildDocument(ThermalReceiptViewData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: ThermalReceiptFormat.pdfPageFormat,
        build: (_) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildInfoBlock(data),
              _buildVoyageSection(data),
              ...data.billets.map((b) => _buildBilletSection(data, b)),
              _buildTotalSection(data),
              _buildClientSection(data),
              _buildPaymentSection(data),
              _buildFooter(),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text(
            'RUSA TRAVEL',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'REÇU DE VENTE',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(child: pw.Divider()),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildInfoBlock(ThermalReceiptViewData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text(
            'Ref: #${data.idReservation}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'Date: ${data.printedAtLabel}',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if (data.nomAgent?.trim().isNotEmpty == true) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              'Agent: ${data.nomAgent}',
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
        pw.SizedBox(height: 5),
      ],
    );
  }

  static pw.Widget _buildVoyageSection(ThermalReceiptViewData data) {
    final rows = <pw.TableRow>[
      _tableHeaderRow('Champ', 'Valeur'),
      _tableDataRow('Trajet', data.routeLabel),
      _tableDataRow('Départ', '${data.dateLabel} ${data.heureLabel}'),
    ];
    if (data.vehicule?.trim().isNotEmpty == true) {
      rows.add(_tableDataRow('Véhicule', data.vehicule!));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETAIL DU VOYAGE:',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: rows,
        ),
        pw.SizedBox(height: 5),
      ],
    );
  }

  static pw.Widget _buildBilletSection(
    ThermalReceiptViewData data,
    ThermalReceiptBilletLine billet,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          data.billets.length > 1
              ? 'BILLET #${billet.idBillet}:'
              : 'DETAIL DU BILLET:',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: [
            _tableHeaderRow('Champ', 'Valeur'),
            _tableDataRow('Passager', billet.nomPassager.toUpperCase()),
            _tableDataRow('Siège', billet.codeSiege),
            _tableDataRow('N° billet', '#${billet.idBillet}'),
          ],
        ),
        pw.SizedBox(height: 6),
        if (!billet.isUsed && billet.qrCode.isNotEmpty)
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: billet.qrCode,
              width: 72,
              height: 72,
            ),
          )
        else
          pw.Center(
            child: pw.Text(
              'BILLET DÉJÀ UTILISÉ',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildTotalSection(ThermalReceiptViewData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RECAPITULATIF:',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        _amountRow('Billets:', data.montantBilletsLabel),
        if (data.montantMajorationElectronique > 0) ...[
          pw.SizedBox(height: 2),
          _amountRow(
            'Frais plateforme Rusa Travel (${data.majorationDetailLabel}):',
            data.montantMajorationLabel,
          ),
        ],
        pw.SizedBox(height: 2),
        _amountRow('Total:', data.montantLabel, bold: true),
        if (data.isPaiementElectronique) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            'Frais de transaction ~2,5% sur le total (non inclus).',
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
          ),
        ],
        pw.SizedBox(height: 5),
        pw.Divider(),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _amountRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClientSection(ThermalReceiptViewData data) {
    final nom = data.nomClient?.trim() ?? '';
    final tel = data.telephoneClient?.trim() ?? '';
    if (nom.isEmpty && tel.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CLIENT:',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        if (nom.isNotEmpty) _labelValueRow('Nom:', nom, boldValue: true),
        if (tel.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _labelValueRow('Tel:', tel),
        ],
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildPaymentSection(ThermalReceiptViewData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PAIEMENT:',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        _labelValueRow('Mode:', data.paiementLabel, boldValue: true),
        pw.SizedBox(height: 2),
        _labelValueRow('Montant payé:', data.montantLabel, boldValue: true),
        if (data.referenceTransaction.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _labelValueRow('Ref:', data.referenceTransaction),
        ],
        pw.SizedBox(height: 4),
        pw.Divider(),
        pw.SizedBox(height: 3),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'MERCI DE VOTRE CONFIANCE !',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.TableRow _tableHeaderRow(String a, String b) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell(a, bold: true),
        _tableCell(b, bold: true),
      ],
    );
  }

  static pw.TableRow _tableDataRow(String label, String value) {
    return pw.TableRow(
      children: [
        _tableCell(label),
        _tableCell(value),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _labelValueRow(
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
