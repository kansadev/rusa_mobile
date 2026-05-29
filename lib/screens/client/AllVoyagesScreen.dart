import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/widgets/voyage_periode_selector.dart';
import 'package:rusa/widgets/caissier_client_picker_sheet.dart';
import 'package:rusa/utils/voyage_periode_filter.dart';
import 'package:rusa/screens/client/voyageDetails.dart';

class AllVoyagesScreen extends StatefulWidget {
  const AllVoyagesScreen({
    super.key,
    this.initialPeriode,
    this.showBack = true,
    this.client,
  });

  final VoyagePeriode? initialPeriode;
  final bool? showBack;

  /// Client pour lequel vendre le billet (flux caissier).
  final Client? client;

  @override
  State<AllVoyagesScreen> createState() => _AllVoyagesScreenState();
}

class _AllVoyagesScreenState extends State<AllVoyagesScreen> {
  static const int _pageSize = 200;

  final ScrollController _scrollController = ScrollController();

  List<Voyage> _voyages = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasNextPage = true;
  int _nextPageNumber = 1;
  String? _error;
  late VoyagePeriode _periode;
  Client? _selectedClient;
  bool _isCaissier = false;
  List<Client> _clientsForPicker = [];
  String? _clientsLoadError;
  bool _loadingClients = false;

  @override
  void initState() {
    super.initState();
    _periode = widget.initialPeriode ?? VoyagePeriode.jour;
    _selectedClient = widget.client;
    _scrollController.addListener(_onScroll);
    _loadRoleContext();
    _loadVoyages(reset: true);
  }

  Future<void> _loadRoleContext() async {
    final auth = await CacheService.getAuthResponse();
    if (!mounted) return;
    final role = auth?.primaryRole.nom.toLowerCase().trim() ?? '';
    final roleName = role.isNotEmpty
        ? role
        : (auth?.nomRole.toLowerCase().trim() ?? '');
    final isCaissier = roleName.contains('caiss');
    setState(() => _isCaissier = isCaissier);
    if (isCaissier) {
      await _ensureClientsLoaded();
    }
  }

  Future<void> _ensureClientsLoaded({bool force = false}) async {
    if (!force && _clientsForPicker.isNotEmpty) return;
    setState(() {
      _loadingClients = true;
      _clientsLoadError = null;
    });
    final list = await ApiService.getAllClients();
    if (!mounted) return;
    setState(() {
      _loadingClients = false;
      if (list == null) {
        _clientsLoadError =
            'Impossible de charger les clients. Vérifiez vos droits.';
        _clientsForPicker = [];
      } else {
        _clientsForPicker = list;
      }
    });
  }

