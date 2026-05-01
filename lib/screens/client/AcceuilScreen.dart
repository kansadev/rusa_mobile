import 'package:flutter/material.dart';
import 'package:rusa/screens/ProfileImageViewScreen.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rusa/screens/client/voyageDetails.dart';
import 'package:rusa/widgets/ProfileImageWidget.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/models/voyage_model.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  static const String _defaultProfileAsset = 'assets/images/profil.jpg';
  bool _showSearchBar = false;
  String _userName = '';
  String? _userPhotoUrl;
  List<Voyage> _voyages = [];
  bool _isLoadingVoyages = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVoyagesWithCacheFallback();
    _retryLoadCacheIfNeeded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Voyage> _getFilteredVoyages() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _voyages;

    return _voyages.where((v) {
      final fields = [
        v.villeDepart,
        v.villeArrivee,
        v.numeroBus,
        v.libelleTypeBus,
        v.date,
        v.heure,
      ];
      return fields.any((f) => f.toLowerCase().contains(q));
    }).toList();
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

    return entries
        .take(maxTags)
        .map((e) => display[e.key] ?? e.key)
        .toList();
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
              final isSelected =
                  selectedNorm == city.trim().toLowerCase();
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
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : Colors.white24,
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
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadVoyagesWithCacheFallback() async {
    await _loadVoyagesFromCache();
    if (!mounted) return;
    if (_voyages.isEmpty) {
      await _refreshVoyages();
    }
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

  Future<void> _loadVoyagesFromCache() async {
    if (!mounted) return;
    setState(() {
      _isLoadingVoyages = true;
    });

    try {
      final cachedVoyages = await CacheService.getVoyages();
      debugPrint(
        'ACCUEIL: voyages cache = ${cachedVoyages == null ? "null" : cachedVoyages.length}',
      );
      if (cachedVoyages != null && mounted) {
        setState(() {
          _voyages = cachedVoyages;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du cache voyages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVoyages = false;
        });
      }
    }
  }

  Future<void> _retryLoadCacheIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _voyages.isNotEmpty) return;

    final cachedVoyages = await CacheService.getVoyages();
    if (!mounted) return;

    if (cachedVoyages != null && cachedVoyages.isNotEmpty) {
      setState(() {
        _voyages = cachedVoyages;
      });
      debugPrint('ACCUEIL: cache rechargé après délai (${cachedVoyages.length})');
    }
  }

  Future<void> _refreshVoyages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingVoyages = true;
    });

    try {
      final voyageResponse = await ApiService.getAllVoyages();
      if (voyageResponse.isNotEmpty) {
        await CacheService.saveVoyages(voyageResponse);
        if (!mounted) return;
        setState(() {
          _voyages = voyageResponse;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des voyages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVoyages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeProfileAsset = (_userPhotoUrl ?? '').trim().isNotEmpty
        ? _userPhotoUrl!
        : _defaultProfileAsset;
    final filteredVoyages = _getFilteredVoyages();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil utilisateur
              Row(
                children: [
                  ProfileImageWidget(
                    imagePath: safeProfileAsset,
                    imageUrl: _userPhotoUrl,
                    userName: _userName,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileImageViewScreen(
                            imagePath: safeProfileAsset,
                            imageUrl: _userPhotoUrl,
                            userName: _userName,
                          ),
                        ),
                      );
                    },
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
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Barre de recherche conditionnelle
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prochains voyages',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 24),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllVoyagesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Voir tout",
                      style: TextStyle(color: Color(0xFF00E676)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Liste des voyages
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
                        onRefresh: _refreshVoyages,
                        color: const Color(0xFF00E676),
                        child: filteredVoyages.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.3,
                                  ),
                                  Center(
                                    child: Text(
                                      _searchQuery.trim().isEmpty
                                          ? 'Aucun voyage disponible'
                                          : 'Aucun résultat pour cette recherche',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: filteredVoyages.length,
                                itemBuilder: (context, index) {
                                  final voyage = filteredVoyages[index];
                                  return _buildVoyageCard(voyage);
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeatSelectionScreen(
                voyage: Voyage(
                  id: voyage.id,
                  dateDepart: voyage.dateDepart,
                  heureDepart: voyage.heureDepart,
                  prix: voyage.prix,
                  idBus: voyage.idBus,
                  idDestination: voyage.idDestination,
                  idSociete: voyage.idSociete,
                  statut: voyage.statut,
                  dateCreation: voyage.dateCreation,
                  numeroBus: voyage.numeroBus,
                  libelleTypeBus: voyage.libelleTypeBus,
                  villeDepart: voyage.villeDepart,
                  villeArrivee: voyage.villeArrivee,
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route principale avec villes sur la même ligne
              Row(
                children: [
                  Expanded(
                    child: Text(
                      voyage.villeDepart,
                      style: TextStyle(
                        color: const Color(0xFF00E676),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voyage.villeArrivee,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: const Color(0xFF00E676),
                        fontSize: 20,
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
                        style: TextStyle(
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
