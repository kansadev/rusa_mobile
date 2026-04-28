import 'package:flutter/material.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rusa/screens/client/voyageDetails.dart';
import 'package:rusa/widgets/ProfileImageWidget.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/models/destination_model.dart';
import 'package:rusa/models/voyage_model.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  bool _showSearchBar = false;
  String _userName = '';
  List<Voyage> _voyages = [];
  bool _isLoadingVoyages = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVoyages();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Utilisateur';
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadVoyages() async {
    setState(() {
      _isLoadingVoyages = true;
    });

    try {
      final voyageResponse = await ApiService.getAllVoyages();

      if (voyageResponse.isNotEmpty) {
        setState(() {
          _voyages = voyageResponse;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des voyages: $e');
    } finally {
      setState(() {
        _isLoadingVoyages = false;
      });
    }
  }

  Future<void> _refreshVoyages() async {
    await _loadVoyages();
  }

  @override
  Widget build(BuildContext context) {
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
                    imagePath: 'assets/images/profil.jpg',
                    userName: _userName,
                    onTap: () {
                      // Action par défaut : navigation vers la visualisation
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
                        child: const TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
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
              // Toggle Switch (Aller simple / Aller-retour)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Aller simple',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Aller-retour',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
                        child: _voyages.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.3,
                                  ),
                                  Center(
                                    child: Text(
                                      'Aucun voyage disponible',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _voyages.length,
                                itemBuilder: (context, index) {
                                  final voyage = _voyages[index];
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
