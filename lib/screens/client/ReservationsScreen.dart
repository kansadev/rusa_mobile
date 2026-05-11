import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/reservation_api_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/screens/client/TicketReceiptScreen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _error;
  int? _clientId;

  @override
  void initState() {
    super.initState();
    _loadClientId();
  }

  Future<void> _loadClientId() async {
    try {
      final session = SessionService();
      final userData = await session.getUserInfo();
      if (userData != null && mounted) {
        setState(() {
          _clientId = int.tryParse(userData['client_id'] ?? '0') ?? 0;
        });
        _loadReservationsWithCacheFallback();
        _retryLoadReservationsCacheIfNeeded();
      } else {
        if (mounted) {
          setState(() {
            _error = 'Impossible de récupérer l\'ID client';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement du client: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReservationsFromCache() async {
    if (_clientId == null) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cachedReservations = await CacheService.getClientReservations(
        _clientId!,
      );
      debugPrint(
        'RESERVATIONS: cache = ${cachedReservations == null ? "null" : cachedReservations.length}',
      );

      if (mounted) {
        setState(() {
          _reservations = cachedReservations ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reservations = [];
          _error = 'Erreur lors du chargement du cache: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReservationsWithCacheFallback() async {
    await _loadReservationsFromCache();
    if (!mounted) return;
    if (_reservations.isEmpty) {
      await _refreshReservationsFromApi(showLoading: false);
    }
  }

  Future<void> _retryLoadReservationsCacheIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _clientId == null || _reservations.isNotEmpty) return;

    final cachedReservations = await CacheService.getClientReservations(
      _clientId!,
    );
    if (!mounted) return;

    if (cachedReservations != null && cachedReservations.isNotEmpty) {
      setState(() {
        _reservations = cachedReservations;
        _isLoading = false;
      });
      debugPrint(
        'RESERVATIONS: cache rechargé après délai (${cachedReservations.length})',
      );
    }
  }

  Future<void> _refreshReservationsFromApi({bool showLoading = true}) async {
    if (_clientId == null) return;

    if (!mounted) return;
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final reservations = await ApiService.getReservationsByClient(_clientId!);
      if (!mounted) return;

      // En cas d'échec réseau/API, on garde le cache existant.
      if (reservations == null) {
        final cachedReservations = await CacheService.getClientReservations(
          _clientId!,
        );
        setState(() {
          _reservations = cachedReservations ?? _reservations;
          _error = 'Réseau indisponible. Affichage des données en cache.';
          _isLoading = false;
        });
        return;
      }

      final data = reservations;

      if (data.isNotEmpty) {
        await CacheService.saveClientReservations(_clientId!, data);
      }

      setState(() {
        _reservations = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final cachedReservations = await CacheService.getClientReservations(
        _clientId!,
      );
      setState(() {
        _reservations = cachedReservations ?? _reservations;
        _error = 'Erreur réseau. Données en cache affichées.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showLoadingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            color: Color(0xFF222222),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00E676),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement du billet...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToTicketReceipt(Reservation reservation) async {
    if (reservation.statutReservation == 'EN_ATTENTE') {
      _showErrorDialog(
        'Billet indisponible',
        'Cette réservation est encore en attente. Le billet sera disponible après validation du paiement.',
      );
      return;
    }

    // Show loading dialog
    _showLoadingDialog();

    try {
      final response = await ApiService.getBilletByReservation(
        reservation.idReservation,
      );

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response != null && mounted) {
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
        _showErrorDialog(
          'Billet indisponible',
          'Aucun billet n\'a encore été émis pour cette réservation.',
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Erreur', 'Une erreur est survenue: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF222222),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF00E676)),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _refresh() async {
    await _refreshReservationsFromApi(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Mes Réservations',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _error != null
          ? _buildErrorView()
          : _buildContent(),
    );
  }

  Widget _buildShimmerLoading() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00E676),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00E676),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Erreur',
                      style: GoogleFonts.caveat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Réessayer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_reservations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF00E676),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF00E676),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucune réservation',
                      style: GoogleFonts.caveat(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vous n\'avez pas encore de réservations',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00E676),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final statut = reservation.statutReservation == 'EN_ATTENTE'
        ? 'En attente'
        : reservation.statutReservation == 'CONFIRMEE'
        ? 'Confirmée'
        : reservation.statutReservation == 'ANNULEE'
        ? 'Annulée'
        : reservation.statutReservation == 'EN_COURS'
        ? 'En cours'
        : 'Terminée';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTicketReceipt(reservation),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Réservation #${reservation.idReservation}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: reservation.statut
                            ? const Color(0xFF00E676).withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statut,
                        style: GoogleFonts.poppins(
                          color: reservation.statut
                              ? const Color(0xFF00E676)
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Départ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            reservation.villeDepart,
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Arrivée',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            reservation.villeArrivee,
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informations supplémentaires
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Color(0xFF00E676),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prix',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${reservation.prixVoyage.toStringAsFixed(0)} FC',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF00E676),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${reservation.formattedDate} • ${reservation.formattedTime}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
