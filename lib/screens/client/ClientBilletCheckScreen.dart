import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rusa/models/billet_check_response.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/widgets/camera_scanner_shell.dart';

import 'BilletReaffectationScreen.dart';

class ClientBilletCheckScreen extends StatefulWidget {
  const ClientBilletCheckScreen({super.key});

  @override
  State<ClientBilletCheckScreen> createState() =>
      _ClientBilletCheckScreenState();
}

class _ClientBilletCheckScreenState extends State<ClientBilletCheckScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingScan = false;
  String? _lastCode;

  Future<void> _resetAndRestartScanner() async {
    _lastCode = null;
    _isHandlingScan = false;
    if (!mounted) return;
    await _controller.stop();
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetectBarcode(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (_lastCode == raw) return;

    _lastCode = raw;
    _isHandlingScan = true;

    await _controller.stop();

    final result = await ApiService.checkBillet(raw);
    if (!mounted) return;

    if (!result.success || result.data == null) {
      await _triggerInvalidFeedback();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Billet invalide'),
          content: Text(
            result.errorMessage ??
                'Billet invalide ou introuvable pour ce QR code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      await _resetAndRestartScanner();
      return;
    }

    await _showBilletStatus(result.data!);
    await _resetAndRestartScanner();
  }

  Future<void> _triggerInvalidFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.vibrate();
  }

  String _formatMoment(BilletCheckResponse r) {
    final m = r.momentDepart;
    if (m == null) return '-';
    final local = m.isUtc ? m.toLocal() : m;
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy à $hh:$min';
  }

  Future<void> _showBilletStatus(BilletCheckResponse data) async {
    final estUtilise = data.isUsed;
    final expire = data.estExpire;
    final autorise =
        data.embarquementAutorise && !data.voyageDejaPasse && !expire;
    final peutReaffecter = data.peutEtreReaffecte;
    final texteStatut = data.statutReservation ?? data.statut ?? '';
    final dateTexte = _formatMoment(data);

    // Style selon l'état.
    final _BilletStatusStyle style;
    if (estUtilise) {
      style = const _BilletStatusStyle(
        color: Colors.redAccent,
        icon: Icons.cancel_rounded,
        titre: 'Billet déjà utilisé',
        description: 'Ce billet a déjà été utilisé pour l’embarquement.',
      );
    } else if (expire) {
      style = const _BilletStatusStyle(
        color: Color(0xFFFFA726),
        icon: Icons.timer_off_rounded,
        titre: 'Billet expiré',
        description: 'La validité de ce billet est dépassée.',
      );
    } else if (autorise) {
      style = const _BilletStatusStyle(
        color: Color(0xFF00E676),
        icon: Icons.verified_rounded,
        titre: 'Billet valide',
        description: 'Ce billet est valide pour l’embarquement.',
      );
    } else {
      style = const _BilletStatusStyle(
        color: Color(0xFFFFA726),
        icon: Icons.info_rounded,
        titre: 'Billet non utilisable',
        description: 'Ce billet ne peut pas être utilisé pour l’instant.',
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.color, size: 40),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                style.titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (data.message != null && data.message!.trim().isNotEmpty)
                    ? data.message!.trim()
                    : style.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.confirmation_number_outlined,
                        'Billet', '#${data.idBillet}'),
                    if (dateTexte != '-') ...[
                      const SizedBox(height: 10),
                      _infoRow(Icons.event, 'Départ prévu', dateTexte),
                    ],
                    if (texteStatut.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _infoRow(Icons.flag_outlined, 'Réservation',
                          texteStatut),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (peutReaffecter) ...[
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(
                      'Réaffecter ce billet',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _ouvrirReaffectation(ctx, data),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _ouvrirReaffectation(
    BuildContext sheetContext,
    BilletCheckResponse data,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final idSociete = await ApiService.getCurrentSocieteId();
    if (!mounted) return;

    // Ferme le bottomsheet avant d'ouvrir l'écran de réaffectation.
    Navigator.pop(sheetContext);

    final result = await Navigator.push<ReaffectationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BilletReaffectationScreen(
          idBillet: data.idBillet,
          idSociete: idSociete,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null && result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vérifier mon billet',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF121212),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: CameraScannerShell(
              controller: _controller,
              onDetect: _onDetectBarcode,
              permissionRationale:
                  'Pour vérifier votre billet, RusaTravel a besoin d\'accéder à la '
                  'caméra afin de lire le QR code. Aucune photo n\'est enregistrée.',
              overlays: [
                IgnorePointer(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF29F58B),
                          width: 3,
                        ),
                        color: Colors.transparent,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300E676),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Place ton QR code de billet dans le cadre vert pour vérifier sa validité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Style visuel d'un état de billet dans le bottomsheet de vérification.
class _BilletStatusStyle {
  final Color color;
  final IconData icon;
  final String titre;
  final String description;

  const _BilletStatusStyle({
    required this.color,
    required this.icon,
    required this.titre,
    required this.description,
  });
}
