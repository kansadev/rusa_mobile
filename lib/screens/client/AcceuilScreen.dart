import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rusa/screens/ProfileImageViewScreen.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rusa/screens/client/voyageDetails.dart';
import 'package:rusa/widgets/ProfileImageWidget.dart';
import 'package:rusa/widgets/voyage_periode_selector.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/utils/voyage_periode_filter.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  static const int _homePageSize = 10;

  bool _showSearchBar = false;
  String _userName = '';
  String? _userPhotoUrl;
  List<Voyage> _voyages = [];
  bool _isLoadingVoyages = false;
  VoyagePeriode _periode = VoyagePeriode.jour;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVoyages();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Villes les plus présentes dans les trajets (départ + arrivée), pour les tags « Plus demandés ».
  List<String> _popularCityTags({int maxTags = 12}) {
    final counts = <String, int>{};
    final display = <String, String>{};

    void bump(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return;
      final key = t.toLowerCase();
      display.putIfAbsent(key, () => _formatCityLabel(t));
      counts[key] = (counts[key] ?? 0) + 1;
    }

    for (final v in _voyages) {
      bump(v.villeDepart);
      bump(v.villeArrivee);
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(maxTags).map((e) => display[e.key] ?? e.key).toList();
  }

  String _formatCityLabel(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  void _applyCityTag(String cityLabel) {
    final text = cityLabel.trim();
    setState(() {
      _searchQuery = text;
      _searchController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _showSearchBar = true;
    });
    _scheduleSearchReload();
  }

  void _scheduleSearchReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadVoyages();
    });
  }

  Widget _buildPopularCitiesSection() {
    final tags = _popularCityTags();
    if (tags.isEmpty) return const SizedBox.shrink();

    final selectedNorm = _searchQuery.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plus demandés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = tags[index];
              final isSelected = selectedNorm == city.trim().toLowerCase();
              return FilterChip(
                label: Text(
                  city,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFF00E676),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00E676) : Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onSelected: (selected) {
                  if (selected) {
                    _applyCityTag(city);
                  } else if (selectedNorm == city.trim().toLowerCase()) {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _loadVoyages();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAuth = await CacheService.getAuthResponse();
      if (!mounted) return;
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Utilisateur';
        _userPhotoUrl = cachedAuth?.utilisateur.photoUrl;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadVoyages() async {
    if (!mounted) return;
    setState(() => _isLoadingVoyages = true);

    try {
      final q = _searchQuery.trim();
      final response = await ApiService.getVoyagesPaged(
        pageNumber: 1,
        pageSize: _homePageSize,
        searchTerm: q.isEmpty ? null : q,
        periode: _periode.apiValue,
        sortBy: 'dateDepart',
        sortDescending: false,
      );

      if (!mounted) return;

      final raw = response?.data ?? [];
      final list = VoyagePeriodeFilter.apply(raw, _periode);
      await CacheService.saveVoyages(list);

      setState(() {
        _voyages = list;
        _isLoadingVoyages = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement voyages accueil: $e');
      if (mounted) {
        setState(() => _isLoadingVoyages = false);
      }
    }
  }

  void _openAllVoyages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllVoyagesScreen(initialPeriode: _periode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProfilePhoto = (_userPhotoUrl ?? '').trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileImageWidget(
                    imagePath: '',
                    imageUrl: _userPhotoUrl,
                    userName: _userName,
                    onTap: hasProfilePhoto
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileImageViewScreen(
                                  imagePath: '',
                                  imageUrl: _userPhotoUrl,
                                  userName: _userName,
                                ),
                              ),
                            );
                          }
                        : () {},
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _userName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showSearchBar ? Icons.close : Icons.search_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                      if (!_showSearchBar) {
                        _loadVoyages();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showSearchBar ? 60 : 0,
                margin: EdgeInsets.only(bottom: _showSearchBar ? 20 : 0),
                child: _showSearchBar
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _scheduleSearchReload();
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Entrez la ville de départ / d\'arrivée',
                            hintStyle: TextStyle(color: Colors.white38),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white54,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      )
                    : null,
              ),
              _buildPopularCitiesSection(),
              //const SizedBox(height: 20),
              VoyagePeriodeSelector(
                selected: _periode,
                onPeriodeChanged: (p) {
                  setState(() => _periode = p);
                  _loadVoyages();
                },
                onVoirTout: _openAllVoyages,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoadingVoyages
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00E676),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVoyages,
                        color: const Color(0xFF00E676),
                        child: _voyages.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.25,
                                  ),
                                  Center(
                                    child: Text(
                                      _searchQuery.trim().isEmpty
                                          ? 'Aucun voyage pour cette période'
                                          : 'Aucun résultat pour cette recherche',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _voyages.length,
                                itemBuilder: (context, index) {
                                  return _buildVoyageCard(_voyages[index]);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoyageCard(Voyage voyage) {
    final isPassed = _isVoyageDepartPasse(voyage);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPassed
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatSelectionScreen(voyage: voyage),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPassed ? const Color(0xFF1A1A1A) : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPassed ? Colors.white10 : Colors.white12,
            ),
          ),
          child: Opacity(
            opacity: isPassed ? 0.55 : 1.0,
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
                        textAlign: TextAlign.right,
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
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
                    'Tarifs par catégorie',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
                              '${t.libelle}: ${t.prix.toStringAsFixed(0)} FC',
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
