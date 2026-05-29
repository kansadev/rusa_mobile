import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/models/create_reservation_request.dart';
import 'package:rusa/models/reservation_with_paiement_request.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/screens/client/TicketReceiptScreen.dart';
import 'package:rusa/screens/client/BusDetailsScreen.dart';
import 'package:rusa/screens/client/ReservationFormScreen.dart';
import 'package:rusa/screens/client/VehiclePhotosGalleryScreen.dart';
import 'package:rusa/screens/SeatViewScreen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Voyage voyage;
  final Client? client;
  final bool showBackButton;

  const SeatSelectionScreen({
    super.key,
    required this.voyage,
    this.client,
    this.showBackButton = true,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // Gestion de l'état des sièges
  int totalSeats = 16;
  List<int> bookedSeats = [];

  bool _isCaissier = false;

  /// Flux vente caissier (rôle ou client bénéficiaire déjà choisi).
  bool get _isVenteCaissier => _isCaissier || widget.client != null;

  // Gestion du carousel
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _fallbackCarouselImages = <String>[
    'assets/images/img1.png',
    'assets/images/img2.png',
    'assets/images/img1.png',
  ];

  final List<Uint8List> _vehicleImages = [];

  int get _carouselCount => _vehicleImages.isNotEmpty
      ? _vehicleImages.length
      : _fallbackCarouselImages.length;

  static const double _carouselImageRadius = 16;

  void _openPhotoGallery({int initialIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehiclePhotosGalleryScreen(
          memoryImages: List<Uint8List>.from(_vehicleImages),
          assetImages: List<String>.from(_fallbackCarouselImages),
          initialIndex: initialIndex,
          title: widget.voyage.numeroBus.isNotEmpty
              ? 'Bus ${widget.voyage.numeroBus}'
              : 'Photos du véhicule',
        ),
      ),
    );
  }

  Widget _buildCarouselImage(int index) {
    final borderRadius = BorderRadius.circular(_carouselImageRadius);
    final child = _vehicleImages.isNotEmpty
        ? Image.memory(
            _vehicleImages[index],
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.asset(
            _fallbackCarouselImages[index],
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );

    return Hero(
      tag: 'vehicle_photo_$index',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(color: const Color(0xFF151515), child: child),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isCaissier = widget.client != null;
    _vehicleImages.addAll(_decodeVehicleImages());
    _loadRoleContext();
  }

  List<Uint8List> _decodeVehicleImages() {
    final photos = widget.voyage.photosVehicules;
    if (photos.isEmpty) return const <Uint8List>[];

    final out = <Uint8List>[];
    for (final p in photos) {
      final decoded = _decodeBase64Image(p.photoBase64);
      if (decoded != null) out.add(decoded);
    }
    return out;
  }

  Uint8List? _decodeBase64Image(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final cleaned = trimmed.contains('base64,')
          ? trimmed.split('base64,').last
          : trimmed;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRoleContext() async {
    if (widget.client != null) {
      if (mounted) setState(() => _isCaissier = true);
      return;
    }
    final auth = await CacheService.getAuthResponse();
    if (!mounted || auth == null) return;
    final primaryRoleName = auth.primaryRole.nom.toLowerCase().trim();
    final roleName = primaryRoleName.isNotEmpty
        ? primaryRoleName
        : auth.nomRole.toLowerCase().trim();
    if (!mounted) return;
    setState(() => _isCaissier = roleName.contains('caiss'));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _suffixeDevisePrix(Voyage v) {
    final c = v.codeDevisePrix?.trim();
    if (c == null || c.isEmpty) return 'FC';
    return c;
  }

  /// Pour l’affichage et l’ancien flux paiement : `prix` du voyage si renseigné, sinon le tarif le plus élevé.
  double _prixUnitaireReference(Voyage v) {
    if (v.prix > 0) return v.prix;
    if (v.tarifs.isEmpty) return 0;
    return v.tarifs.map((t) => t.prix).reduce((a, b) => a > b ? a : b);
  }

  // Méthode pour formater la date
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Non défini';

    try {
      DateTime? date;

      // Essayer de parser le format ISO (2026-04-23T12:58:45.611838)
      if (dateString.contains('T')) {
        date = DateTime.tryParse(dateString);
      }
      // Essayer de parser le format YYYY-MM-DD
      else if (dateString.contains('-')) {
        List<String> parts = dateString.split('-');
        if (parts.length >= 3) {
          // Extraire seulement la partie date si elle contient des caractères supplémentaires
          String dayPart = parts[2].split(
            'T',
          )[0]; // Prendre la partie avant 'T'
          date = DateTime(
            int.parse(parts[0]), // année
            int.parse(parts[1]), // mois
            int.parse(dayPart), // jour
          );
        }
      }
      // Essayer de parser le format DD/MM/YYYY
      else if (dateString.contains('/')) {
        List<String> parts = dateString.split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]), // année
            int.parse(parts[1]), // mois
            int.parse(parts[0]), // jour
          );
        }
      }

      if (date == null) return dateString;

      // Formater en français
      const List<String> mois = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];

      const List<String> jours = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];

      return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]} ${date.year}';
    } catch (e) {
      debugPrint('Erreur lors du formatage de la date: $e');
      return 'Date invalide';
    }
  }

  bool _isVoyageDepartPasse(Voyage v) {
    final raw = v.dateDepart.trim();
    if (raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final depDay = DateTime(local.year, local.month, local.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return depDay.isBefore(today);
  }

  double _carouselSectionHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.38).clamp(280.0, 420.0);
  }

  @override
  Widget build(BuildContext context) {
    final carouselHeight = _carouselSectionHeight(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Section supérieure avec l'image
            Container(
              height: carouselHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                ),
              ),
              child: Stack(
                children: [
                  // Carousel d'images
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _carouselCount,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openPhotoGallery(initialIndex: index),
                            borderRadius: BorderRadius.circular(
                              _carouselImageRadius,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildCarouselImage(index),
                                if (_carouselCount > 1)
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Agrandir',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Indicateurs de page
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _carouselCount,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF00E676)
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Boutons de navigation
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildCircularButton(
                      Icons.arrow_back_ios_new_rounded,
                      () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildVoyageOptionsMenu(),
                  ),
                ],
              ),
            ),

            // Section inférieure avec les détails
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF222222),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicateur de drag
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Contenu scrollable
                    Expanded(
                      child: SingleChildScrollView(child: _buildContent()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isPassed = _isVoyageDepartPasse(widget.voyage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre et infos du trajet
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.voyage.villeDepart} - ${widget.voyage.villeArrivee}',
                    style: GoogleFonts.caveat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tarification (multi-catégories + devise)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.voyage.tarifs.isNotEmpty) ...[
                Text(
                  'Tarifs par classe',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.voyage.tarifs
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '${t.libelle}: ${t.prix.toStringAsFixed(0)} ${_suffixeDevisePrix(widget.voyage)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (widget.voyage.prixDevisePrincipale != null &&
                    (widget.voyage.codeDevisePrincipale?.trim().isNotEmpty ??
                        false)) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Indication (${widget.voyage.codeDevisePrincipale}): ${widget.voyage.prixDevisePrincipale!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Prix du billet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _prixUnitaireReference(widget.voyage) > 0
                      ? '${_prixUnitaireReference(widget.voyage).toStringAsFixed(0)} ${_suffixeDevisePrix(widget.voyage)}'
                      : 'Tarif sur demande',
                  style: TextStyle(
                    color: _prixUnitaireReference(widget.voyage) > 0
                        ? const Color(0xFF00E676)
                        : Colors.white54,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),
        Column(
          children: [
            Row(
              children: [
                Text(
                  "Heure de Départ: ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.voyage.heure,
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "Date du voyage: ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(widget.voyage.dateDepart),
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  "Compagnie: ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.voyage.nomSociete ?? '',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  "Filiale: ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.voyage.nomSite ?? '',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Bouton réservation (client) ou vente (caissier)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPassed
                  ? Colors.white24
                  : const Color(0xFF00E676),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isPassed
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationFormScreen(
                          voyage: widget.voyage,
                          client: widget.client,
                        ),
                      ),
                    );
                  },
            child: Text(
              isPassed
                  ? 'Voyage passé'
                  : (_isVenteCaissier ? 'Vendre le billet' : 'Réserver'),
              style: TextStyle(
                color: isPassed ? Colors.white70 : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildVoyageOptionsMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: _onVoyageMenuSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'seats',
          child: Row(
            children: [
              Icon(
                Icons.event_seat_outlined,
                color: Color(0xFF00E676),
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Sièges disponibles', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'bus',
          child: Row(
            children: [
              Icon(
                Icons.directions_bus_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Détails du bus', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _onVoyageMenuSelected(String value) {
    switch (value) {
      case 'seats':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeatViewScreen(
              idVoyage: widget.voyage.id,
              title: 'Sièges disponibles',
              subtitle: [
                '${widget.voyage.villeDepart} → ${widget.voyage.villeArrivee}',
                if (widget.voyage.numeroBus.isNotEmpty)
                  'Bus ${widget.voyage.numeroBus}',
              ].join(' · '),
            ),
          ),
        );
        break;
      case 'bus':
        if (widget.voyage.idVehicule <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Véhicule non renseigné pour ce voyage.'),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BusDetailsScreen(busId: widget.voyage.idVehicule),
          ),
        );
        break;
    }
  }

  void _showReservationOptionsDialog() {
    final montantController = TextEditingController();
    int nombreDePlace = 1;
    final prixRef = _prixUnitaireReference(widget.voyage);
    double montantTotal = prixRef * nombreDePlace;
    bool updatingMontantField = false;
    montantController.text = (montantTotal * 0.5).toStringAsFixed(0);
    final devise = _suffixeDevisePrix(widget.voyage);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          montantTotal = prixRef * nombreDePlace;
          final montantMaximum = montantTotal * 0.5;
          return Dialog(
            backgroundColor: const Color(0xFF222222),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations supplementaires',
                      style: GoogleFonts.caveat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nombre de sièges',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (nombreDePlace > 1) {
                                  setDialogState(() {
                                    nombreDePlace--;
                                    final total = prixRef * nombreDePlace;
                                    montantController.text = (total * 0.5)
                                        .toStringAsFixed(0);
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$nombreDePlace',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setDialogState(() {
                                nombreDePlace++;
                                final total = prixRef * nombreDePlace;
                                montantController.text = (total * 0.5)
                                    .toStringAsFixed(0);
                              }),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Montant total: ${montantTotal.toStringAsFixed(0)} $devise',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Montant payé min (50%): ${montantMaximum.toStringAsFixed(0)} $devise',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        if (updatingMontantField) return;
                        final montant = double.tryParse(value.trim());
                        if (montant == null || montant <= 0) return;
                        if (prixRef <= 0) return;
                        final computedSeats = ((montant * 2) / prixRef).ceil();
                        final nextSeats = computedSeats < 1 ? 1 : computedSeats;
                        if (nextSeats != nombreDePlace) {
                          setDialogState(() {
                            updatingMontantField = true;
                            nombreDePlace = nextSeats;
                            final minAllowed = (prixRef * nombreDePlace) * 0.5;
                            if (montant < minAllowed) {
                              montantController.text = minAllowed
                                  .toStringAsFixed(0);
                              montantController.selection =
                                  TextSelection.collapsed(
                                    offset: montantController.text.length,
                                  );
                            }
                            updatingMontantField = false;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Montant payé',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final montantPaye =
                                  double.tryParse(
                                    montantController.text.trim(),
                                  ) ??
                                  0;
                              if (montantPaye <= 0 ||
                                  montantPaye < montantMaximum ||
                                  montantPaye > montantTotal) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Le montant payé doit être >= ${montantMaximum.toStringAsFixed(0)} $devise et <= ${montantTotal.toStringAsFixed(0)} $devise',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              await _processReservation(
                                nombreDePlace: nombreDePlace,
                                montantPaye: montantPaye,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Valider'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processReservation({
    required int nombreDePlace,
    required double montantPaye,
  }) async {
    // Afficher le dialog de chargement
    _showLoadingDialog();

    try {
      // Récupérer les informations utilisateur
      final session = SessionService();
      final userData = await session.getUserInfo();

      if (userData == null) {
        _hideLoadingDialog();
        throw Exception('Impossible de récupérer les informations utilisateur');
      }

      // Afficher les infos de debug
      debugPrint('=== DEBUG RÉSERVATION ===');
      debugPrint('User Data: $userData');
      debugPrint('ID Utilisateur: ${userData['id']}');
      debugPrint('ID Client: ${userData['client_id']}');
      debugPrint('Voyage ID: ${widget.voyage.id}');
      debugPrint('Societe ID: ${widget.voyage.idSociete}');
      final prixRef = _prixUnitaireReference(widget.voyage);
      debugPrint('Prix unitaire (réf.): $prixRef');
      final montantTotal = prixRef * nombreDePlace;

      // Créer la requête de réservation avec paiement
      final reservationRequest = ReservationRequest(
        idVoyage: widget.voyage.id,
        idClient: int.tryParse(userData['client_id'] ?? '0') ?? 0,
        nombreDePlace: nombreDePlace,
        idUtilisateur: int.tryParse(userData['id'] ?? '0') ?? 0,
        idSociete: widget.voyage.idSociete,
      );

      final paiementRequest = PaiementRequest(
        montantAPaye: montantTotal,
        montantPaye: montantPaye,
        methodePaiement: 'Mobile Money', // Méthode par défaut
        referenceTransaction: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        idUtilisateur: int.tryParse(userData['id'] ?? '0') ?? 0,
        idSociete: widget.voyage.idSociete,
      );

      final reservationWithPaiementRequest = ReservationWithPaiementRequest(
        reservation: reservationRequest,
        paiement: paiementRequest,
      );

      debugPrint(
        'Données de réservation avec paiement: ${reservationWithPaiementRequest.toJson()}',
      );

      // Appeler l'API pour créer la réservation avec paiement
      final response = await ApiService.reservationWithPaiement(
        reservationWithPaiementRequest,
      );

      // Cacher le dialog de chargement
      _hideLoadingDialog();

      if (response != null) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Réservation créée avec succès! ID: ${response.reservation.idReservation}',
            ),
            backgroundColor: const Color(0xFF00E676),
          ),
        );

        // Naviguer vers le reçu avec les données de la réservation
        Navigator.push(
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
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la réservation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cacher le dialog de chargement en cas d'erreur
      _hideLoadingDialog();

      // Afficher un message d'erreur détaillé
      debugPrint('ERREUR DÉTAILLÉE: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Traitement en cours...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez patienter pendant\nque nous créons votre réservation',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _processPayment(String method) async {
    // Afficher un message de traitement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création de la réservation...'),
        backgroundColor: Color(0xFF00E676),
      ),
    );

    try {
      // Récupérer les informations utilisateur
      final session = SessionService();
      final userData = await session.getUserInfo();

      if (userData == null) {
        throw Exception('Impossible de récupérer les informations utilisateur');
      }

      // Créer la requête de réservation
      final reservationRequest = CreateReservationRequest(
        idUtilisateur: int.tryParse(userData['id'] ?? '0') ?? 0,
        idClient: int.tryParse(userData['id'] ?? '0') ?? 0,
        idVoyage: widget.voyage.id,
        statutReservation: 'Confirmée',
        statut: true,
        dateReservation: DateTime.now().toIso8601String().split('T')[0],
        idSociete: widget.voyage.idSociete,
      );

      // Appeler l'API pour créer la réservation
      final success = await ApiService.createReservation(reservationRequest);

      if (success) {
        // Fermer le bottom sheet
        Navigator.pop(context);

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation créée avec succès!'),
            backgroundColor: Color(0xFF00E676),
          ),
        );

        // Naviguer vers le reçu
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TicketReceiptScreen()),
        );
      } else {
        throw Exception('Échec de la création de la réservation');
      }
    } catch (e) {
      // Fermer le bottom sheet
      Navigator.pop(context);

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
