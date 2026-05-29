import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/reservation_api_model.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:rusa/services/api_service.dart';

class CaissierClientDetailsScreen extends StatefulWidget {
  final int clientId;

  const CaissierClientDetailsScreen({super.key, required this.clientId});

  @override
  State<CaissierClientDetailsScreen> createState() =>
      _CaissierClientDetailsScreenState();
}

class _CaissierClientDetailsScreenState
    extends State<CaissierClientDetailsScreen> {
  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);
  static const _accent = Color(0xFF29F58B);

  Client? _client;
  List<Reservation> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait([
      ApiService.getClientById(widget.clientId),
      ApiService.getReservationsByClient(widget.clientId),
    ]);

    if (!mounted) return;

    final client = results[0] as Client?;
    final reservations = results[1] as List<Reservation>?;

    if (client == null) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les informations du client.';
      });
      return;
    }

    setState(() {
      _client = client;
      _reservations = reservations ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Fiche client',
          style: GoogleFonts.caveat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator(color: _accent)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    final client = _client!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.nomClient,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                client.emailClient,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 4),
              Text(
                client.telephone,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              if ((client.adresseClient ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  client.adresseClient!.trim(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllVoyagesScreen(client: client),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.confirmation_num_outlined),
                  label: const Text('Vendre billet'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Réservations (${_reservations.length})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_reservations.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucune réservation pour ce client.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          )
        else
          ..._reservations.map(_buildReservationTile),
      ],
    );
  }

  Widget _buildReservationTile(Reservation r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.villeDepart} -> ${r.villeArrivee}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${r.formattedDate} ${r.formattedTime} | ${r.formattedPrice}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 4),
          Text(
            'Statut: ${r.statutReservation}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
