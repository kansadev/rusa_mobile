import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/screens/client/voyageDetails.dart';

class AllVoyagesScreen extends StatefulWidget {
  const AllVoyagesScreen({super.key});

  @override
  State<AllVoyagesScreen> createState() => _AllVoyagesScreenState();
}

class _AllVoyagesScreenState extends State<AllVoyagesScreen> {
  List<Voyage> _voyages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVoyages();
  }

  Future<void> _loadVoyages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final voyages = await ApiService.getAllVoyages();

      if (mounted) {
        setState(() {
          _voyages = voyages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des voyages: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadVoyages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Tous les Voyages',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 28,
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
              height: 140,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
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
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
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
    );
  }

  Widget _buildContent() {
    if (_voyages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Color(0xFF00E676),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun voyage disponible',
              style: GoogleFonts.caveat(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Réessayez plus tard',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
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
        itemCount: _voyages.length,
        itemBuilder: (context, index) {
          final voyage = _voyages[index];
          return _buildVoyageCard(voyage);
        },
      ),
    );
  }

  Widget _buildVoyageCard(Voyage voyage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeatSelectionScreen(voyage: voyage),
                ),
              );
            } catch (e) {
              debugPrint('Erreur lors de la navigation: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de la navigation: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route principale avec villes sur la même ligne
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        voyage.villeDepart,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                    Expanded(
                      child: Text(
                        voyage.villeArrivee,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Prix sur la ligne suivante
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        voyage.prixFormatted,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informations horaires et date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF00E676),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Départ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          voyage.heure,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF00E676),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          voyage.date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Informations supplémentaires
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: Colors.white.withOpacity(0.7),
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bus ${voyage.numeroBus}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (voyage.nomSociete != null &&
                        voyage.nomSociete!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.business,
                          color: Colors.white.withOpacity(0.7),
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        voyage.nomSociete!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
