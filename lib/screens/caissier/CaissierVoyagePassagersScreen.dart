import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/models/voyage_passager_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/utils/voyage_periode_filter.dart';
import 'package:rusa/widgets/voyage_periode_selector.dart';

/// Choisir un voyage (API société paginée) puis afficher ses passagers.
class CaissierVoyagePassagersScreen extends StatefulWidget {
  const CaissierVoyagePassagersScreen({super.key});

  @override
  State<CaissierVoyagePassagersScreen> createState() =>
      _CaissierVoyagePassagersScreenState();
}

class _CaissierVoyagePassagersScreenState
    extends State<CaissierVoyagePassagersScreen> {
  static const _accent = Color(0xFF29F58B);
  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  int _idSociete = 0;
  bool _loadingInit = true;
  String? _initError;

  VoyagePeriode _periode = VoyagePeriode.jour;
  List<Voyage> _voyages = [];
  bool _loadingVoyages = false;
  bool _loadingMore = false;
  bool _hasNextPage = true;
  int _nextPage = 1;
  String? _voyagesError;

  Voyage? _selectedVoyage;
  List<VoyagePassager> _passagers = [];
  bool _loadingPassagers = false;
  String? _passagersError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = await CacheService.getAuthResponse();
    final idSoc = auth?.utilisateur.idSociete ?? 0;
    if (!mounted) return;
    if (idSoc <= 0) {
      setState(() {
        _idSociete = 0;
        _loadingInit = false;
        _initError = 'Société introuvable pour ce compte.';
      });
      return;
    }
    setState(() {
      _idSociete = idSoc;
      _loadingInit = false;
    });
    await _loadVoyages(reset: true);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadVoyages(reset: true);
    });
  }

  void _onScroll() {
    if (!_hasNextPage || _loadingMore || _loadingVoyages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _loadVoyages({required bool reset}) async {
    if (_idSociete <= 0) return;
    if (reset) {
      setState(() {
        _loadingVoyages = true;
        _voyagesError = null;
        _hasNextPage = true;
        _nextPage = 1;
        _voyages = [];
        _selectedVoyage = null;
        _passagers = [];
        _passagersError = null;
      });
    }

    final response = await ApiService.getVoyagesBySocietePaged(
      idSociete: _idSociete,
      pageNumber: 1,
      pageSize: _pageSize,
      searchTerm: _searchController.text.trim(),
      periode: _periode.apiValue,
      sortBy: 'dateDepart',
      sortDescending: false,
    );

    if (!mounted) return;
    if (response == null) {
      setState(() {
        _loadingVoyages = false;
        _voyagesError = 'Impossible de charger les voyages.';
        _hasNextPage = false;
      });
      return;
    }

    setState(() {
      _voyages = VoyagePeriodeFilter.apply(response.data, _periode);
      _hasNextPage = response.hasNextPage;
      _nextPage = 2;
      _loadingVoyages = false;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasNextPage || _loadingMore || _loadingVoyages) return;
    setState(() => _loadingMore = true);

    final response = await ApiService.getVoyagesBySocietePaged(
      idSociete: _idSociete,
      pageNumber: _nextPage,
      pageSize: _pageSize,
      searchTerm: _searchController.text.trim(),
      periode: _periode.apiValue,
      sortBy: 'dateDepart',
      sortDescending: false,
    );

    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (response == null) {
        _hasNextPage = false;
        return;
      }
      final more = VoyagePeriodeFilter.apply(response.data, _periode);
      _voyages = [..._voyages, ...more];
      _hasNextPage = response.hasNextPage;
      _nextPage++;
    });
  }

  Future<void> _selectVoyage(Voyage v) async {
    setState(() {
      _selectedVoyage = v;
      _loadingPassagers = true;
      _passagers = [];
      _passagersError = null;
    });

    final list = await ApiService.getPassagersByVoyage(
      v.id,
      voyageFallback: v,
    );

    if (!mounted) return;
    setState(() {
      _passagers = list;
      _loadingPassagers = false;
      if (list.isEmpty) {
        _passagersError =
            'Aucun passager trouvé pour ce voyage (ou endpoint non disponible).';
      }
    });
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return raw;
    final local = dt.isUtc ? dt.toLocal() : dt;
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Passagers par voyage',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _initError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un voyage…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      prefixIcon: const Icon(Icons.search, color: _accent),
                      filled: true,
                      fillColor: _card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: VoyagePeriodeSelector(
                    selected: _periode,
                    showVoirTout: false,
                    onPeriodeChanged: (p) {
                      setState(() => _periode = p);
                      _loadVoyages(reset: true);
                    },
                  ),
                ),
                if (_selectedVoyage != null) _buildSelectedVoyageBanner(),
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildSelectedVoyageBanner() {
    final v = _selectedVoyage!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: _accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${v.villeDepart} → ${v.villeArrivee} · ${_formatDate(v.dateDepart)} ${v.heure}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedVoyage = null;
                _passagers = [];
                _passagersError = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedVoyage != null) {
      return _buildPassagersList();
    }
    return _buildVoyagesList();
  }

  Widget _buildVoyagesList() {
    if (_loadingVoyages && _voyages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_voyagesError != null && _voyages.isEmpty) {
      return Center(
        child: Text(_voyagesError!, style: const TextStyle(color: Colors.white70)),
      );
    }
    if (_voyages.isEmpty) {
      return Center(
        child: Text(
          'Aucun voyage pour cette période.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _loadVoyages(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _voyages.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _voyages.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              ),
            );
          }
          return _buildVoyageTile(_voyages[index]);
        },
      ),
    );
  }

  Widget _buildVoyageTile(Voyage v) {
    final places = v.placesDisponiblesTotal;
    final repartition = v.repartitionCategorieSiegesDisponible;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: () => _selectVoyage(v),
        leading: CircleAvatar(
          backgroundColor: _accent.withValues(alpha: 0.15),
          child: const Icon(Icons.directions_bus, color: _accent, size: 22),
        ),
        title: Text(
          '${v.villeDepart} → ${v.villeArrivee}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_formatDate(v.dateDepart)} · ${v.heure} · ${v.numeroBus.isNotEmpty ? v.numeroBus : v.libelleTypeBus}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
            if (places > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$places place(s) dispo.',
                  style: const TextStyle(color: _accent, fontSize: 12),
                ),
              ),
            if (repartition.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  repartition
                      .map(
                        (r) =>
                            '${r.codeCategorieSiege.isNotEmpty ? r.codeCategorieSiege : r.libelle}: ${r.nombreSiege}',
                      )
                      .join(' · '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }

  Widget _buildPassagersList() {
    if (_loadingPassagers) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        final v = _selectedVoyage;
        if (v != null) await _selectVoyage(v);
      },
      child: _passagers.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _passagersError ?? 'Aucun passager.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _passagers.length,
              itemBuilder: (context, index) {
                final p = _passagers[index];
                return _buildPassagerCard(p);
              },
            ),
    );
  }

  Widget _buildPassagerCard(VoyagePassager p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _accent.withValues(alpha: 0.15),
            child: Icon(
              p.estEmbarque ? Icons.how_to_reg : Icons.person_outline,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nomComplet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (p.telephone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.telephone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
                if (p.codeSiege != null || p.categorieSiege != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (p.categorieSiege != null) p.categorieSiege!,
                      if (p.codeSiege != null) 'Siège ${p.codeSiege}',
                    ].join(' · '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (p.estEmbarque)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Embarqué',
                style: TextStyle(color: _accent, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
