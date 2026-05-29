import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/screens/caissier/CaissierAddClientScreen.dart';

/// Feuille de recherche / sélection d'un client (flux caissier).
class CaissierClientPickerSheet extends StatefulWidget {
  const CaissierClientPickerSheet({
    super.key,
    required this.clients,
    this.loadError,
    this.onRetry,
  });

  final List<Client> clients;
  final String? loadError;
  final VoidCallback? onRetry;

  @override
  State<CaissierClientPickerSheet> createState() =>
      _CaissierClientPickerSheetState();
}

class _CaissierClientPickerSheetState extends State<CaissierClientPickerSheet> {
  static const _accent = Color(0xFF29F58B);

  final _searchController = TextEditingController();
  List<Client> _visible = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _visible = List<Client>.from(widget.clients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visible = List<Client>.from(widget.clients);
        return;
      }
      _visible = widget.clients.where((c) {
        return c.nomClient.toLowerCase().contains(q) ||
            c.emailClient.toLowerCase().contains(q) ||
            c.telephone.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _openCreateClient() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (context) => const CaissierAddClientScreen()),
    );
    if (!mounted) return;
    if (result is Client) {
      Navigator.pop(context, result);
    } else if (result == true) {
      widget.onRetry?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141A18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choisir un client',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom, e-mail, téléphone…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: const Color(0xFF1E2622),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.loadError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                  if (widget.onRetry != null)
                    TextButton(
                      onPressed: widget.onRetry,
                      child: const Text('Réessayer'),
                    ),
                ],
              ),
            ),
          Flexible(
            child: _visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.clients.isEmpty
                            ? 'Aucun client. Créez-en un nouveau.'
                            : 'Aucun résultat pour cette recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
                    itemCount: _visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final c = _visible[i];
                      return Material(
                        color: const Color(0xFF1E2622),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          title: Text(
                            c.nomClient,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${c.telephone}\n${c.emailClient}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => Navigator.pop(context, c),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openCreateClient,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Créer un nouveau client'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
