import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_models.dart';
import '../../models/categorie_siege_model.dart';
import '../../widgets/caissier_client_picker_sheet.dart';
import '../../models/reservation_with_passengers_request.dart';
import '../../models/voyage_model.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/session_service.dart';
import 'MobileMoneyPendingScreen.dart';
import 'package:rusa/widgets/app_feedback.dart';
import 'package:rusa/widgets/payment_fee_notice.dart';
import 'package:rusa/screens/caissier/CaissierTicketReceiptScreen.dart';

import 'TicketReceiptScreen.dart';

class ReservationFormScreen extends StatefulWidget {
  final Voyage voyage;

  /// Client bénéficiaire (flux caissier).
  final Client? client;

  const ReservationFormScreen({super.key, required this.voyage, this.client});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

enum _ReservationMode { selfOnly, othersOnly, selfAndOthers }

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placesController = TextEditingController(text: '1');
  final _montantPayeController = TextEditingController();

  bool _isLoading = false;
  bool _isCaissier = false;
  bool _passagersAdditionnelsActifs = false;
  Client? _selectedClient;

  /// Vente en caisse : seul le client choisi compte comme passager, pas le caissier.
  bool get _isVenteCaissier => _isCaissier || widget.client != null;
  List<Client> _clientsForPicker = [];
  String? _clientsLoadError;
  int? _clientPassagerCategorieSiegeId;
  _ReservationMode _reservationMode = _ReservationMode.selfOnly;

