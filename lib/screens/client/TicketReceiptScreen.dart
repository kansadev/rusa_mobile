import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rusa/models/billet_check_response.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';
import 'package:share_plus/share_plus.dart';

import 'BilletReaffectationScreen.dart';

class TicketReceiptScreen extends StatefulWidget {
  final ReservationData? reservationData;
  final PaiementData? paiementData;
  final BilletData? billetData;

  /// Plusieurs billets (même réservation). Si vide, seul [billetData] est affiché.
  final List<BilletData> billets;

  const TicketReceiptScreen({
    super.key,
    this.reservationData,
    this.paiementData,
    this.billetData,
    this.billets = const [],
  });

  @override
  State<TicketReceiptScreen> createState() => _TicketReceiptScreenState();
}

class _TicketReceiptScreenState extends State<TicketReceiptScreen> {
  final GlobalKey _ticketKey = GlobalKey();
  final PageController _billetCarouselController = PageController();
  bool _isSaving = false;
  int _carouselIndex = 0;

  @override
  void dispose() {
    _billetCarouselController.dispose();
    super.dispose();
  }

  /// Billets affichés (multi-billets ou billet unique).
  List<BilletData> get _billetsAffichage => widget.billets.isNotEmpty
      ? widget.billets
      : (widget.billetData != null ? [widget.billetData!] : <BilletData>[]);

  /// Billet actuellement visible dans le carrousel.
  BilletData? get _currentBillet {
    final list = _billetsAffichage;
    if (list.isEmpty) return null;
    final idx = _carouselIndex.clamp(0, list.length - 1);
    return list[idx];
  }

  Future<void> _reporterBillet() async {
    final billet = _currentBillet;
    if (billet == null || billet.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun billet à reporter.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final idSociete = billet.idSociete > 0
        ? billet.idSociete
        : await ApiService.getCurrentSocieteId();
    if (!mounted) return;

    final result = await Navigator.push<ReaffectationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BilletReaffectationScreen(
          idBillet: billet.id,
          idSociete: idSociete,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null && result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _formatTimeFromString(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'N/A';
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeString;
  }

  Future<Uint8List?> _captureTicket() async {
    try {
      final boundary =
          _ticketKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Partage le billet en image (menu système : WhatsApp, Galerie, Drive…).
  /// Aucune permission READ_MEDIA / galerie requise.
  Future<void> _shareAsImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pngBytes = await _captureTicket();
      if (pngBytes == null || !mounted) return;
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null || !mounted) return;
      final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));

      final tempDir = await getTemporaryDirectory();
      final fileName = 'billet_rusa_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(jpgBytes, flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/jpeg', name: fileName)],
          text: 'Mon billet Rusa Travel',
          subject: 'Billet Rusa Travel',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur lors du partage de l\'image.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Partage le billet en PDF via le menu système (sans permission stockage).
  Future<void> _shareAsPdf() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pngBytes = await _captureTicket();
      if (pngBytes == null || !mounted) return;

