import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/bus_model.dart';
import '../../services/api_service.dart';

class BusDetailsScreen extends StatefulWidget {
  final int busId;

  const BusDetailsScreen({super.key, required this.busId});

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  Bus? _bus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBusDetails();
  }

  Future<void> _loadBusDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bus = await ApiService.getBusById(widget.busId);
      if (!mounted) return;

      if (bus != null) {
        setState(() {
          _bus = bus;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Bus non trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadBusDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          'Détails du Bus',
          style: GoogleFonts.caveat(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[800]!,
                highlightColor: Colors.grey[600]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 200,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Info cards shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[800]!,
                highlightColor: Colors.grey[600]!,
                child: Column(
                  children: [
                    _buildShimmerCard(),
                    const SizedBox(height: 16),
                    _buildShimmerCard(),
                    const SizedBox(height: 16),
                    _buildShimmerCard(),
                    const SizedBox(height: 16),
                    _buildShimmerCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
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
    if (_bus == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00E676),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre principal
              Text(
                '${_bus!.marques} - Immatriculation: ${_bus!.numeroDePlaque}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // Informations détaillées
              _buildInfoSection('Informations générales', [
                _buildInfoItem(
                  Icons.confirmation_number,
                  'Alias du bus',
                  _bus!.aliasVehicule,
                  Colors.blue,
                ),
                _buildInfoItem(
                  Icons.badge,
                  'Plaque d\'immatriculation',
                  _bus!.numeroDePlaque,
                  Colors.green,
                ),
                _buildInfoItem(
                  Icons.category,
                  'Type de bus',
                  _bus!.libelleTypeBus ?? 'Non spécifié',
                  Colors.orange,
                ),
                _buildInfoItem(
                  Icons.event_seat,
                  'Nombre de sièges',
                  '${_bus!.nombreSiege}',
                  Colors.purple,
                ),
              ]),

              const SizedBox(height: 24),

              _buildInfoSection('Société', [
                _buildInfoItem(
                  Icons.business,
                  'Nom de la société',
                  _bus!.nomSociete,
                  Colors.teal,
                ),
              ]),

              const SizedBox(height: 24),

              _buildInfoSection('Dates', [
                _buildInfoItem(
                  Icons.calendar_today,
                  'Date d\'enregistrement',
                  _formatDate(_bus!.dateCreation),
                  Colors.amber,
                ),
                if (_bus!.dateModification != null)
                  _buildInfoItem(
                    Icons.update,
                    'Date de modification',
                    _formatDate(_bus!.dateModification!),
                    Colors.cyan,
                  ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
      return dateString;
    }
  }
}
