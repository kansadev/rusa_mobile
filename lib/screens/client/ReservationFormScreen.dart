import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/categorie_siege_model.dart';
import '../../models/reservation_with_passengers_request.dart';
import '../../models/voyage_model.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/session_service.dart';
import 'TicketReceiptScreen.dart';

class ReservationFormScreen extends StatefulWidget {
  final Voyage voyage;

  const ReservationFormScreen({super.key, required this.voyage});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

enum _ReservationMode { selfOnly, othersOnly, selfAndOthers }

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placesController = TextEditingController(text: '1');
  final _montantPayeController = TextEditingController();
  final _referenceController = TextEditingController();

  bool _isLoading = false;
  bool _isCaissier = false;
  _ReservationMode _reservationMode = _ReservationMode.selfOnly;
  String _methodePaiement = 'Mobile Money';

  /// Passagers additionnels (formulaire unique → liste).
  final List<_PassagerSaisi> _passagersAjoutes = [];
  List<CategorieSiege> _categoriesSiege = [];
  int? _selfCategorieSiegeId;

  final _draftNom = TextEditingController();
  final _draftPhone = TextEditingController();
  final _draftEmail = TextEditingController();
  final _draftDocType = TextEditingController();
  final _draftDocNum = TextEditingController();
  final _draftGenre = TextEditingController();
  int? _draftCategorieSiegeId;

  @override
  void initState() {
    super.initState();
    _syncPlacesAndMontant();
    _loadRoleContext();
    _loadCategorieSieges();
  }

  /// Si l’API refuse le rôle (403), on peut quand même proposer les catégories
  /// présentes sur le voyage (`tarifs`), avec les bons `idCategorieSiege`.
  List<CategorieSiege> _categoriesFromVoyageTarifs() {
    final idSoc = widget.voyage.idSociete;
    final seen = <int>{};
    final out = <CategorieSiege>[];
    for (final t in widget.voyage.tarifs) {
      if (t.idCategorieSiege <= 0 || seen.contains(t.idCategorieSiege)) {
        continue;
      }
      seen.add(t.idCategorieSiege);
      final lib = t.libelle.trim().isEmpty
          ? 'Catégorie ${t.idCategorieSiege}'
          : t.libelle.trim();
      final code = lib.length <= 32 ? lib : lib.substring(0, 32);
      out.add(
        CategorieSiege(
          idCategorieSiege: t.idCategorieSiege,
          idSociete: idSoc,
          codeCategorieSiege: code,
          libelle: lib,
          statut: true,
        ),
      );
    }
    return out;
  }

  Future<void> _loadCategorieSieges() async {
    var categories = await ApiService.getCategorieSiegesBySociete(
      idSociete: widget.voyage.idSociete,
      actifsSeulement: true,
    );
    if (categories.isEmpty && widget.voyage.tarifs.isNotEmpty) {
      categories = _categoriesFromVoyageTarifs();
      debugPrint(
        'Catégories siège: liste vide depuis l’API — '
        'repli sur voyage.tarifs (${categories.length} catégorie(s)).',
      );
    }
    if (!mounted) return;
    setState(() {
      _categoriesSiege = categories;
      if (_selfCategorieSiegeId == null && categories.isNotEmpty) {
        _selfCategorieSiegeId = categories.first.idCategorieSiege;
      }
      _draftCategorieSiegeId ??= categories.isNotEmpty
          ? categories.first.idCategorieSiege
          : null;
      _syncPlacesAndMontant();
    });
  }

  Future<void> _loadRoleContext() async {
    final auth = await CacheService.getAuthResponse();
    if (!mounted || auth == null) return;
    final primaryRoleName = auth.primaryRole.nom.toLowerCase().trim();
    final roleName = primaryRoleName.isNotEmpty
        ? primaryRoleName
        : auth.nomRole.toLowerCase().trim();
    final isCaissier = roleName.contains('caiss');
    if (!mounted) return;
    setState(() {
      _isCaissier = isCaissier;
      if (_isCaissier && _reservationMode == _ReservationMode.selfOnly) {
        _reservationMode = _ReservationMode.selfAndOthers;
      }
      _syncPlacesAndMontant();
    });
  }

  bool get _showPassengersSection {
    return _isCaissier || _reservationMode != _ReservationMode.selfOnly;
  }

  @override
  void dispose() {
    _placesController.dispose();
    _montantPayeController.dispose();
    _referenceController.dispose();
    _draftNom.dispose();
    _draftPhone.dispose();
    _draftEmail.dispose();
    _draftDocType.dispose();
    _draftDocNum.dispose();
    _draftGenre.dispose();
    super.dispose();
  }

  int get _nombrePlaces {
    final value = int.tryParse(_placesController.text.trim()) ?? 1;
    return value < 1 ? 1 : value;
  }