      final pdf = pw.Document();
      final memoryImage = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) =>
              pw.Center(child: pw.Image(memoryImage, fit: pw.BoxFit.contain)),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = 'billet_rusa_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(await pdf.save(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
          text: 'Mon billet Rusa Travel',
          subject: 'Billet Rusa Travel',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur lors du partage du PDF.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E8E3E),
      ),
    );
  }

  /// Une carte billet complète (bandeau vert + QR + trajet + séparateur + passager + date).
  Widget _buildFullTicketCard({
    required bool hasBillet,
    BilletData? billet,
    required String route,
    required String date,
    required String time,
    required String price,
    required String passengerFallback,
    int? pageIndex,
    int? pageCount,
  }) {
    final displayPassenger = hasBillet && billet != null
        ? ((billet.nomPassager != null && billet.nomPassager!.trim().isNotEmpty
                  ? billet.nomPassager!
                  : passengerFallback)
              .toUpperCase())
        : passengerFallback.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Code siège: ${billet?.codeSiege}',
                      style: GoogleFonts.caveat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (pageIndex != null &&
                        pageCount != null &&
                        pageCount > 1) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Billet ${pageIndex + 1} / $pageCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            child: Column(
              children: [
                if (hasBillet && billet != null) ...[
                  if (!billet.isUsed)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF00E676),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: billet.qrCode,
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        border: Border.all(
                          color: const Color(0xFFE53935),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Ce Billet est déjà utilisé',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.orange, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Billet non encore émis.\nRevenez après validation de la réservation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  route,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const TicketSeparator(),
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PASSAGER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayPassenger,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'PRIX',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Départ le $date à $time',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billetsAffichage = widget.billets.isNotEmpty
        ? widget.billets
        : (widget.billetData != null
              ? <BilletData>[widget.billetData!]
              : <BilletData>[]);
    final hasBillet = billetsAffichage.isNotEmpty;
    final multiBillets = billetsAffichage.length > 1;
    final route =
        '${widget.reservationData?.villeDepart ?? 'N/A'} → ${widget.reservationData?.villeArrivee ?? 'N/A'}';
    final date = _formatDate(widget.reservationData?.dateVoyage);
    final time = _formatTimeFromString(
      widget.reservationData?.heureVoyage?.formattedTime,
    );
    // Le paiement Mobile Money peut renvoyer montantPaye=0 tant que la réponse
    // reste « en attente ». On retombe alors sur montantAPaye, puis sur le
    // prixVoyage de la réservation (présent dans le billet confirmé).
    final montantPaye = widget.paiementData?.montantPaye ?? 0;
    final montantAPaye = widget.paiementData?.montantAPaye ?? 0;
    final prixVoyage = widget.reservationData?.prixVoyage ?? 0;
    final montantAffiche = montantPaye > 0
        ? montantPaye
        : (montantAPaye > 0 ? montantAPaye : prixVoyage);
    final price = '${montantAffiche.toStringAsFixed(0)} FC';
    final passengerName =
        widget.reservationData?.nomClient ??
        widget.reservationData?.nomUtilisateur ??
        'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          multiBillets ? 'Mes billets' : 'Mon Billet',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            enabled: !_isSaving,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E1E),
            onSelected: (value) {
              if (value == 'pdf') {
                _shareAsPdf();
              } else if (value == 'image') {
                _shareAsImage();
              } else if (value == 'report') {
                _reporterBillet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFF00E676),
                    ),
                    SizedBox(width: 10),
                    Text('Partager en PDF'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'image',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: Color(0xFF00E676)),
                    SizedBox(width: 10),
                    Text('Partager en image'),
                  ],
                ),
              ),
              if (_currentBillet != null)
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.event_repeat_outlined,
                          color: Color(0xFF00E676)),
                      SizedBox(width: 10),
                      Text('Reporter le voyage'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: multiBillets
            ? Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _billetCarouselController,
                      onPageChanged: (i) {
                        setState(() => _carouselIndex = i);
                      },
                      itemCount: billetsAffichage.length,
                      itemBuilder: (context, i) {
                        return Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: RepaintBoundary(
                              key: i == _carouselIndex
                                  ? _ticketKey
                                  : ValueKey<String>('ticket_rb_$i'),
                              child: _buildFullTicketCard(
                                hasBillet: true,
                                billet: billetsAffichage[i],
                                route: route,
                                date: date,
                                time: time,
                                price: price,
                                passengerFallback: passengerName,
                                pageIndex: i,
                                pageCount: billetsAffichage.length,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            billetsAffichage.length,
                            (i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == _carouselIndex ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i == _carouselIndex
                                      ? const Color(0xFF00E676)
                                      : const ui.Color.fromARGB(
                                          66,
                                          255,
                                          255,
                                          255,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Glissez pour voir l’autre billet',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: RepaintBoundary(
                          key: _ticketKey,
                          child: _buildFullTicketCard(
                            hasBillet: hasBillet,
                            billet: hasBillet ? billetsAffichage.first : null,
                            route: route,
                            date: date,
                            time: time,
                            price: price,
                            passengerFallback: passengerName,
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

class TicketSeparator extends StatelessWidget {
  const TicketSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 15,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: DashedLine(color: Colors.black26, height: 1.5),
          ),
        ),
        Container(
          height: 30,
          width: 15,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  final double height;

  const DashedLine({super.key, this.color = Colors.black26, this.height = 1.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
