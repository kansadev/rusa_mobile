import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mombongo/services/app_currency_preference.dart';
import 'package:mombongo/services/service_locator.dart';
import 'package:mombongo/services/cart_service.dart';
import 'package:mombongo/utils/invoice_receipt_helper.dart';
import 'package:mombongo/models/client.dart';
import 'package:mombongo/models/utilisateur.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_lib;
import 'package:printing/printing.dart';
import 'dart:io' as io;

class InvoiceGenerator {
  final BuildContext context;
  final CartService cartService;
  final Client? selectedClient;
  final dynamic saleResponse;
  final String invoiceNumber;
  final double? paidAmountOverride; // Optional override for paid amount
  final List<CartItem> invoiceItems;

  InvoiceGenerator({
    required this.context,
    required this.cartService,
    required this.selectedClient,
    required this.saleResponse,
    required this.invoiceNumber,
    this.paidAmountOverride,
    List<CartItem>? invoiceItems,
  }) : invoiceItems = invoiceItems ?? cartService.items;

  Future<void> generateAndShow() async {
    debugPrint('=== DEBUT GENERATION FACTURE ===');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Génération de la facture...'),
            ],
          ),
        );
      },
    );

    try {
      final pdf = await _createInvoicePDF();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await _showPrintOptionsDialog(pdf);
      }
    } catch (e) {
      debugPrint('Erreur génération facture: $e');
      if (context.mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération de la facture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pdf_lib.Document> _createInvoicePDF() async {
    final pdf = pdf_lib.Document();
    final currentUser = locator.authRepository.currentUser;

    pdf.addPage(
      pdf_lib.MultiPage(
        pageFormat: PdfPageFormat(
          70 * PdfPageFormat.mm,
          350 * PdfPageFormat.mm,
          marginLeft: 8 * PdfPageFormat.mm,
          marginRight: 8 * PdfPageFormat.mm,
          marginTop: 8 * PdfPageFormat.mm,
          marginBottom: 8 * PdfPageFormat.mm,
        ),
        build: (ctx) => [
          pdf_lib.Column(
            crossAxisAlignment: pdf_lib.CrossAxisAlignment.stretch,
            children: [
              _buildInvoiceHeader(currentUser),
              _buildInvoiceInfo(currentUser),
              _buildItemsTable(),
              _buildInvoiceSummary(),
              _buildPaymentInfo(),
              buildPdfServiceDescriptionsBlock(
                collectServiceDescriptionsForReceipt(invoiceItems),
              ),
              _buildInvoiceFooter(),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  pdf_lib.Widget _buildInvoiceHeader(Utilisateur? user) {
    final companyName = user?.nomSociete ?? 'KANSA BUSINESS';
    final siteName = user?.nomSite ?? 'SIEGE PRINCIPAL';
    final address = user?.adresseSite ?? '';
    final phone = user?.contact ?? '';

    // Charger le logo personnalisé du reçu depuis les préférences
    String receiptLogoPath = '';
    try {
      receiptLogoPath = locator.databaseService.get<String>('pref_receipt_logo_path') ?? '';
    } catch (e) {
      debugPrint('Erreur lors du chargement du logo du reçu: $e');
    }

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.center,
      children: [
        // Afficher le logo personnalisé s'il existe
        if (receiptLogoPath.isNotEmpty)
          pdf_lib.Container(
            height: 40,
            margin: const pdf_lib.EdgeInsets.only(bottom: 5),
            child: pdf_lib.Image(
              pdf_lib.MemoryImage(io.File(receiptLogoPath).readAsBytesSync()),
              fit: pdf_lib.BoxFit.contain,
            ),
          ),
        pdf_lib.Center(
          child: pdf_lib.Text(
            companyName,
            style: pdf_lib.TextStyle(
              fontSize: 10,
              fontWeight: pdf_lib.FontWeight.bold,
            ),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        pdf_lib.SizedBox(height: 3),
        pdf_lib.Center(
          child: pdf_lib.Text(
            siteName,
            style: pdf_lib.TextStyle(
              fontSize: 9,
              fontWeight: pdf_lib.FontWeight.bold,
            ),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        if (address.isNotEmpty) ...[
          pdf_lib.SizedBox(height: 3),
          pdf_lib.Center(
            child: pdf_lib.Text(
              address,
              style: pdf_lib.TextStyle(fontSize: 8),
              textAlign: pdf_lib.TextAlign.center,
            ),
          ),
        ],
        if (phone.isNotEmpty) ...[
          pdf_lib.SizedBox(height: 3),
          pdf_lib.Center(
            child: pdf_lib.Text(
              phone,
              style: pdf_lib.TextStyle(fontSize: 8),
              textAlign: pdf_lib.TextAlign.center,
            ),
          ),
        ],
        pdf_lib.SizedBox(height: 5),
        pdf_lib.Center(child: pdf_lib.Divider()),
        pdf_lib.SizedBox(height: 4),
      ],
    );
  }

  pdf_lib.Widget _buildInvoiceInfo(Utilisateur? user) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final ref = saleResponse is Map
        ? (saleResponse['referencePaiement'] ?? invoiceNumber)
        : invoiceNumber;
    final agentName = user?.nomComplet ?? 'Agent';

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.center,
      children: [
        pdf_lib.Center(
          child: pdf_lib.Text(
            'Ref: $ref',
            style: pdf_lib.TextStyle(
              fontSize: 9,
              fontWeight: pdf_lib.FontWeight.bold,
            ),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        pdf_lib.SizedBox(height: 3),
        pdf_lib.Center(
          child: pdf_lib.Text(
            'Date: $dateStr $timeStr',
            style: pdf_lib.TextStyle(fontSize: 8),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        pdf_lib.SizedBox(height: 3),
        pdf_lib.Center(
          child: pdf_lib.Text(
            'Agent: $agentName',
            style: pdf_lib.TextStyle(fontSize: 8),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        pdf_lib.SizedBox(height: 5),
      ],
    );
  }

  pdf_lib.Widget _buildItemsTable() {
    final tauxService = locator.tauxService;

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
      children: [
        pdf_lib.Text(
          'DETAIL DES ARTICLES:',
          style: pdf_lib.TextStyle(
            fontSize: 9,
            fontWeight: pdf_lib.FontWeight.bold,
          ),
          textAlign: pdf_lib.TextAlign.left,
        ),
        pdf_lib.SizedBox(height: 4),
        pdf_lib.Table(
          border: pdf_lib.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pdf_lib.FlexColumnWidth(3),
            1: const pdf_lib.FixedColumnWidth(20),
            2: const pdf_lib.FixedColumnWidth(35),
          },
          children: [
            pdf_lib.TableRow(
              decoration: const pdf_lib.BoxDecoration(color: PdfColors.grey200),
              children: [
                pdf_lib.Padding(
                  padding: const pdf_lib.EdgeInsets.all(2),
                  child: pdf_lib.Text(
                    'Article',
                    style: pdf_lib.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf_lib.FontWeight.bold,
                    ),
                    textAlign: pdf_lib.TextAlign.left,
                  ),
                ),
                pdf_lib.Padding(
                  padding: const pdf_lib.EdgeInsets.all(2),
                  child: pdf_lib.Text(
                    'Qte',
                    style: pdf_lib.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf_lib.FontWeight.bold,
                    ),
                    textAlign: pdf_lib.TextAlign.center,
                  ),
                ),
                pdf_lib.Padding(
                  padding: const pdf_lib.EdgeInsets.all(2),
                  child: pdf_lib.Text(
                    'Prix',
                    style: pdf_lib.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf_lib.FontWeight.bold,
                    ),
                    textAlign: pdf_lib.TextAlign.right,
                  ),
                ),
              ],
            ),
            ...invoiceItems.map((item) {
              final articleName = item.article.libelle;
              final qty = item.quantity.toString();
              final price = tauxService.formatPrice(item.totalPrice);

              return pdf_lib.TableRow(
                children: [
                  pdf_lib.Padding(
                    padding: const pdf_lib.EdgeInsets.all(2),
                    child: buildPdfReceiptArticleNameCell(articleName),
                  ),
                  pdf_lib.Padding(
                    padding: const pdf_lib.EdgeInsets.all(2),
                    child: pdf_lib.Text(
                      qty,
                      style: pdf_lib.TextStyle(fontSize: 8),
                      textAlign: pdf_lib.TextAlign.center,
                    ),
                  ),
                  pdf_lib.Padding(
                    padding: const pdf_lib.EdgeInsets.all(2),
                    child: pdf_lib.Text(
                      price,
                      style: pdf_lib.TextStyle(fontSize: 8),
                      textAlign: pdf_lib.TextAlign.right,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        pdf_lib.SizedBox(height: 5),
      ],
    );
  }

  pdf_lib.Widget _buildInvoiceSummary() {
    final total = cartService.total;

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
      children: [
        pdf_lib.Text(
          'TOTAL:',
          style: pdf_lib.TextStyle(
            fontSize: 10,
            fontWeight: pdf_lib.FontWeight.bold,
          ),
          textAlign: pdf_lib.TextAlign.left,
        ),
        pdf_lib.SizedBox(height: 4),
        pdf_lib.Row(
          mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
          children: [
            pdf_lib.Text(
              'Total:',
              style: pdf_lib.TextStyle(
                fontSize: 10,
                fontWeight: pdf_lib.FontWeight.bold,
              ),
            ),
            pdf_lib.Text(
              AppCurrencyPreference.formatCurrency(total),
              style: pdf_lib.TextStyle(
                fontSize: 10,
                fontWeight: pdf_lib.FontWeight.bold,
              ),
            ),
          ],
        ),
        pdf_lib.SizedBox(height: 5),
        pdf_lib.Divider(),
        pdf_lib.SizedBox(height: 4),
      ],
    );
  }

  pdf_lib.Widget _buildPaymentInfo() {
    final paymentMethod = saleResponse is Map
        ? (saleResponse['modePaiement'] ?? 'Espèces')
        : 'Espèces';
    // Use paidAmountOverride if provided, otherwise try to get from saleResponse
    final double paidAmount;
    if (paidAmountOverride != null) {
      paidAmount = paidAmountOverride!;
    } else {
      paidAmount = saleResponse is Map
          ? (saleResponse['montant'] as num? ?? cartService.total).toDouble()
          : cartService.total;
    }

    // Total amount from cart (TVA already included by backend)
    final tauxService = locator.tauxService;
    final totalAmount = cartService.total;
    final remaining = (totalAmount - paidAmount).clamp(0.0, double.infinity);
    final ref = saleResponse is Map
        ? (saleResponse['referencePaiement'] ?? invoiceNumber)
        : invoiceNumber;
    final typeTransaction = saleResponse is Map
        ? (saleResponse['typeTransaction'] ?? 'Complete')
        : 'Complete';

    final clientName = selectedClient != null
        ? '${selectedClient!.prenom} ${selectedClient!.nom}'.trim()
        : '';
    final clientPhone = selectedClient?.telephone ?? '';
    final clientEmail = selectedClient?.email ?? '';

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
      children: [
        if (clientName.isNotEmpty) ...[
          pdf_lib.Text(
            'CLIENT:',
            style: pdf_lib.TextStyle(
              fontSize: 8,
              fontWeight: pdf_lib.FontWeight.bold,
            ),
            textAlign: pdf_lib.TextAlign.left,
          ),
          pdf_lib.SizedBox(height: 3),
          pdf_lib.Row(
            mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
            children: [
              pdf_lib.Text('Nom:', style: pdf_lib.TextStyle(fontSize: 7)),
              pdf_lib.Text(
                clientName,
                style: pdf_lib.TextStyle(
                  fontSize: 7,
                  fontWeight: pdf_lib.FontWeight.bold,
                ),
              ),
            ],
          ),
          if (clientPhone.isNotEmpty) ...[
            pdf_lib.SizedBox(height: 2),
            pdf_lib.Row(
              mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
              children: [
                pdf_lib.Text('Tel:', style: pdf_lib.TextStyle(fontSize: 7)),
                pdf_lib.Text(
                  clientPhone,
                  style: pdf_lib.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ],
          if (clientEmail.isNotEmpty) ...[
            pdf_lib.SizedBox(height: 2),
            pdf_lib.Row(
              mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
              children: [
                pdf_lib.Text('Email:', style: pdf_lib.TextStyle(fontSize: 7)),
                pdf_lib.Text(
                  clientEmail,
                  style: pdf_lib.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ],
          pdf_lib.SizedBox(height: 4),
        ],
        pdf_lib.Text(
          'PAIEMENT:',
          style: pdf_lib.TextStyle(
            fontSize: 8,
            fontWeight: pdf_lib.FontWeight.bold,
          ),
          textAlign: pdf_lib.TextAlign.left,
        ),
        pdf_lib.SizedBox(height: 3),
        pdf_lib.Row(
          mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
          children: [
            pdf_lib.Text('Mode:', style: pdf_lib.TextStyle(fontSize: 7)),
            pdf_lib.Text(
              paymentMethod,
              style: pdf_lib.TextStyle(
                fontSize: 7,
                fontWeight: pdf_lib.FontWeight.bold,
              ),
            ),
          ],
        ),
        pdf_lib.SizedBox(height: 2),
        pdf_lib.Row(
          mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
          children: [
            pdf_lib.Text(
              'Type de Transaction:',
              style: pdf_lib.TextStyle(fontSize: 7),
            ),
            pdf_lib.Text(
              typeTransaction,
              style: pdf_lib.TextStyle(
                fontSize: 7,
                fontWeight: pdf_lib.FontWeight.bold,
              ),
            ),
          ],
        ),

        pdf_lib.SizedBox(height: 2),
        pdf_lib.Row(
          mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
          children: [
            pdf_lib.Text(
              'Montant payé:',
              style: pdf_lib.TextStyle(fontSize: 7),
            ),
            pdf_lib.Text(
              tauxService.formatPrice(paidAmount),
              style: pdf_lib.TextStyle(
                fontSize: 7,
                fontWeight: pdf_lib.FontWeight.bold,
              ),
            ),
          ],
        ),
        if (remaining > 0) ...[
          pdf_lib.SizedBox(height: 2),
          pdf_lib.Row(
            mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
            children: [
              pdf_lib.Text('Reste dû:', style: pdf_lib.TextStyle(fontSize: 7)),
              pdf_lib.Text(
                '${AppCurrencyPreference.symbolFor(AppCurrencyPreference.readCode(locator.databaseService))}${AppCurrencyPreference.formatterFor(AppCurrencyPreference.readCode(locator.databaseService)).format(remaining)}',
                style: pdf_lib.TextStyle(
                  fontSize: 7,
                  fontWeight: pdf_lib.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        pdf_lib.SizedBox(height: 2),
        pdf_lib.Row(
          mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceBetween,
          children: [
            pdf_lib.Text('Ref:', style: pdf_lib.TextStyle(fontSize: 7)),
            pdf_lib.Text(ref, style: pdf_lib.TextStyle(fontSize: 7)),
          ],
        ),
        pdf_lib.SizedBox(height: 4),
        pdf_lib.Divider(),
        pdf_lib.SizedBox(height: 3),
      ],
    );
  }

  pdf_lib.Widget _buildInvoiceFooter() {
    // Charger le message personnalisé du pied de reçu depuis les préférences
    String receiptFooterMessage = '';
    try {
      receiptFooterMessage = locator.databaseService.get<String>('pref_receipt_footer_message') ?? '';
    } catch (e) {
      debugPrint('Erreur lors du chargement du message du pied de reçu: $e');
    }

    return pdf_lib.Column(
      crossAxisAlignment: pdf_lib.CrossAxisAlignment.center,
      children: [
        pdf_lib.SizedBox(height: 3),
        pdf_lib.Center(
          child: pdf_lib.Text(
            'MERCI DE VOTRE CONFIANCE !',
            style: pdf_lib.TextStyle(
              fontSize: 8,
              fontWeight: pdf_lib.FontWeight.bold,
            ),
            textAlign: pdf_lib.TextAlign.center,
          ),
        ),
        // Afficher le message personnalisé s'il existe
        if (receiptFooterMessage.isNotEmpty) ...[
          pdf_lib.SizedBox(height: 6),
          pdf_lib.Center(
            child: pdf_lib.Text(
              receiptFooterMessage,
              style: pdf_lib.TextStyle(
                fontSize: 6,
                fontStyle: pdf_lib.FontStyle.italic,
              ),
              textAlign: pdf_lib.TextAlign.center,
            ),
          ),
        ],
        pdf_lib.SizedBox(height: 6),
        
      ],
    );
  }

  Future<void> _showPrintOptionsDialog(pdf_lib.Document pdf) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Facture générée',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Que souhaitez-vous faire ?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            await _savePdfToFile(pdf);
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          'Sauvegarder',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            await _printPdf(pdf);
                          }
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: Text(
                          'Imprimer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePdfToFile(pdf_lib.Document pdf) async {
    try {
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (_) => bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Facture enregistrée avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPdf(pdf_lib.Document pdf) async {
    try {
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (_) => bytes, dynamicLayout: false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impression envoyée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
