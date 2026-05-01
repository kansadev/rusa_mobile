import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientContactsScreen extends StatefulWidget {
  const ClientContactsScreen({super.key});

  @override
  State<ClientContactsScreen> createState() => _ClientContactsScreenState();
}

class _ClientContactsScreenState extends State<ClientContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _visibleContacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    PermissionStatus permission;
    try {
      permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Plugin contacts indisponible. Fermez totalement l\'app et relancez-la.';
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de demander la permission contacts.';
      });
      return;
    }
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.limited) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Permission refusée. Autorisez l\'accès aux contacts dans les paramètres.';
      });
      return;
    }

    try {
      final list = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      list.sort(
        (a, b) =>
            (a.displayName ?? '').toLowerCase().compareTo(
              (b.displayName ?? '').toLowerCase(),
            ),
      );
      if (!mounted) return;
      setState(() {
        _contacts = list;
        _visibleContacts = List<Contact>.from(list);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les contacts.';
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _visibleContacts = List<Contact>.from(_contacts));
      return;
    }
    setState(() {
      _visibleContacts = _contacts.where((c) {
        final name = (c.displayName ?? '').toLowerCase();
        final phones = c.phones.map((p) => p.number.toLowerCase()).join(' ');
        return name.contains(q) || phones.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Mes contacts',
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: const Color(0xFF222222),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contact_page_outlined, color: Colors.white38, size: 46),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visibleContacts.isEmpty) {
      return Center(
        child: Text(
          'Aucun contact trouvé.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: const Color(0xFF00E676),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _visibleContacts.length,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = _visibleContacts[index];
          final phone = c.phones.isNotEmpty ? c.phones.first.number : '-';
          final displayName = (c.displayName ?? '').trim();
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00E676),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              title: Text(
                displayName.isNotEmpty ? displayName : 'Sans nom',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                phone,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          );
        },
      ),
    );
  }
}