  String get _suffixeDevise {
    final c = widget.voyage.codeDevisePrix?.trim();
    if (c == null || c.isEmpty) return 'FC';
    return c;
  }

  /// Prix d’une place pour cette catégorie (tarifs du voyage, sinon `prix` global).
  double _prixPourCategorieSiege(int idCategorieSiege) {
    for (final t in widget.voyage.tarifs) {
      if (t.idCategorieSiege == idCategorieSiege) return t.prix;
    }
    if (widget.voyage.prix > 0) return widget.voyage.prix;
    if (widget.voyage.tarifs.isEmpty) return 0;
    return widget.voyage.tarifs
        .map((t) => t.prix)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Somme des tarifs : vous + chaque passager ajouté (chaque catégorie peut différer).
  double get _montantTotal {
    final idTit = _selfCategorieSiegeId;
    if (idTit == null) {
      if (widget.voyage.prix > 0) {
        return widget.voyage.prix * _nombrePlaces;
      }
      return 0;
    }
    var sum = _prixPourCategorieSiege(idTit);
    if (_showPassengersSection) {
      for (final p in _passagersAjoutes) {
        sum += _prixPourCategorieSiege(p.idCategorieSiege);
      }
    }
    return sum;
  }

  int get _requiredPlaces {
    final extra = _showPassengersSection ? _passagersAjoutes.length : 0;
    return 1 + extra;
  }

  void _syncPlacesAndMontant() {
    _placesController.text = _requiredPlaces.toString();
    final total = _montantTotal;
    if (total > 0) {
      _montantPayeController.text = total.toStringAsFixed(0);
    } else {
      _montantPayeController.clear();
    }
  }

  void _setReservationMode(_ReservationMode mode) {
    setState(() {
      _reservationMode = mode;
      _passagersAjoutes.clear();
      _clearDraft();
      _syncPlacesAndMontant();
    });
  }

  void _clearDraft() {
    _draftNom.clear();
    _draftPhone.clear();
    _draftEmail.clear();
    _draftDocType.clear();
    _draftDocNum.clear();
    _draftGenre.clear();
    _draftCategorieSiegeId = _categoriesSiege.isNotEmpty
        ? _categoriesSiege.first.idCategorieSiege
        : null;
  }

  void _addPassengerFromDraft() {
    final nom = _draftNom.text.trim();
    final tel = _draftPhone.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indique le nom complet du passager.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_draftCategorieSiegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis une catégorie de siège pour ce passager.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _passagersAjoutes.add(
        _PassagerSaisi(
          nomComplet: nom,
          telephone: tel,
          email: _draftEmail.text.trim(),
          documentType: _draftDocType.text.trim(),
          documentNumero: _draftDocNum.text.trim(),
          genre: _draftGenre.text.trim(),
          idCategorieSiege: _draftCategorieSiegeId!,
        ),
      );
      _clearDraft();
      _syncPlacesAndMontant();
    });
  }

  void _removePassengerAjoute(int index) {
    setState(() {
      _passagersAjoutes.removeAt(index);
      _syncPlacesAndMontant();
    });
  }

  String _libelleCategorie(int id) {
    for (final c in _categoriesSiege) {
      if (c.idCategorieSiege == id) {
        return '${c.codeCategorieSiege} — ${c.libelle}';
      }
    }
    return 'Cat. $id';
  }

  /// Contrat API : `email` absent ou vide → `null` dans le JSON.
  static String? _emailPourApi(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  Future<int> _resolveIdSite(Map<String, String> userData) async {
    if (widget.voyage.idSite > 0) return widget.voyage.idSite;

    final fromUser = int.tryParse((userData['idSite'] ?? '').trim());
    if (fromUser != null && fromUser > 0) return fromUser;

    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');
    if (authData != null && authData.isNotEmpty) {
      try {
        final decoded = json.decode(authData);
        if (decoded is Map<String, dynamic>) {
          final utilisateur = decoded['utilisateur'];
          if (utilisateur is Map<String, dynamic>) {
            final idSite = utilisateur['idSite'];
            if (idSite is int && idSite > 0) return idSite;
            if (idSite is String) {
              final parsed = int.tryParse(idSite);
              if (parsed != null && parsed > 0) return parsed;
            }
          }
          final agent = decoded['agent'];
          if (agent is Map<String, dynamic>) {
            final idSite = agent['idSite'];
            if (idSite is int && idSite > 0) return idSite;
            if (idSite is String) {
              final parsed = int.tryParse(idSite);
              if (parsed != null && parsed > 0) return parsed;
            }
          }
        }
      } catch (_) {}
    }
    return 0;
  }

  Future<void> _pickContactForDraft() async {
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.limited) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission contacts refusée.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone, ContactProperty.email},
      );
      if (!mounted) return;
      if (contacts.isEmpty) return;

      final selected = await showModalBottomSheet<Contact>(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        builder: (context) {
          return SafeArea(
            child: ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
              itemBuilder: (context, i) {
                final c = contacts[i];
                final name = (c.displayName ?? '').trim();
                final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
                return ListTile(
                  title: Text(
                    name.isEmpty ? 'Sans nom' : name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    phone.isEmpty ? 'Pas de numero' : phone,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          );
        },
      );

      if (selected == null || !mounted) return;
      final phone = selected.phones.isNotEmpty
          ? selected.phones.first.number
          : '';
      final email = selected.emails.isNotEmpty
          ? selected.emails.first.address
          : '';

      setState(() {
        _draftNom.text = selected.displayName ?? '';
        _draftPhone.text = phone;
        _draftEmail.text = email;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger les contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = SessionService();
    final userData = await session.getUserInfo();
    if (userData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session invalide. Reconnectez-vous.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final idUtilisateur = int.tryParse(userData['id'] ?? '0') ?? 0;
    final idClient = int.tryParse(userData['client_id'] ?? '0') ?? 0;
    final idSite = await _resolveIdSite(userData);
    final totalDu = _montantTotal;
    if (totalDu <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Montant total indisponible : vérifie les tarifs du voyage ou la catégorie de siège.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final montantPaye =
        double.tryParse(_montantPayeController.text.trim()) ?? 0;

    if (montantPaye <= 0 || montantPaye > totalDu) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Montant invalide : saisir un montant > 0 et ≤ ${totalDu.toStringAsFixed(0)} $_suffixeDevise.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final passagers = <ReservationPassengerData>[];
    if (_selfCategorieSiegeId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionne une catégorie de siège pour le client connecté.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final idCatTitulaire = _selfCategorieSiegeId!;
    final emailTitulaireBrut =
        (userData['email'] ?? userData['user_email'])?.toString();
    final currentUserPassenger = ReservationPassengerData(
      idClient: idClient,
      idCategorieSiege: idCatTitulaire,
      nomComplet: (userData['name'] ?? userData['user_name'] ?? '')
          .toString()
          .trim(),
      telephone: (userData['phone'] ?? userData['telephone'] ?? '')
          .toString()
          .trim(),
      email: _emailPourApi(emailTitulaireBrut),
      documentType: '',
      documentNumero: '',
      genre: '',
    );
    passagers.add(currentUserPassenger);

    if (_showPassengersSection) {
      if (_passagersAjoutes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoute au moins un passager à la liste.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      for (final p in _passagersAjoutes) {
        passagers.add(
          ReservationPassengerData(
            idCategorieSiege: p.idCategorieSiege,
            nomComplet: p.nomComplet,
            telephone: p.telephone,
            email: _emailPourApi(p.email),
            documentType: p.documentType,
            documentNumero: p.documentNumero,
            genre: p.genre,
          ),
        );
      }
    }

    if (_nombrePlaces < passagers.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nombre de places insuffisant: au moins ${passagers.length} place(s) requise(s).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = ReservationWithPassengersAndPaiementRequest(
        reservation: ReservationWithPassengersData(
          idVoyage: widget.voyage.id,
          idClient: idClient,
          nombreDePlace: _nombrePlaces,
          idUtilisateur: idUtilisateur,
          idSociete: widget.voyage.idSociete,
          idSite: idSite,
          passagers: passagers,
        ),
        paiement: PaiementWithSiteData(
          montantAPaye: totalDu,
          montantPaye: montantPaye,
          methodePaiement: _methodePaiement,
          referenceTransaction: _referenceController.text.trim().isEmpty
              ? 'TXN-${DateTime.now().millisecondsSinceEpoch}'
              : _referenceController.text.trim(),
          idUtilisateur: idUtilisateur,
          idSociete: widget.voyage.idSociete,
          idSite: idSite,
        ),
      );

      final response = await ApiService.reservationWithPassengersAndPaiement(
        request,
      );
      if (!mounted) return;

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Echec de la reservation.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation creee avec succes.'),
          backgroundColor: Color(0xFF00E676),
        ),
      );

      Navigator.pushReplacement(
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Nouvelle reservation',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.voyage.villeDepart} -> ${widget.voyage.villeArrivee}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _montantTotal > 0
                  ? 'Total dû (selon sièges) : ${_montantTotal.toStringAsFixed(0)} $_suffixeDevise'
                  : 'Tarifs : renseigne ta catégorie de siège pour afficher le total.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _placesController,
              label: 'Nombre de places',
              keyboardType: TextInputType.number,
              enabled: false,
            ),
            const SizedBox(height: 6),
            Text(
              'Mis à jour automatiquement (toi + passagers ajoutés).',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            if (!_isCaissier) ...[
              const Text(
                'Type de billet',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_ReservationMode>(
                selected: {_reservationMode},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    _setReservationMode(selection.first);
                  }
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.black
                        : Colors.white;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? const Color(0xFF00E676)
                        : const Color(0xFF2A2A2A);
                  }),
                ),
                segments: const [
                  ButtonSegment(
                    value: _ReservationMode.selfOnly,
                    label: Text('Moi'),
                  ),
                  ButtonSegment(
                    value: _ReservationMode.othersOnly,
                    label: Text('Autre(s)'),
                  ),
                  ButtonSegment(
                    value: _ReservationMode.selfAndOthers,
                    label: Text('Moi et autre(s)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Même pour une réservation pour autre(s), tes informations '
                'restent incluses comme titulaire.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (_showPassengersSection) ...[
              const SizedBox(height: 20),
              _buildDraftPassengersBlock(),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selfCategorieSiegeId,
              items: _categoriesSiege
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.idCategorieSiege,
                      child: Text('${c.codeCategorieSiege} - ${c.libelle}'),
                    ),
                  )
                  .toList(),
              onChanged: _categoriesSiege.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _selfCategorieSiegeId = value;
                        _syncPlacesAndMontant();
                      });
                    },
              decoration: _inputDecoration('Catégorie de siège (Vous)'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Text(
                'Indépendante des catégories choisies pour les autres passagers.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _montantPayeController,
              label: 'Montant payé',
              keyboardType: TextInputType.number,
              validator: (v) {
                final value = double.tryParse((v ?? '').trim()) ?? 0;
                final total = _montantTotal;
                if (total <= 0) {
                  return 'Total indisponible';
                }
                if (value <= 0 || value > total) {
                  return '> 0 et ≤ ${total.toStringAsFixed(0)}';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Rappel total: ${_montantTotal.toStringAsFixed(0)} $_suffixeDevise',
              style: const TextStyle(color: Color(0xFF00E676)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('methode_$_methodePaiement'),
              initialValue: _methodePaiement,
              items: const [
                DropdownMenuItem(
                  value: 'Mobile Money',
                  child: Text('Mobile Money'),
                ),
                DropdownMenuItem(value: 'Especes', child: Text('Espèces')),
                DropdownMenuItem(value: 'Carte', child: Text('Carte')),
              ],
              onChanged: (value) =>
                  setState(() => _methodePaiement = value ?? 'Mobile Money'),
              decoration: _inputDecoration('Méthode de paiement'),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _referenceController,
              label: 'Référence transaction (optionnel)',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Valider la reservation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftPassengersBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Autres passagers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Remplis le formulaire puis « Ajouter à la liste ». '
            'Le nombre de places augmente à chaque ajout. '
            'Chaque passager peut avoir une catégorie de siège différente. '
            'Le téléphone est facultatif (ex. réservation pour enfant).',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _draftCategorieSiegeId,
            items: _categoriesSiege
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.idCategorieSiege,
                    child: Text('${c.codeCategorieSiege} - ${c.libelle}'),
                  ),
                )
                .toList(),
            onChanged: _categoriesSiege.isEmpty
                ? null
                : (value) => setState(() => _draftCategorieSiegeId = value),
            decoration: _inputDecoration('Catégorie de siège (passager)'),
          ),
          const SizedBox(height: 10),
          _buildField(controller: _draftNom, label: 'Nom complet'),
          const SizedBox(height: 8),
          _buildField(
            controller: _draftPhone,
            label: 'Téléphone (optionnel, ex. enfant)',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          _buildField(
            controller: _draftEmail,
            label: 'Email (optionnel)',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _draftDocType,
                  label: 'Type document',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildField(
                  controller: _draftDocNum,
                  label: 'N° document',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildField(controller: _draftGenre, label: 'Genre (optionnel)'),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _pickContactForDraft,
                icon: const Icon(Icons.contacts_outlined),
                tooltip: 'Importer depuis les contacts',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addPassengerFromDraft,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Ajouter à la liste'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          if (_passagersAjoutes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Liste (${_passagersAjoutes.length})',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_passagersAjoutes.length, (i) {
              final p = _passagersAjoutes[i];
              return Card(
                color: const Color(0xFF252525),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    p.nomComplet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    [
                      p.telephone.isNotEmpty ? p.telephone : 'Pas de téléphone',
                      if (p.email.isNotEmpty) p.email,
                      _libelleCategorie(p.idCategorieSiege),
                    ].join('\n'),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    onPressed: () => _removePassengerAjoute(i),
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    tooltip: 'Retirer',
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF222222),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _PassagerSaisi {
  final String nomComplet;
  final String telephone;
  final String email;
  final String documentType;
  final String documentNumero;
  final String genre;
  final int idCategorieSiege;

  _PassagerSaisi({
    required this.nomComplet,
    required this.telephone,
    required this.email,
    required this.documentType,
    required this.documentNumero,
    required this.genre,
    required this.idCategorieSiege,
  });
}
