import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/services/api_service.dart';

/// Action renvoyée au [BilletQrScannerScreen] à la fermeture de cette page.
enum BilletScanResultExit {
  /// Revenir au scanner pour un autre QR.
  scanAnother,

  /// Quitter aussi l’écran scanner.
  finish,
}

// ——— Fenêtre d’embarquement (même règles qu’avant) ———

const Duration _kEmbarquementMaxAvantDepart = Duration(hours: 6);
const Duration _kEmbarquementMaxApresDepart = Duration(minutes: 45);

String _formatDateHeureCourt(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final y = d.year;
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$y à $hh:$min';
}

DateTime? _parseDepartPrevuePourEmbarquement(ReservationData r) {
  final raw = r.dateVoyage?.trim();
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final local = parsed.isUtc ? parsed.toLocal() : parsed;
  final hv = r.heureVoyage;
  if (hv != null && local.hour == 0 && local.minute == 0 && local.second == 0) {
    return DateTime(
      local.year,
      local.month,
      local.day,
      hv.hours,
      hv.minutes,
      hv.seconds,
    );
  }
  return local;
}

({bool autorise, String? message}) _evaluerFenetreEmbarquement(ReservationData r) {
  final depart = _parseDepartPrevuePourEmbarquement(r);
  if (depart == null) {
    return (autorise: true, message: null);
  }
  final now = DateTime.now();
  final debutFenetre = depart.subtract(_kEmbarquementMaxAvantDepart);
  final finFenetre = depart.add(_kEmbarquementMaxApresDepart);
  if (now.isBefore(debutFenetre)) {
    return (
      autorise: false,
      message:
          'Trop tôt pour embarquer ce passager. '
          'Ouverture à partir du ${_formatDateHeureCourt(debutFenetre)} '
          '(départ prévu ${_formatDateHeureCourt(depart)}).',
    );
  }
  if (now.isAfter(finFenetre)) {
    return (
      autorise: false,
      message:
          'Fenêtre d’embarquement dépassée pour ce trajet '
          '(le départ prévu était ${_formatDateHeureCourt(depart)}).',
    );
  }
  return (autorise: true, message: null);
}

/// Page plein écran après un scan QR réussi : détail billet + embarquement.
class BilletScanResultScreen extends StatefulWidget {
  const BilletScanResultScreen({super.key, required this.data});

  final ReservationWithPaiementResponse data;

  @override
  State<BilletScanResultScreen> createState() => _BilletScanResultScreenState();
}

class _BilletScanResultScreenState extends State<BilletScanResultScreen> {
  static const _bg = Color(0xFF0A0F0D);
  static const _surface = Color(0xFF141A18);
  static const _accent = Color(0xFF29F58B);
  static const _accentDim = Color(0xFF1A2820);

  late BilletData? _billetCourant;
  bool _embarquementLoading = false;
  bool _embarquementOk = false;
  String _embarquementErreur = '';

  @override
  void initState() {
    super.initState();
    _billetCourant = widget.data.billet;
  }

