import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/models/create_reservation_request.dart';
import 'package:rusa/models/reservation_with_paiement_request.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/screens/client/TicketReceiptScreen.dart';
import 'package:rusa/screens/client/BusDetailsScreen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Voyage voyage;

  const SeatSelectionScreen({super.key, required this.voyage});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // Gestion de l'état des sièges
  int totalSeats = 16;
  List<int> bookedSeats = [];

  // Gestion du carousel
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _carouselImages = [
    'assets/images/img1.png',
    'assets/images/img2.png',
    'assets/images/img1.png',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Section supérieure avec l'image
            Container(
              height: size.height * 0.25,
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
                    itemCount: _carouselImages.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            _carouselImages[index],
                            fit: BoxFit.contain,
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
                        _carouselImages.length,
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
                    child: _buildCircularButton(Icons.favorite_border, () {}),
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
                      fontSize: 30,
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

        // Prix et informations bus
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    '${widget.voyage.prix.toStringAsFixed(0)} FC',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                  widget.voyage.heureDepart,
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
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BusDetailsScreen(busId: widget.voyage.idBus),
                ),
              );
            },
            child: Text(
              "Voir les informations du bus",
              style: TextStyle(color: Color.fromARGB(255, 155, 156, 155)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Bouton "Reserver"
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _showReservationOptionsDialog,
            child: const Text(
              'Reserver',
              style: TextStyle(
                color: Colors.black,
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

  void _showReservationOptionsDialog() {
    final montantController = TextEditingController();
    int nombreDePlace = 1;
    double montantTotal = widget.voyage.prix * nombreDePlace;
    bool updatingMontantField = false;
    montantController.text = (montantTotal * 0.5).toStringAsFixed(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          montantTotal = widget.voyage.prix * nombreDePlace;
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
                                    final total = widget.voyage.prix * nombreDePlace;
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
                                final total = widget.voyage.prix * nombreDePlace;
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
                      'Montant total: ${montantTotal.toStringAsFixed(0)} FC',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Montant payé min (50%): ${montantMaximum.toStringAsFixed(0)} FC',
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
                        final computedSeats =
                            ((montant * 2) / widget.voyage.prix).ceil();
                        final nextSeats = computedSeats < 1 ? 1 : computedSeats;
                        if (nextSeats != nombreDePlace) {
                          setDialogState(() {
                            updatingMontantField = true;
                            nombreDePlace = nextSeats;
                            final minAllowed =
                                (widget.voyage.prix * nombreDePlace) * 0.5;
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
                                      'Le montant payé doit être >= ${montantMaximum.toStringAsFixed(0)} FC et <= ${montantTotal.toStringAsFixed(0)} FC',
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
      debugPrint('Prix: ${widget.voyage.prix}');
      final montantTotal = widget.voyage.prix * nombreDePlace;

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