  /// Valeurs attendues par l'API: `MOBILE_MONEY`, `CARTE_BANCAIRE`, et (caissier seulement) `CASH`.
  String _methodePaiement = 'MOBILE_MONEY';
  String? _mobileMoneyPhoneToSend;
  bool _isMobileMoneyPhoneConfirmed = false;

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
    _selectedClient = widget.client;
    if (widget.client != null) {
      _isCaissier = true;
      _methodePaiement = 'CASH';
    }
    _syncPlacesAndMontant();
    _loadRoleContext();
    _loadCategorieSieges();
  }

  bool get _countsSelectedClientAsPassenger =>
      _isVenteCaissier && _selectedClient != null;

  /// L'utilisateur connecté est-il lui-même un passager du billet ?
  /// En mode « Autre(s) », il réserve uniquement pour d'autres personnes.
  bool get _selfIsPassenger {
    if (_isVenteCaissier) return false;
    return _reservationMode != _ReservationMode.othersOnly;
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

  bool _isVoyageDepartPasse(Voyage v) {
    final raw = v.dateDepart.trim();
    if (raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final depDay = DateTime(local.year, local.month, local.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return depDay.isBefore(today);
  }

  /// Catégories proposées = tarifs du voyage (évite VP hors voyage, etc.).
  List<CategorieSiege> _categoriesPourCeVoyage(List<CategorieSiege> fromApi) {
    final tarifIds = widget.voyage.tarifs
        .where((t) => t.idCategorieSiege > 0)
        .map((t) => t.idCategorieSiege)
        .toSet();
    if (tarifIds.isEmpty) return fromApi;

    final filtered = fromApi
        .where((c) => tarifIds.contains(c.idCategorieSiege))
        .toList();
    if (filtered.isNotEmpty) return filtered;

    return _categoriesFromVoyageTarifs();
  }

  int? _defaultCategorieSiegeId(List<CategorieSiege> categories) {
    for (final t in widget.voyage.tarifs) {
      if (t.idCategorieSiege > 0) return t.idCategorieSiege;
    }
    if (categories.isNotEmpty) return categories.first.idCategorieSiege;
    return null;
  }

  Future<void> _loadCategorieSieges() async {
    var categories = await ApiService.getCategorieSiegesBySociete(
      idSociete: widget.voyage.idSociete,
      actifsSeulement: true,
    );
    if (widget.voyage.tarifs.isNotEmpty) {
      categories = _categoriesPourCeVoyage(categories);
      debugPrint(
        'Catégories siège pour voyage ${widget.voyage.id}: '
        '${categories.length} (filtrées sur tarifs).',
      );
    } else if (categories.isEmpty) {
      categories = _categoriesFromVoyageTarifs();
      debugPrint(
        'Catégories siège: repli sur voyage.tarifs (${categories.length}).',
      );
    }
    if (!mounted) return;
    final defaultId = _defaultCategorieSiegeId(categories);
    setState(() {
      _categoriesSiege = categories;
      if (defaultId != null) {
        _selfCategorieSiegeId ??= defaultId;
        _clientPassagerCategorieSiegeId ??= defaultId;
        _draftCategorieSiegeId ??= defaultId;
        if (_clientPassagerCategorieSiegeId != null &&
            !categories.any(
              (c) => c.idCategorieSiege == _clientPassagerCategorieSiegeId,
            )) {
          _clientPassagerCategorieSiegeId = defaultId;
        }
      }
      _syncPlacesAndMontant();
    });
  }

  Future<void> _loadRoleContext() async {
    if (widget.client != null) {
      if (!mounted) return;
      setState(() {
        _isCaissier = true;
        _selectedClient = widget.client;
        _methodePaiement = 'CASH';
        _syncPlacesAndMontant();
      });
      _ensureClientsLoaded();
      return;
    }
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
      if (isCaissier) {
        _methodePaiement = 'CASH';
      }
      _syncPlacesAndMontant();
    });
    if (isCaissier) {
      _ensureClientsLoaded();
    }
  }

  Future<void> _ensureClientsLoaded({bool force = false}) async {
    if (!force && _clientsForPicker.isNotEmpty) return;
    final list = await ApiService.getAllClients();
    if (!mounted) return;
    setState(() {
      if (list == null) {
        _clientsLoadError =
            'Impossible de charger les clients. Vérifiez vos droits.';
        _clientsForPicker = [];
      } else {
        _clientsForPicker = list;
        _clientsLoadError = null;
      }
    });
  }

  Future<void> _openClientPicker() async {
    if (_clientsForPicker.isEmpty) {
      await _ensureClientsLoaded(force: true);
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CaissierClientPickerSheet(
        clients: _clientsForPicker,
        loadError: _clientsLoadError,
        onRetry: () async {
          Navigator.pop(ctx);
          await _ensureClientsLoaded(force: true);
          if (mounted) await _openClientPicker();
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedClient = picked;
        _passagersAdditionnelsActifs = false;
        _passagersAjoutes.clear();
        _clearDraft();
        _mobileMoneyPhoneToSend = null;
        _isMobileMoneyPhoneConfirmed = false;
        _syncPlacesAndMontant();
      });
    }
  }

  Future<String?> _getMobileMoneyPhone() async {
    if (_isVenteCaissier) {
      return _normalizeMobileMoneyPhone(_selectedClient?.telephone);
    }
    final session = SessionService();
    final userData = await session.getUserInfo();
    final phone = (userData?['phone'] ?? userData?['telephone'] ?? '')
        .toString()
        .trim();
    return _normalizeMobileMoneyPhone(phone);
  }

  /// Format Mobile Money: indicatif obligatoire, sans '+'.
  /// Exemples:
  /// - +243812345678 -> 243812345678
  /// - 0812345678    -> 243812345678
  /// - 812345678     -> 243812345678
  String? _normalizeMobileMoneyPhone(String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) return null;

    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    // Préfixe international saisi en "00"
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // DRC par défaut: 243
    if (digits.startsWith('243')) return digits;
    if (digits.length == 10 && digits.startsWith('0')) {
      return '243${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return '243$digits';
    }
    return digits;
  }

  Future<String?> _confirmMobileMoneyPhone(String initialPhone) async {
    String mobilePhone = _normalizeMobileMoneyPhone(initialPhone) ?? '';

    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 28 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirmer votre numéro ',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                PaymentFeesLearnMoreText(
                  prefix: 'Ce numéro sera utilisé pour le paiement de votre billet.',
                  voyage: widget.voyage,
                  isCaissier: _isVenteCaissier,
                  fontSize: 12,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _normalizeMobileMoneyPhone(initialPhone) ?? initialPhone,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: 0971234567',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00E676)),
                    ),
                  ),
                  onChanged: (v) => mobilePhone = v.trim(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final trimmed = _normalizeMobileMoneyPhone(mobilePhone);
                          if (trimmed == null || trimmed.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Le numéro ne peut pas être vide.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx, trimmed);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Confirmer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePaymentMethodChanged(String? value) {
    final newMethod = value ??
        (_isCaissier ? 'CASH' : 'MOBILE_MONEY');
    final previousMethod = _methodePaiement;

    if (newMethod != 'MOBILE_MONEY') {
      setState(() {
        _methodePaiement = newMethod;
        _mobileMoneyPhoneToSend = null;
        _isMobileMoneyPhoneConfirmed = false;
      });
      _syncPlacesAndMontant();
      return;
    }

    // Traiter Mobile Money en async (confirmation du numéro).
    _handleMobileMoneySelection(previousMethod);
  }

  /// Ouvre le bottom sheet de confirmation (numéro modifiable).
  Future<String?> _promptAndConfirmMobileMoneyPhone() async {
    var initial = _mobileMoneyPhoneToSend?.trim() ?? '';
    if (initial.isEmpty) {
      initial = (await _getMobileMoneyPhone())?.trim() ?? '';
    }
    return _confirmMobileMoneyPhone(initial);
  }

  void _handleMobileMoneySelection(String previousMethod) async {
    setState(() => _methodePaiement = 'MOBILE_MONEY');

    final confirmedPhone = await _promptAndConfirmMobileMoneyPhone();
    if (!mounted) return;

    if (confirmedPhone != null && confirmedPhone.trim().isNotEmpty) {
      setState(() {
        _mobileMoneyPhoneToSend = confirmedPhone.trim();
        _isMobileMoneyPhoneConfirmed = true;
      });
      _syncPlacesAndMontant();
    } else {
      setState(() {
        _methodePaiement = previousMethod;
        _mobileMoneyPhoneToSend = null;
        _isMobileMoneyPhoneConfirmed = false;
      });
    }
  }

  bool get _showPassengersSection {
    if (_isVenteCaissier) {
      return _selectedClient != null && _passagersAdditionnelsActifs;
    }
    return _reservationMode != _ReservationMode.selfOnly;
  }

  void _setPassagersAdditionnelsActifs(bool value) {
    setState(() {
      _passagersAdditionnelsActifs = value;
      if (!value) {
        _passagersAjoutes.clear();
        _clearDraft();
      }
      _syncPlacesAndMontant();
    });
  }

  @override
  void dispose() {
    _placesController.dispose();
    _montantPayeController.dispose();
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

  String get _suffixeDeviseMajoration =>
      widget.voyage.deviseMajorationPaieElectronique;

  bool get _isPaiementElectronique =>
      _methodePaiement == 'MOBILE_MONEY' ||
      _methodePaiement == 'CARTE_BANCAIRE';

  /// Somme des tarifs billets uniquement (hors majoration électronique).
  double get _montantBillets {
    if (_isVenteCaissier && _selectedClient != null) {
      final catId = _clientPassagerCategorieSiegeId;
      if (catId == null) return 0;
      var sum = _prixPourCategorieSiege(catId);
      for (final p in _passagersAjoutes) {
        sum += _prixPourCategorieSiege(p.idCategorieSiege);
      }
      return sum;
    }

    var sum = 0.0;
    if (_selfIsPassenger) {
      final idTit = _selfCategorieSiegeId;
      if (idTit != null) {
        sum += _prixPourCategorieSiege(idTit);
      } else if (widget.voyage.prix > 0) {
        sum += widget.voyage.prix;
      }
    }
    if (_showPassengersSection && !_isVenteCaissier) {
      for (final p in _passagersAjoutes) {
        sum += _prixPourCategorieSiege(p.idCategorieSiege);
      }
    }
    return sum;
  }

  double get _montantMajorationElectronique {
    if (!_isPaiementElectronique) return 0;
    return widget.voyage.majorationPaieElectroniquePour(_requiredPlaces);
  }

  /// Total dû (billets + majoration électronique si applicable).
  double get _montantTotalDu => _montantBillets + _montantMajorationElectronique;

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

  int get _requiredPlaces {
    if (_isVenteCaissier) {
      if (_selectedClient == null) return 0;
      return 1 + _passagersAjoutes.length;
    }
    if (_countsSelectedClientAsPassenger) {
      return 1 + _passagersAjoutes.length;
    }
    final selfCount = _selfIsPassenger ? 1 : 0;
    final extra = _showPassengersSection ? _passagersAjoutes.length : 0;
    final total = selfCount + extra;
    return total < 1 ? 1 : total;
  }

  void _syncPlacesAndMontant() {
    _placesController.text = _requiredPlaces.toString();
    final total = _montantTotalDu;
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
    for (final t in widget.voyage.tarifs) {
      if (t.idCategorieSiege == id && t.libelle.trim().isNotEmpty) {
        return t.libelle.trim();
      }
    }
    for (final c in _categoriesSiege) {
      if (c.idCategorieSiege == id) {
        return '${c.codeCategorieSiege} — ${c.libelle}';
      }
    }
    return 'Cat. $id';
  }

  DropdownMenuItem<int> _categorieDropdownItem(int id) {
    return DropdownMenuItem<int>(
      value: id,
      child: Text(_libelleCategorie(id), overflow: TextOverflow.ellipsis),
    );
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
                  tileColor: const Color(0xFF252525),
                  splashColor: Colors.white12,
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
    if (_isVoyageDepartPasse(widget.voyage)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce voyage est déjà passé. Réservation impossible.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }
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
    final idClient = _isVenteCaissier
        ? (_selectedClient?.idClient ?? 0)
        : (int.tryParse(userData['client_id'] ?? '0') ?? 0);
    final idSite = await _resolveIdSite(userData);

    if (_isVenteCaissier && idClient <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez ou créez un client avant de valider.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final totalDu = _montantTotalDu;
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

    if (_methodePaiement == 'MOBILE_MONEY' && !_isMobileMoneyPhoneConfirmed) {
      final confirmedPhone = await _promptAndConfirmMobileMoneyPhone();
      if (!mounted) return;
      if (confirmedPhone == null || confirmedPhone.trim().isEmpty) {
        return;
      }
      setState(() {
        _mobileMoneyPhoneToSend = confirmedPhone.trim();
        _isMobileMoneyPhoneConfirmed = true;
      });
    }

    // Champs additionnels requis par certains endpoints de paiement électronique.
    final String? phoneForPayment = _isVenteCaissier
        ? _selectedClient?.telephone.trim()
        : (userData['phone'] ?? userData['telephone'] ?? '').toString().trim();

    final String? codeDevisePrix = widget.voyage.codeDevisePrix?.trim();
    final String? codeDevisePaiement =
        (codeDevisePrix != null && codeDevisePrix.isNotEmpty)
        ? codeDevisePrix
        : (widget.voyage.codeDevisePrincipale?.trim().isNotEmpty == true
              ? widget.voyage.codeDevisePrincipale?.trim()
              : null);

    final String? phoneForElectronic = _methodePaiement == 'MOBILE_MONEY'
        ? _mobileMoneyPhoneToSend
        : _methodePaiement == 'CARTE_BANCAIRE'
        ? phoneForPayment
        : null;

    final passagers = <ReservationPassengerData>[];

    if (_isVenteCaissier && _selectedClient != null) {
      final catClient = _clientPassagerCategorieSiegeId;
      if (catClient == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choisissez une catégorie de siège pour le client.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final c = _selectedClient!;
      passagers.add(
        ReservationPassengerData(
          idClient: c.idClient,
          idCategorieSiege: catClient,
          nomComplet: c.nomClient,
          telephone: c.telephone,
          email: _emailPourApi(c.emailClient),
          documentType: '',
          documentNumero: '',
          genre: c.genreClient,
        ),
      );
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
    } else {
      if (_selfIsPassenger) {
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
        final emailTitulaireBrut = (userData['email'] ?? userData['user_email'])
            ?.toString();
        passagers.add(
          ReservationPassengerData(
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
          ),
        );
      }

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
          phone: phoneForElectronic,
          codeDevisePaiement: codeDevisePaiement,
          idUtilisateur: idUtilisateur,
          idSociete: widget.voyage.idSociete,
          idSite: idSite,
        ),
      );

      if (_methodePaiement == 'MOBILE_MONEY' ||
          _methodePaiement == 'CARTE_BANCAIRE') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MobileMoneyPendingScreen(
              request: request,
              isVenteCaissier: _isVenteCaissier,
            ),
          ),
        );
        return;
      }

      final result = await ApiService.reservationWithPassengersAndPaiement(
        request,
      );
      if (!mounted) return;

      if (!result.isSuccess || result.response == null) {
        AppFeedback.showError(
          context,
          result.errorMessage ??
              'Échec de la réservation. Essayez une autre catégorie de siège.',
        );
        return;
      }

      final response = result.response!;

      AppFeedback.showSuccess(
        context,
        _isVenteCaissier
            ? 'Vente enregistrée avec succès.'
            : 'Réservation créée avec succès.',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _isVenteCaissier
              ? CaissierTicketReceiptScreen(
                  idReservation: response.reservation.idReservation,
                  paiementHint: response.paiement,
                )
              : TicketReceiptScreen(
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

  Widget _buildResumeMontants({bool compact = false}) {
    final billets = _montantBillets;
    final majoration = _montantMajorationElectronique;
    final total = _montantTotalDu;
    final afficheFraisTransaction = _isPaiementElectronique;

    if (billets <= 0 && total <= 0) {
      return Text(
        'Tarifs : renseigne ta catégorie de siège pour afficher le total.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: compact ? 0.55 : 0.7),
          fontSize: compact ? 12 : 13,
        ),
      );
    }

    final lines = <Widget>[
      if (!compact || majoration <= 0)
        Text(
          'Billets : ${billets.toStringAsFixed(0)} $_suffixeDevise',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: compact ? 12 : 13,
          ),
        ),
      if (afficheFraisTransaction && majoration > 0) ...[
        if (!compact) const SizedBox(height: 4),
        Text(
          'Frais de transaction '
          '($_requiredPlaces × ${widget.voyage.montAddPaieElectronique.toStringAsFixed(0)} '
          '$_suffixeDeviseMajoration) : ${majoration.toStringAsFixed(0)} $_suffixeDeviseMajoration',
          style: TextStyle(
            color: Colors.orange.shade200,
            fontSize: compact ? 11 : 12,
          ),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PaymentFeesLearnMoreText(
              prefix: 'Inclus dans le total affiché (par passager).',
              voyage: widget.voyage,
              isCaissier: _isVenteCaissier,
            ),
          ),
      ],
      SizedBox(height: compact ? 4 : 6),
      Text(
        'Total affiché : ${total.toStringAsFixed(0)} $_suffixeDevise',
        style: TextStyle(
          color: const Color(0xFF00E676),
          fontWeight: FontWeight.w700,
          fontSize: compact ? 13 : 14,
        ),
      ),
      if (afficheFraisTransaction && (compact || majoration <= 0)) ...[
        SizedBox(height: compact ? 2 : 4),
        PaymentFeesLearnMoreText(
          voyage: widget.voyage,
          isCaissier: _isVenteCaissier,
          fontSize: compact ? 11 : 12,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
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
        title: Text(
          _isVenteCaissier ? 'Vente de billet' : 'Nouvelle reservation',
          style: const TextStyle(color: Colors.white, fontSize: 20),
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
            _buildResumeMontants(),
            if (_isVenteCaissier) ...[
              _buildCaissierClientSection(),
              const SizedBox(height: 16),
            ],
            if (!_isVenteCaissier || _selectedClient != null) ...[
              const SizedBox(height: 16),
              _buildField(
                controller: _placesController,
                label: 'Nombre de places',
                keyboardType: TextInputType.number,
                enabled: false,
              ),
              const SizedBox(height: 6),
              Text(
                _isVenteCaissier
                    ? (_passagersAdditionnelsActifs
                          ? 'Client bénéficiaire + passagers additionnels.'
                          : 'Une place pour le client bénéficiaire.')
                    : (_reservationMode == _ReservationMode.othersOnly
                          ? 'Mis à jour automatiquement (passagers ajoutés).'
                          : 'Mis à jour automatiquement (toi + passagers ajoutés).'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              if (!_isVenteCaissier) ...[
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
                Text(
                  _reservationMode == _ReservationMode.othersOnly
                      ? 'Réservation pour d\'autres passagers uniquement : '
                            'tu n\'es pas compté comme passager.'
                      : 'Tes informations sont incluses comme passager du billet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              if (_isVenteCaissier && _selectedClient != null) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SwitchListTile(
                    tileColor: const Color(0xFF222222),
                    value: _passagersAdditionnelsActifs,
                    onChanged: _setPassagersAdditionnelsActifs,
                    activeThumbColor: const Color(0xFF29F58B),
                    title: const Text(
                      'Passagers additionnels',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Activer pour ajouter d\'autres voyageurs sur ce billet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              if (_showPassengersSection) ...[
                const SizedBox(height: 16),
                _buildDraftPassengersBlock(
                  title: _isVenteCaissier
                      ? 'Passagers additionnels'
                      : 'Autres passagers',
                ),
              ],
              const SizedBox(height: 16),
              if (_isVenteCaissier) ...[
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _clientPassagerCategorieSiegeId,
                  items: _categoriesSiege
                      .map((c) => _categorieDropdownItem(c.idCategorieSiege))
                      .toList(),
                  onChanged: _categoriesSiege.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _clientPassagerCategorieSiegeId = value;
                            _syncPlacesAndMontant();
                          });
                        },
                  decoration: _inputDecoration('Catégorie de siège (client)'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Text(
                    'Choisissez une catégorie avec des places libres sur ce voyage. '
                    'Si la vente échoue (ex. VP complet), essayez une autre catégorie.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ] else if (_selfIsPassenger) ...[
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selfCategorieSiegeId,
                  items: _categoriesSiege
                      .map((c) => _categorieDropdownItem(c.idCategorieSiege))
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
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('methode_$_methodePaiement'),
                initialValue: _isCaissier
                    ? (_methodePaiement == 'MOBILE_MONEY' ||
                              _methodePaiement == 'CARTE_BANCAIRE' ||
                              _methodePaiement == 'CASH')
                          ? _methodePaiement
                          : 'CASH'
                    : (_methodePaiement == 'MOBILE_MONEY' ||
                          _methodePaiement == 'CARTE_BANCAIRE')
                    ? _methodePaiement
                    : 'MOBILE_MONEY',
                items: _isCaissier
                    ? const [
                        DropdownMenuItem(
                          value: 'MOBILE_MONEY',
                          child: Text('Mobile Money'),
                        ),
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'CARTE_BANCAIRE',
                          child: Text('Carte'),
                        ),
                      ]
                    : const [
                        DropdownMenuItem(
                          value: 'MOBILE_MONEY',
                          child: Text('Mobile Money'),
                        ),
                        DropdownMenuItem(
                          value: 'CARTE_BANCAIRE',
                          child: Text('Carte'),
                        ),
                      ],
                onChanged: _handlePaymentMethodChanged,
                decoration: _inputDecoration('Méthode de paiement'),
              ),
              const SizedBox(height: 8),
              _buildResumeMontants(compact: true),
              const SizedBox(height: 12),
              _buildField(
                controller: _montantPayeController,
                label: 'Montant payé',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim()) ?? 0;
                  final total = _montantTotalDu;
                  if (total <= 0) {
                    return 'Total indisponible';
                  }
                  if (value <= 0 || value > total) {
                    return '> 0 et ≤ ${total.toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed:
                  (_isLoading ||
                      _isVoyageDepartPasse(widget.voyage) ||
                      (_isVenteCaissier && _selectedClient == null))
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isVoyageDepartPasse(widget.voyage)
                    ? Colors.white24
                    : const Color(0xFF00E676),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isVoyageDepartPasse(widget.voyage)
                          ? 'Voyage passé'
                          : (_isVenteCaissier
                                ? 'Valider la vente'
                                : 'Valider la reservation'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaissierClientSection() {
    final c = _selectedClient;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF29F58B).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client de la vente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (c != null) ...[
            Text(
              c.nomClient,
              style: const TextStyle(
                color: Color(0xFF29F58B),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${c.telephone} · ${c.emailClient}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ] else
            Text(
              'Aucun client sélectionné.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openClientPicker,
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(c == null ? 'Choisir un client' : 'Changer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF29F58B),
                    side: const BorderSide(color: Color(0xFF29F58B)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftPassengersBlock({String title = 'Autres passagers'}) {
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
          Text(
            title,
            style: const TextStyle(
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
            isExpanded: true,
            initialValue: _draftCategorieSiegeId,
            items: _categoriesSiege
                .map((c) => _categorieDropdownItem(c.idCategorieSiege))
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
                  tileColor: const Color(0xFF2C2C2C),
                  splashColor: Colors.white12,
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