  Future<void> _onEmbarquer() async {
    final reservation = widget.data.reservation;
    final b = _billetCourant;
    final idSociete = (b?.idSociete ?? 0) > 0 ? b!.idSociete : reservation.idSociete;
    final idPassager = b?.idReservationPassenger ?? 0;
    final idBillet = b?.id ?? 0;

    setState(() {
      _embarquementLoading = true;
      _embarquementErreur = '';
    });
    final result = await ApiService.embarquerPassagerBillet(
      idSociete: idSociete,
      idReservationPassenger: idPassager,
      idBillet: idBillet,
    );
    if (!mounted) return;

    setState(() {
      _embarquementLoading = false;
      if (result.success) {
        _embarquementOk = true;
        if (result.billet != null) {
          _billetCourant = result.billet;
        } else {
          final prev = _billetCourant;
          if (prev != null) {
            _billetCourant = BilletData(
              id: prev.id,
              qrCode: prev.qrCode,
              dateGeneration: prev.dateGeneration,
              idReservation: prev.idReservation,
              idClient: prev.idClient,
              idSociete: prev.idSociete,
              urlBillet: prev.urlBillet,
              idReservationPassenger: prev.idReservationPassenger,
              isUsed: true,
            );
          }
        }
      } else {
        _embarquementErreur = result.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final reservation = data.reservation;
    final paiement = data.paiement;
    final trajet =
        '${reservation.villeDepart ?? '—'} → ${reservation.villeArrivee ?? '—'}';

    final b = _billetCourant;
    final idSociete = (b?.idSociete ?? 0) > 0 ? b!.idSociete : reservation.idSociete;
    final idPassager = b?.idReservationPassenger ?? 0;
    final idBillet = b?.id ?? 0;
    final dejaUtilise = b?.isUsed == true;
    final fenetreEmb = _evaluerFenetreEmbarquement(reservation);
    final peutEmbarquer =
        b != null &&
        !dejaUtilise &&
        !_embarquementOk &&
        idSociete > 0 &&
        idPassager > 0 &&
        idBillet > 0 &&
        fenetreEmb.autorise;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () =>
              Navigator.pop(context, BilletScanResultExit.scanAnother),
        ),
        title: Text(
          'Contrôle billet',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildHeaderBadge(dejaUtilise: dejaUtilise, okEmbarque: _embarquementOk),
                const SizedBox(height: 20),
                _SectionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Passager',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine('Nom', reservation.nomClient ?? '—'),
                      _infoLine('Téléphone', reservation.telephoneClient ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.route_rounded,
                  title: 'Trajet',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trajet,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoLine('Date voyage', reservation.dateVoyage ?? '—'),
                      _infoLine('Bus', reservation.numeroBus ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.payments_outlined,
                  title: 'Paiement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine(
                        'Montant payé',
                        '${paiement.montantPaye.toStringAsFixed(2)} FC',
                      ),
                      _infoLine(
                        'Statut réservation',
                        reservation.statutReservation.isEmpty
                            ? '—'
                            : reservation.statutReservation,
                      ),
                    ],
                  ),
                ),
                if (b != null) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Billet',
                    child: Text(
                      'N° $idBillet${dejaUtilise ? ' — déjà utilisé' : ''}',
                      style: GoogleFonts.poppins(
                        color: dejaUtilise ? Colors.orangeAccent : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildAlerts(
                  b: b,
                  idPassager: idPassager,
                  fenetreEmb: fenetreEmb,
                  embarquementOk: _embarquementOk,
                  embarquementErreur: _embarquementErreur,
                ),
              ],
            ),
          ),
          _buildFooter(
            context: context,
            peutEmbarquer: peutEmbarquer,
            embarquementLoading: _embarquementLoading,
            onEmbarquer: _onEmbarquer,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({required bool dejaUtilise, required bool okEmbarque}) {
    final Color ring;
    final IconData icon;
    final String title;
    final String subtitle;
    if (okEmbarque) {
      ring = _accent;
      icon = Icons.check_rounded;
      title = 'Embarquement enregistré';
      subtitle = 'Le passager a été marqué comme embarqué.';
    } else if (dejaUtilise) {
      ring = Colors.orangeAccent;
      icon = Icons.history_rounded;
      title = 'Billet déjà utilisé';
      subtitle = 'Ce billet a déjà été scanné pour embarquement.';
    } else {
      ring = _accent;
      icon = Icons.verified_rounded;
      title = 'Billet valide';
      subtitle = 'Les informations ci-dessous correspondent au QR scanné.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _accentDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ring.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring.withValues(alpha: 0.15),
              border: Border.all(color: ring.withValues(alpha: 0.7), width: 2),
            ),
            child: Icon(icon, color: ring, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts({
    required BilletData? b,
    required int idPassager,
    required ({bool autorise, String? message}) fenetreEmb,
    required bool embarquementOk,
    required String embarquementErreur,
  }) {
    final widgets = <Widget>[];

    if (b == null) {
      widgets.add(
        _AlertBanner(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          text:
              'Détail billet absent : embarquement impossible depuis cet écran.',
        ),
      );
    } else if (idPassager <= 0) {
      widgets.add(
        _AlertBanner(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          text:
              'Identifiant passager absent : l’API doit renvoyer idReservationPassenger sur le billet.',
        ),
      );
    } else if (!fenetreEmb.autorise && fenetreEmb.message != null) {
      widgets.add(
        _AlertBanner(
          icon: Icons.schedule_rounded,
          color: Colors.orangeAccent,
          text: fenetreEmb.message!,
        ),
      );
    }

    if (embarquementOk) {
      widgets.add(
        _AlertBanner(
          icon: Icons.check_circle_rounded,
          color: _accent,
          text: 'Passager marqué comme embarqué.',
        ),
      );
    }

    if (embarquementErreur.isNotEmpty && !embarquementOk) {
      widgets.add(
        _AlertBanner(
          icon: Icons.error_outline_rounded,
          color: Colors.redAccent,
          text: embarquementErreur,
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          widgets[i],
        ],
      ],
    );
  }

  Widget _buildFooter({
    required BuildContext context,
    required bool peutEmbarquer,
    required bool embarquementLoading,
    required VoidCallback onEmbarquer,
  }) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: _surface,
      elevation: 12,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (peutEmbarquer)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: embarquementLoading ? null : onEmbarquer,
                icon: embarquementLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black87,
                        ),
                      )
                    : const Icon(Icons.directions_bus_filled_rounded),
                label: Text(
                  embarquementLoading ? 'Enregistrement…' : 'Marquer comme embarqué',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            if (peutEmbarquer) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, BilletScanResultExit.scanAnother),
                    child: Text(
                      'Scanner un autre',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, BilletScanResultExit.finish),
                    child: Text(
                      'Terminer',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.87),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BilletScanResultScreenState._surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _BilletScanResultScreenState._accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