  Future<Client?> _openClientPicker() async {
    if (_clientsForPicker.isEmpty && !_loadingClients) {
      await _ensureClientsLoaded(force: true);
    }
    if (!mounted) return null;
    return showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CaissierClientPickerSheet(
        clients: _clientsForPicker,
        loadError: _clientsLoadError,
        onRetry: () async {
          Navigator.pop(ctx);
          await _ensureClientsLoaded(force: true);
          if (mounted) {
            final picked = await _openClientPicker();
            if (picked != null) setState(() => _selectedClient = picked);
          }
        },
      ),
    );
  }

  void _clearClient() => setState(() => _selectedClient = null);

  bool _isVoyageDepartPasse(Voyage voyage) {
    final raw = voyage.dateDepart.trim();
    if (raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final depDay = DateTime(local.year, local.month, local.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return depDay.isBefore(today);
  }

  Future<void> _onVoyageTap(Voyage voyage) async {
    if (_isVoyageDepartPasse(voyage)) return;

    if (_isCaissier && _selectedClient == null) {
      final picked = await _openClientPicker();
      if (picked == null || !mounted) return;
      setState(() => _selectedClient = picked);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          voyage: voyage,
          client: _selectedClient,
          showBackButton: widget.showBack ?? true,
        ),
      ),
    );
  }

  Widget _buildClientBanner() {
    if (!_isCaissier) return const SizedBox.shrink();

    final c = _selectedClient;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2622),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF29F58B).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: Color(0xFF29F58B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c == null ? 'Aucun client sélectionné' : 'Réservation pour',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    c?.nomClient ?? 'Choisissez un client avant de vendre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final picked = await _openClientPicker();
                if (picked != null) setState(() => _selectedClient = picked);
              },
              child: Text(c == null ? 'Choisir' : 'Changer'),
            ),
            if (c != null)
              IconButton(
                onPressed: _clearClient,
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                tooltip: 'Retirer le client',
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNextPage || _loadingMore || _isLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _loadVoyages({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _hasNextPage = true;
        _nextPageNumber = 1;
        _voyages = [];
      });
    }

    try {
      final response = await ApiService.getVoyagesPaged(
        pageNumber: 1,
        pageSize: _pageSize,
        periode: _periode.apiValue,
        sortBy: 'dateDepart',
        sortDescending: false,
      );

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _error = 'Impossible de charger les voyages.';
          _isLoading = false;
          _hasNextPage = false;
        });
        return;
      }

      setState(() {
        _voyages = VoyagePeriodeFilter.apply(response.data, _periode);
        _hasNextPage = response.hasNextPage;
        _nextPageNumber = 2;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des voyages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNextPage || _loadingMore || _isLoading) return;

    setState(() => _loadingMore = true);

    try {
      final response = await ApiService.getVoyagesPaged(
        pageNumber: _nextPageNumber,
        pageSize: _pageSize,
        periode: _periode.apiValue,
        sortBy: 'dateDepart',
        sortDescending: false,
      );

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _loadingMore = false;
          _hasNextPage = false;
        });
        return;
      }

      setState(() {
        final more = VoyagePeriodeFilter.apply(response.data, _periode);
        _voyages = [..._voyages, ...more];
        _hasNextPage = response.hasNextPage;
        _nextPageNumber++;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    await _loadVoyages(reset: true);
  }

  void _onPeriodeChanged(VoyagePeriode p) {
    setState(() => _periode = p);
    _loadVoyages(reset: true);
  }

  String _suffixeDevisePrix(Voyage v) {
    final c = v.codeDevisePrix?.trim();
    if (c == null || c.isEmpty) return 'FC';
    return c;
  }

  double _prixUnitaireReference(Voyage v) {
    if (v.prix > 0) return v.prix;
    if (v.tarifs.isEmpty) return 0;
    return v.tarifs.map((t) => t.prix).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        automaticallyImplyLeading: widget.showBack ?? true,
        title: Text(
          'Tous les voyages',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClientBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: VoyagePeriodeSelector(
              selected: _periode,
              onPeriodeChanged: _onPeriodeChanged,
              showVoirTout: false,
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _error != null
                ? _buildErrorView()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
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
      return RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF00E676),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
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
                    'Aucun voyage pour cette période',
                    style: GoogleFonts.caveat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
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
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _voyages.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _voyages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00E676),
                  ),
                ),
              ),
            );
          }
          return _buildVoyageCard(_voyages[index]);
        },
      ),
    );
  }

  Widget _buildVoyageCard(Voyage voyage) {
    final isPassed = _isVoyageDepartPasse(voyage);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPassed ? const Color(0xFF1A1A1A) : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPassed ? Colors.white10 : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPassed ? null : () => _onVoyageTap(voyage),
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isPassed ? 0.55 : 1,
            child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
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
                            color: Colors.white.withValues(alpha: 0.54),
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
                        color: Colors.white10,
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
                            color: Colors.white.withValues(alpha: 0.54),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          voyage.dateDepart.length >= 10
                              ? voyage.dateDepart.substring(0, 10)
                              : voyage.dateDepart,
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
                Row(
                  children: [
                    const Icon(
                      Icons.event_seat,
                      color: Color(0xFF00E676),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      voyage.placesDisponiblesTotal > 0
                          ? '${voyage.placesDisponiblesTotal} siège(s) dispo'
                          : 'Complet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (voyage.tarifs.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Tarifs par classe',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: voyage.tarifs
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
                              '${t.libelle}: ${t.prix.toStringAsFixed(0)} ${_suffixeDevisePrix(voyage)}',
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
                ] else ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _prixUnitaireReference(voyage) > 0
                              ? '${_prixUnitaireReference(voyage).toStringAsFixed(0)} ${_suffixeDevisePrix(voyage)}'
                              : 'Tarif sur demande',
                          style: TextStyle(
                            color: _prixUnitaireReference(voyage) > 0
                                ? const Color(0xFF00E676)
                                : Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bus ${voyage.numeroBus}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (voyage.nomSociete != null &&
                        voyage.nomSociete!.isNotEmpty)
                      Text(
                        voyage.nomSociete!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
