import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/screens/caissier/CaissierAddClientScreen.dart';
import 'package:rusa/screens/caissier/CaissierClientDetailsScreen.dart';
import 'package:rusa/services/api_service.dart';

enum _ClientListScope { societe, plateforme }

/// Clients société (après réservation) + clients plateforme Rusa (création).
class CaissierClientsListScreen extends StatefulWidget {
  final bool showBack;

  const CaissierClientsListScreen({super.key, this.showBack = true});

  @override
  State<CaissierClientsListScreen> createState() =>
      _CaissierClientsListScreenState();
}

class _CaissierClientsListScreenState extends State<CaissierClientsListScreen> {
  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);
  static const _accent = Color(0xFF29F58B);
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _ClientListScope _scope = _ClientListScope.societe;
  int _idSociete = 0;
  List<Client> _clients = [];
  int _totalCount = 0;
  int _nextPageNumber = 1;
  bool _hasNextPage = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Timer? _searchDebounce;
  int? _selectedClientId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _idSociete = await ApiService.getCurrentSocieteId();
    if (!mounted) return;
    if (_idSociete <= 0) {
      setState(() {
        _loading = false;
        _error = 'Société introuvable. Reconnectez-vous.';
      });
      return;
    }
    await _loadClients(reset: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _loadClients(reset: true);
    });
  }

  Future<ClientPagedResponse?> _fetchClientsPage(int pageNumber) {
    final search = _searchController.text.trim();
    if (_scope == _ClientListScope.plateforme) {
      return ApiService.getClientsPaged(
        pageNumber: pageNumber,
        pageSize: _pageSize,
        searchTerm: search,
        sortBy: 'idClient',
        sortDescending: true,
        includeInactive: true,
      );
    }
    return ApiService.getClientsBySocietePaged(
      idSociete: _idSociete,
      pageNumber: pageNumber,
      pageSize: _pageSize,
      searchTerm: search,
      sortBy: 'idClient',
      sortDescending: true,
      includeInactive: true,
    );
  }

  void _onScopeChanged(_ClientListScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _loadClients(reset: true);
  }

  Future<void> _loadClients({required bool reset}) async {
    if (_scope == _ClientListScope.societe && _idSociete <= 0) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _nextPageNumber = 1;
        _hasNextPage = true;
        _clients = [];
      });
    }

    final response = await _fetchClientsPage(1);

    if (!mounted) return;

    if (response == null) {
      setState(() {
        _loading = false;
        _error = _scope == _ClientListScope.plateforme
            ? 'Impossible de charger les clients plateforme. Vérifiez la connexion.'
            : 'Impossible de charger les clients. Vérifiez la connexion ou vos droits.';
        _clients = [];
        _hasNextPage = false;
      });
      return;
    }

    setState(() {
      _clients = response.data;
      _totalCount = response.totalCount;
      _nextPageNumber = response.pageNumber + 1;
      _hasNextPage = response.hasNextPage;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNextPage || _loading) return;
    if (_scope == _ClientListScope.societe && _idSociete <= 0) return;

    setState(() => _loadingMore = true);

    final response = await _fetchClientsPage(_nextPageNumber);

    if (!mounted) return;

    if (response == null) {
      setState(() => _loadingMore = false);
      return;
    }

    setState(() {
      _clients = [..._clients, ...response.data];
      _totalCount = response.totalCount;
      _nextPageNumber = response.pageNumber + 1;
      _hasNextPage = response.hasNextPage;
      _loadingMore = false;
    });
  }

  Future<void> _openAddClient() async {
    final created = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (context) => const CaissierAddClientScreen()),
    );
    if (created == null || !mounted) return;

    Client? newClient;
    if (created is Client) {
      newClient = created;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Client créé sur la plateforme Rusa. Il apparaîtra dans votre société '
          'après sa première réservation.',
        ),
        duration: Duration(seconds: 5),
      ),
    );

    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);

    setState(() {
      _scope = _ClientListScope.plateforme;
      _selectedClientId = newClient?.idClient;
    });

    await _loadClients(reset: true);

    if (!mounted || newClient == null) return;

    final createdClient = newClient;
    setState(() {
      _selectedClientId = createdClient.idClient;
      if (!_clients.any((c) => c.idClient == createdClient.idClient)) {
        _clients = [createdClient, ..._clients];
        _totalCount += 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _scopeLabel(_ClientListScope scope) => switch (scope) {
        _ClientListScope.societe => 'Ma société',
        _ClientListScope.plateforme => 'Plateforme Rusa',
      };

  String? _clientBadge(Client c) {
    if (_scope == _ClientListScope.societe) {
      return c.isLinkedToSociete(_idSociete) ? null : 'Historique';
    }
    if (!c.hasReservationHistory) {
      return 'Plateforme Rusa';
    }
    if (c.isLinkedToSociete(_idSociete)) {
      return 'Ma société';
    }
    return 'Autre société';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        leading: widget.showBack
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              )
            : null,
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _totalCount > 0 ? 'Clients ($_totalCount)' : 'Clients',
          style: GoogleFonts.caveat(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
            ),
            onPressed: _openAddClient,
            tooltip: 'Nouveau client',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<_ClientListScope>(
              segments: [
                ButtonSegment(
                  value: _ClientListScope.societe,
                  label: Text(_scopeLabel(_ClientListScope.societe)),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _ClientListScope.plateforme,
                  label: Text(_scopeLabel(_ClientListScope.plateforme)),
                  icon: const Icon(Icons.public_rounded, size: 18),
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => _onScopeChanged(s.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;
                  }
                  return Colors.white70;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _accent;
                  }
                  return _card;
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              _scope == _ClientListScope.societe
                  ? 'Clients ayant déjà réservé au moins une fois avec votre société.'
                  : 'Tous les clients Rusa, y compris ceux créés récemment '
                      '(rattachés à la plateforme avant leur première réservation).',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, e-mail, téléphone…)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _accent, width: 1),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _accent,
              onRefresh: () => _loadClients(reset: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: _accent)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_clients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _scope == _ClientListScope.societe
                    ? (_searchController.text.trim().isEmpty
                        ? 'Aucun client n\'a encore réservé avec votre société.\n'
                            'Créez un client ou consultez l\'onglet Plateforme Rusa.'
                        : 'Aucun résultat pour cette recherche.')
                    : (_searchController.text.trim().isEmpty
                        ? 'Aucun client sur la plateforme.'
                        : 'Aucun résultat pour cette recherche.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ],
      );
    }

    final itemCount = _clients.length + (_loadingMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= _clients.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
            ),
          );
        }

        final c = _clients[i];
        final badge = _clientBadge(c);
        final isSelected = c.idClient == _selectedClientId;

        return Material(
          color: isSelected ? _accent.withValues(alpha: 0.12) : _card,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected
                  ? const BorderSide(color: _accent, width: 1.5)
                  : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              c.nomClient,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.emailClient.trim().isNotEmpty)
                    Text(
                      c.emailClient,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  if (c.telephone.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.telephone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if ((c.adresseClient ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.adresseClient!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: _accent,
                      size: 18,
                    ),
                  ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badge == 'Plateforme Rusa'
                          ? const Color(0xFF1A2A3A)
                          : _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: badge == 'Plateforme Rusa'
                            ? Colors.white24
                            : _accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badge == 'Plateforme Rusa'
                            ? Colors.white70
                            : _accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!c.isActif) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Inactif',
                    style: TextStyle(
                      color: Colors.orange.shade200,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              setState(() => _selectedClientId = c.idClient);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CaissierClientDetailsScreen(clientId: c.idClient),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
