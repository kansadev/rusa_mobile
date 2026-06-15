import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/screens/caissier/CaissierAddClientScreen.dart';
import 'package:rusa/screens/caissier/CaissierClientDetailsScreen.dart';
import 'package:rusa/services/api_service.dart';

/// Liste des clients enregistrés (`/api/Client`) avec recherche locale.
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

  final TextEditingController _searchController = TextEditingController();

  List<Client> _all = [];
  List<Client> _visible = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final list = await ApiService.getAllClients();

    if (!mounted) return;

    if (list == null) {
      setState(() {
        _loading = false;
        _error =
            'Impossible de charger les clients. Vérifiez la connexion ou vos droits.';
        _all = [];
        _visible = [];
      });
      return;
    }

    list.sort((a, b) => b.idClient.compareTo(a.idClient));
    setState(() {
      _all = list;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _visible = List<Client>.from(_all));
      return;
    }
    setState(() {
      _visible = _all.where((c) {
        final nom = c.nomClient.toLowerCase();
        final mail = c.emailClient.toLowerCase();
        final tel = c.telephone.toLowerCase();
        final adr = (c.adresseClient ?? '').toLowerCase();
        return nom.contains(q) ||
            mail.contains(q) ||
            tel.contains(q) ||
            adr.contains(q);
      }).toList();
    });
  }

  Future<void> _openAddClient() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CaissierAddClientScreen()),
    );
    if (created == true && mounted) await _load();
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
          'Clients',
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
              onRefresh: _load,
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
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Text(
              _all.isEmpty
                  ? 'Aucun client pour le moment.'
                  : 'Aucun résultat pour cette recherche.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _visible[i];
        return Material(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
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
                  Text(
                    c.emailClient,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.telephone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
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
                if (!c.isActif)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Inactif',
                      style: TextStyle(
                        color: Colors.orange.shade200,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
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
