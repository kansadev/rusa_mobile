import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/utils/voyage_periode_filter.dart';
import 'package:rusa/widgets/truncated_text.dart';

/// Écran de réaffectation d'un billet expiré (jamais utilisé) vers un autre
/// voyage. L'utilisateur choisit un voyage cible à venir, puis confirme.
class BilletReaffectationScreen extends StatefulWidget {
  final int idBillet;
  final int idSociete;

  const BilletReaffectationScreen({
    super.key,
    required this.idBillet,
    required this.idSociete,
  });

  @override
  State<BilletReaffectationScreen> createState() =>
      _BilletReaffectationScreenState();
}

class _BilletReaffectationScreenState extends State<BilletReaffectationScreen> {
  static const Color _accent = Color(0xFF00E676);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  List<Voyage> _voyages = [];
  int? _selectedVoyageId;
  bool _confirmerPaiementDifferentiel = true;

  @override
  void initState() {
    super.initState();
    _loadVoyages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadVoyages({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getVoyagesPaged(
      pageNumber: 1,
      pageSize: 100,
      periode: VoyagePeriode.mensuel.apiValue,
      searchTerm: search,
      sortBy: 'dateDepart',
    );

    if (!mounted) return;

    if (response == null) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les voyages disponibles.';
      });
      return;
    }

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final futurs = response.data.where((v) {
      final dep = VoyagePeriodeFilter.parseDateDepartCalendaire(v.dateDepart);
      return dep != null && !dep.isBefore(dayStart);
    }).toList()..sort((a, b) => a.dateDepart.compareTo(b.dateDepart));

    setState(() {
      _isLoading = false;
      _voyages = futurs;
      if (_selectedVoyageId != null &&
          !futurs.any((v) => v.id == _selectedVoyageId)) {
        _selectedVoyageId = null;
      }
    });
  }

  String _formatDate(String raw) {
    final d = VoyagePeriodeFilter.parseDateDepartCalendaire(raw);
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmer() async {
    final id = _selectedVoyageId;
    if (id == null) return;

    setState(() => _isSubmitting = true);
    final result = await ApiService.reaffecterBillet(
      idSociete: widget.idSociete,
      idBillet: widget.idBillet,
      idVoyageCible: id,
      confirmerPaiementDifferentiel: _confirmerPaiementDifferentiel,
      commentaire: _commentController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPaiementDifferentielInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: _accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paiement différentiel',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoParagraphe(
                Icons.swap_horiz_rounded,
                'Qu’est-ce que c’est ?',
                'Lorsque vous reportez votre billet vers un autre voyage, le '
                    'tarif peut être différent de celui d’origine.',
              ),
              const SizedBox(height: 14),
              _infoParagraphe(
                Icons.trending_up_rounded,
                'Si le nouveau voyage est plus cher',
                'Vous payez uniquement la différence de prix entre l’ancien et '
                    'le nouveau billet.',
              ),
              const SizedBox(height: 14),
              _infoParagraphe(
                Icons.toggle_on_outlined,
                'En activant cette option',
                'Vous autorisez le règlement automatique de cette différence '
                    'pour finaliser le report. Si elle est désactivée et qu’un '
                    'complément est dû, le report peut être refusé.',
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('J’ai compris'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoParagraphe(IconData icon, String titre, String texte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                texte,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF121212),
        centerTitle: true,
        title: Text(
          'Reporter un voyage',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _loadVoyages(search: v),
              decoration: InputDecoration(
                hintText: 'Rechercher un voyage (ville, date...)',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildList()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _loadVoyages(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_voyages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun voyage à venir disponible pour la réaffectation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _voyages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = _voyages[index];
        final selected = v.id == _selectedVoyageId;
        final complet = v.placesDisponiblesTotal <= 0;
        return GestureDetector(
          onTap: complet
              ? null
              : () => setState(() => _selectedVoyageId = v.id),
          child: Opacity(
            opacity: complet ? 0.45 : 1,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? _accent.withValues(alpha: 0.12)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? _accent : Colors.white12,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TruncatedText(
                          v.villeDepart,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          color: _accent,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TruncatedText(
                          v.villeArrivee,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: _accent,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(v.dateDepart),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        v.heure,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${v.prix.toStringAsFixed(0)} ${v.codeDevisePrix ?? 'FC'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat_rounded,
                        size: 14,
                        color: complet ? Colors.redAccent : _accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        complet
                            ? 'Complet'
                            : '${v.placesDisponiblesTotal} place(s)',
                        style: TextStyle(
                          color: complet ? Colors.redAccent : Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final canSubmit = _selectedVoyageId != null && !_isSubmitting;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141A18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Commentaire (recommandé)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: _accent,
            value: _confirmerPaiementDifferentiel,
            onChanged: (v) =>
                setState(() => _confirmerPaiementDifferentiel = v),
            title: const Text(
              'Confirmer le paiement différentiel',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                children: [
                  const TextSpan(
                    text:
                        'Accepter de payer l’éventuelle différence de tarif. ',
                  ),
                  TextSpan(
                    text: 'En savoir plus',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _showPaiementDifferentielInfo,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: canSubmit ? _confirmer : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Confirmer la réaffectation',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
