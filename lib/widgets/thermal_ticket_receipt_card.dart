import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rusa/models/thermal_receipt_view_data.dart';

/// Aperçu du reçu thermique Rusa (même structure que le PDF imprimé).
class ThermalTicketReceiptCard extends StatelessWidget {
  final ThermalReceiptViewData data;

  const ThermalTicketReceiptCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ThermalReceiptFormat.previewWidth,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildInfoBlock(),
          _buildVoyageSection(),
          ...data.billets.map(_buildBilletSection),
          _buildTotalSection(),
          _buildClientSection(),
          _buildPaymentSection(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'RUSA TRAVEL',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'REÇU DE VENTE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        Divider(color: Colors.black38, height: 1),
        SizedBox(height: 4),
      ],
    );
  }

  Widget _buildInfoBlock() {
    return Column(
      children: [
        Text(
          'Ref: #${data.idReservation}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Date: ${data.printedAtLabel}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        if (data.nomAgent?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text(
            'Agent: ${data.nomAgent}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildVoyageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAIL DU VOYAGE:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.grey, width: 0.5),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _tableHeaderRow('Champ', 'Valeur'),
            _tableDataRow('Trajet', data.routeLabel),
            _tableDataRow('Départ', '${data.dateLabel} ${data.heureLabel}'),
            if (data.vehicule?.trim().isNotEmpty == true)
              _tableDataRow('Véhicule', data.vehicule!),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildBilletSection(ThermalReceiptBilletLine billet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.billets.length > 1
              ? 'BILLET #${billet.idBillet}:'
              : 'DETAIL DU BILLET:',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.grey, width: 0.5),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _tableHeaderRow('Champ', 'Valeur'),
            _tableDataRow('Passager', billet.nomPassager.toUpperCase()),
            _tableDataRow('Siège', billet.codeSiege),
            _tableDataRow('N° billet', '#${billet.idBillet}'),
          ],
        ),
        const SizedBox(height: 6),
        if (!billet.isUsed && billet.qrCode.isNotEmpty)
          Center(
            child: QrImageView(
              data: billet.qrCode,
              version: QrVersions.auto,
              size: 110,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          )
        else
          const Center(
            child: Text(
              'BILLET DÉJÀ UTILISÉ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECAPITULATIF:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        _amountRow('Billets:', data.montantBilletsLabel),
        if (data.montantMajorationElectronique > 0) ...[
          const SizedBox(height: 2),
          _amountRow('Frais transaction (${data.majorationDetailLabel}):',
              data.montantMajorationLabel),
        ],
        const SizedBox(height: 2),
        _amountRow('Total:', data.montantLabel, bold: true),
        if (data.isPaiementElectronique) ...[
          const SizedBox(height: 4),
          const Text(
            'Frais passerelle ~2,5% sur le total (non inclus).',
            style: TextStyle(fontSize: 8, color: Colors.black54, height: 1.3),
          ),
        ],
        const SizedBox(height: 5),
        const Divider(color: Colors.black38, height: 1),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _amountRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    final nom = data.nomClient?.trim() ?? '';
    final tel = data.telephoneClient?.trim() ?? '';
    if (nom.isEmpty && tel.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLIENT:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        if (nom.isNotEmpty) _labelValueRow('Nom:', nom, boldValue: true),
        if (tel.isNotEmpty) ...[
          const SizedBox(height: 2),
          _labelValueRow('Tel:', tel),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAIEMENT:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        _labelValueRow('Mode:', data.paiementLabel, boldValue: true),
        const SizedBox(height: 2),
        _labelValueRow('Montant payé:', data.montantLabel, boldValue: true),
        if (data.referenceTransaction.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          _labelValueRow('Ref:', data.referenceTransaction),
        ],
        const SizedBox(height: 4),
        const Divider(color: Colors.black38, height: 1),
        const SizedBox(height: 3),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        SizedBox(height: 3),
        Text(
          'MERCI DE VOTRE CONFIANCE !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6),
      ],
    );
  }

  TableRow _tableHeaderRow(String a, String b) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        _tableCell(a, bold: true),
        _tableCell(b, bold: true),
      ],
    );
  }

  TableRow _tableDataRow(String label, String value) {
    return TableRow(
      children: [
        _tableCell(label),
        _tableCell(value),
      ],
    );
  }

  Widget _tableCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _labelValueRow(
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
