import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/destination_model.dart';
import 'package:rusa/models/passager_embarque_model.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';

/// Liste des passagers déjà embarqués : destination → voyage → API.
class PassagersEmbarquesScreen extends StatefulWidget {
  const PassagersEmbarquesScreen({super.key});

  @override
  State<PassagersEmbarquesScreen> createState() =>
      _PassagersEmbarquesScreenState();
}

class _PassagersEmbarquesScreenState extends State<PassagersEmbarquesScreen> {
  static const _accent = Color(0xFF29F58B);
  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);

  final TextEditingController _destinationSearchCtrl = TextEditingController();
  Timer? _destinationSearchDebounce;

  int _idSociete = 0;
  bool _loadingInit = true;
  bool _loadingDestinations = false;
  String? _initError;

  List<Destination> _destinations = [];
  String _destinationSearchQuery = '';
  Destination? _destination;
  List<Voyage> _voyages = [];
  bool _loadingVoyages = false;

  Voyage? _voyageSelection;
  List<PassagerEmbarque> _passagers = [];
  bool _loadingPassagers = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _destinationSearchDebounce?.cancel();
    _destinationSearchCtrl.dispose();
    super.dispose();
  }

  void _onDestinationSearchChanged(String value) {
    setState(() => _destinationSearchQuery = value);
    _destinationSearchDebounce?.cancel();
    _destinationSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadDestinations();
    });
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingInit = true;
      _initError = null;
    });
    final auth = await CacheService.getAuthResponse();
    final idSoc = auth?.utilisateur.idSociete ?? 0;
    if (idSoc <= 0) {
      if (mounted) {
        setState(() {
          _idSociete = 0;
          _loadingInit = false;
          _initError =
              'Société introuvable pour ce compte. Reconnecte-toi ou contacte l’administrateur.';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _idSociete = idSoc;
      _loadingInit = false;
    });
    await _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    if (_idSociete <= 0) return;
    final q = _destinationSearchCtrl.text.trim();
    setState(() {
      _loadingDestinations = true;
      _destinationSearchQuery = q;
    });
    final list = await ApiService.getDestinationsBySociete(
      _idSociete,
      searchTerm: q.isEmpty ? null : q,
      sortBy: 'villeDepart',
      sortDescending: false,
    );
    if (!mounted) return;

    final prevId = _destination?.idDestination;
    Destination? newSelection = _destination;
    if (newSelection != null) {
      try {
        newSelection = list.firstWhere(
          (d) => d.idDestination == newSelection!.idDestination,
        );
      } catch (_) {
        newSelection = null;
      }
    }
    if (newSelection == null && list.length == 1) {
      newSelection = list.first;
    }

    setState(() {
      _destinations = list;
      _loadingDestinations = false;
      _destination = newSelection;
      if (newSelection == null) {
        _voyages = [];
        _voyageSelection = null;
        _passagers = [];
      }
    });

    if (!mounted || newSelection == null) return;
    final selectionChanged = newSelection.idDestination != prevId;
    if (selectionChanged) {
      await _loadVoyagesPourDestination(newSelection);
    }
  }

  Future<void> _loadVoyagesPourDestination(Destination d) async {
    setState(() {
      _loadingVoyages = true;
      _voyages = [];
      _voyageSelection = null;
      _passagers = [];
    });
    final voyages = await ApiService.getVoyagesByDestination(d.idDestination);
    if (!mounted) return;
    setState(() {
      _voyages = voyages;
      _loadingVoyages = false;
    });
  }

  Future<void> _loadPassagers(Voyage v) async {
    setState(() {
      _voyageSelection = v;
      _loadingPassagers = true;
      _passagers = [];
    });
    final list = await ApiService.getPassagersEmbarques(
      idDestination: v.idDestination,
      idVehicule: v.idVehicule,
      dateDepart: v.dateDepart,
      heureDepart: v.heureDepart,
    );
    if (!mounted) return;
    setState(() {
      _passagers = list;
      _loadingPassagers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Passagers embarqués',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              color: _accent,
              onRefresh: () async {
                if (_idSociete > 0) {
                  await _loadDestinations();
                } else {
                  await _bootstrap();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildDestinationSearchField(),
                  const SizedBox(height: 12),
                  Text(
                    'Choisis une destination puis un départ pour voir la liste des passagers embarqués.',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDestinationField(),
                  const SizedBox(height: 20),
                  if (_destination != null) ...[
                    Row(
                      children: [
                        Text(
                          'Départs',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (_loadingVoyages) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (!_loadingVoyages && _voyages.isEmpty)
                      Text(
                        'Aucun voyage programmé pour cette destination.',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      )
                    else
                      ..._voyages.map((v) => _buildVoyageTile(v)),
                  ],
                  if (_voyageSelection != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Embarqués (${_voyageSelection!.date} ${_voyageSelection!.heure} — bus ${_voyageSelection!.numeroBus})',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_loadingPassagers)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_loadingPassagers && _passagers.isEmpty)
                      Text(
                        'Aucun passager embarqué pour ce créneau.',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      )
                    else
                      ..._passagers.map(_buildPassagerCard),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDestinationSearchField() {
    return TextField(
      controller: _destinationSearchCtrl,
      onChanged: _onDestinationSearchChanged,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      cursorColor: _accent,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Rechercher une destination (ville départ ou arrivée)',
        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: _accent, size: 22),
        suffixIcon: _loadingDestinations
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
              )
            : _destinationSearchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                onPressed: () {
                  _destinationSearchCtrl.clear();
                  _onDestinationSearchChanged('');
                },
              ),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
    );
  }

  Widget _buildDestinationField() {
    if (_loadingDestinations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
        ),
      );
    }
    if (_destinations.isEmpty) {
      final q = _destinationSearchQuery.trim();
      if (q.isNotEmpty) {
        return Text(
          'Aucun résultat pour « $q ».',
          style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 13),
        );
      }
      return Text(
        'Aucune destination active pour cette société.',
        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
      );
    }
    Destination? valeurDropdown;
    if (_destination != null) {
      for (final d in _destinations) {
        if (d.idDestination == _destination!.idDestination) {
          valeurDropdown = d;
          break;
        }
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Destination>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2622),
          hint: Text(
            'Choisir une destination',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
          ),
          value: valeurDropdown,
          icon: const Icon(Icons.expand_more, color: _accent),
          items: _destinations.map((d) {
            final jd = d.jourDepart?.trim();
            final label = (jd != null && jd.isNotEmpty)
                ? '${d.villeDepart} → ${d.villeArrivee} · $jd'
                : '${d.villeDepart} → ${d.villeArrivee}';
            return DropdownMenuItem<Destination>(
              value: d,
              child: Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (d) {
            if (d == null) return;
            setState(() => _destination = d);
            _loadVoyagesPourDestination(d);
          },
        ),
      ),
    );
  }

  Widget _buildVoyageTile(Voyage v) {
    final selected = _voyageSelection?.id == v.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _loadPassagers(v),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1A2820) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? _accent.withValues(alpha: 0.6)
                    : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: selected ? _accent : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${v.date} · ${v.heure}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${v.libelleTypeBus} · ${v.numeroBus}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: selected ? _accent : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassagerCard(PassagerEmbarque p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.titre,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (p.sousTitre != null && p.sousTitre!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p.sousTitre!,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
