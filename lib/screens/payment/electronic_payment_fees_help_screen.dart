import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';

/// Page d'aide : frais liés au paiement électronique (client et caissier).
class ElectronicPaymentFeesHelpScreen extends StatelessWidget {
  final Voyage? voyage;
  final bool isCaissier;

  const ElectronicPaymentFeesHelpScreen({
    super.key,
    this.voyage,
    this.isCaissier = false,
  });

  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1E1E1E);
  static const Color _accent = Color(0xFF00E676);
  static const Color _accentBlue = Color(0xFF64B5F6);
  static const Color _accentOrange = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'Paiement électronique',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildIntroBanner(),
          if (voyage != null) ...[
            const SizedBox(height: 16),
            _buildVoyageContextCard(voyage!),
          ],
          const SizedBox(height: 20),
          _buildSectionCard(
            icon: Icons.route_outlined,
            iconColor: _accent,
            title: 'Où voyez-vous ces frais ?',
            children: [
              _paragraph(
                'Rusa affiche les frais plateforme dès la liste des voyages, sur la '
                'fiche du trajet, puis dans le récapitulatif avant paiement. Le '
                'total affiché inclut déjà ces frais par passager lorsque vous '
                'choisissez Mobile Money ou carte bancaire.',
              ),
              const SizedBox(height: 10),
              _bullet('Liste des voyages et accueil : bandeau bleu informatif.'),
              _bullet(
                'Réservation / vente : ligne « Frais plateforme Rusa Travel ».',
              ),
              _bullet(
                'Reçu : détail billets + frais plateforme si paiement électronique.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.people_outline_rounded,
            iconColor: _accent,
            title: 'Qui est concerné ?',
            children: [
              _paragraph(
                isCaissier
                    ? 'Lorsque vous vendez un billet avec Mobile Money ou carte '
                        'bancaire, les frais plateforme Rusa Travel du voyage '
                        'peuvent s\'appliquer.'
                    : 'Lorsque vous payez par Mobile Money ou carte bancaire, '
                        'les frais plateforme Rusa Travel du voyage peuvent '
                        's\'appliquer.',
              ),
              const SizedBox(height: 10),
              _paragraph(
                'Le paiement en espèces (cash, caissier uniquement) ne déclenche '
                'ni frais plateforme Rusa Travel ni frais de transaction FlexPay.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.receipt_long_outlined,
            iconColor: _accentOrange,
            title: 'Frais plateforme Rusa Travel (par passager)',
            children: [
              _paragraph(
                'Chaque voyage peut prévoir un montant fixe par passager, '
                'configuré pour la plateforme Rusa Travel. Ce supplément '
                's\'ajoute au prix des billets en cas de paiement électronique '
                '(Mobile Money, carte bancaire…).',
              ),
              const SizedBox(height: 12),
              _buildPlatformFeeBox(voyage),
              const SizedBox(height: 10),
              _bullet(
                'Formule : montant unitaire du voyage × nombre de passagers.',
              ),
              _bullet(
                'Ce montant est ajouté au prix des billets dans le total affiché '
                'par l\'application.',
              ),
              _bullet(
                'La devise des frais peut différer de celle du billet ; l\'app '
                'utilise la devise indiquée pour ce voyage.',
              ),
              _bullet(
                'Aucun frais plateforme si vous payez en espèces.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.timeline_outlined,
            iconColor: _accent,
            title: 'Étapes du calcul (dans l\'app)',
            children: [
              _stepRow(
                '1',
                'Prix des billets',
                'Somme des tarifs selon la catégorie de siège de chaque passager.',
              ),
              _stepRow(
                '2',
                'Frais plateforme Rusa Travel',
                voyage != null && voyage!.hasMajorationPaieElectronique
                    ? '+ ${voyage!.libelleFraisPaieElectroniqueUnitaire} '
                        '× nombre de passagers (si Mobile Money ou carte).'
                    : '+ frais plateforme du voyage × passagers (si applicable '
                        'et paiement électronique).',
              ),
              _stepRow(
                '3',
                'Total affiché',
                'Billets + frais plateforme = montant envoyé à la réservation.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: _accentBlue,
            title: 'Frais de transaction (~2,5 %)',
            children: [
              _paragraph(
                'En plus du total affiché dans l\'app, FlexPay peut prélever '
                'environ 2,5 % de frais de transaction au moment du débit '
                'Mobile Money ou carte. Ce montant n\'est pas inclus dans le '
                'total calculé par Rusa Travel.',
              ),
              const SizedBox(height: 10),
              _bullet('Prélevés par FlexPay lors du paiement électronique.'),
              _bullet('Non inclus dans le total affiché par l\'application.'),
              _bullet(
                'Le montant réellement débité sur le téléphone ou la carte peut '
                'donc être légèrement supérieur au total affiché.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildExampleSection(voyage),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.payments_outlined,
            iconColor: Colors.white70,
            title: 'Paiement en espèces',
            children: [
              _paragraph(
                'Réservé au caissier. Vous payez uniquement le montant des billets : '
                'pas de frais plateforme Rusa Travel, pas de frais de transaction.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.help_outline_rounded,
            iconColor: _accentBlue,
            title: 'En résumé',
            children: [
              _paragraph(
                '• Espèces : prix des billets uniquement.\n'
                '• Mobile Money / Carte : billets + frais plateforme Rusa Travel '
                '(si définis), puis éventuellement ~2,5 % de frais de transaction '
                'au débit.\n'
                '• Le montant exact des frais plateforme est indiqué sur chaque '
                'trajet et repris dans le récapitulatif avant validation.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.18),
            _accentBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Comprendre les frais',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Deux types de frais peuvent s\'appliquer au paiement électronique : '
            'les frais plateforme Rusa Travel par passager (visibles dans l\'app) '
            'et les frais de transaction (~2,5 %, au moment du débit FlexPay). '
            'Ce guide détaille les deux.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoyageContextCard(Voyage v) {
    final route = '${v.villeDepart} → ${v.villeArrivee}';
    final hasFee = v.hasMajorationPaieElectronique;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentBlue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voyage concerné',
            style: GoogleFonts.poppins(
              color: _accentBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            route,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (v.dateDepart.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Départ : ${v.date} à ${v.heure}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (hasFee)
            _highlightBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frais plateforme Rusa Travel sur ce trajet',
                    style: GoogleFonts.poppins(
                      color: _accentOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${v.libelleFraisPaieElectroniqueUnitaire}\n'
                    'Ajoutée au total pour chaque passager en Mobile Money ou carte.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Ce voyage n\'a pas de frais plateforme Rusa Travel par passager. '
                'Seuls les frais de transaction (~2,5 %) peuvent s\'appliquer '
                'lors d\'un paiement Mobile Money ou carte.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformFeeBox(Voyage? voyageInfo) {
    if (voyageInfo != null && voyageInfo.hasMajorationPaieElectronique) {
      return _highlightBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant enregistré pour ce voyage',
              style: GoogleFonts.poppins(
                color: _accentOrange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${voyageInfo.montAddPaieElectronique.toStringAsFixed(0)} '
              '${voyageInfo.deviseMajorationPaieElectronique} par passager',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Exemple : 2 passagers → +'
              '${voyageInfo.majorationPaieElectroniquePour(2).toStringAsFixed(0)} '
              '${voyageInfo.deviseMajorationPaieElectronique} ajoutés au total.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        'Le montant par passager varie selon le voyage. Consultez le bandeau '
        '« Frais plateforme Rusa Travel » sur la fiche du trajet ou le '
        'récapitulatif de réservation.',
        style: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildExampleSection(Voyage? v) {
    final unitFee = v != null && v.hasMajorationPaieElectronique
        ? v.montAddPaieElectronique
        : 500.0;
    final deviseFee = v?.deviseMajorationPaieElectronique ?? 'FC';
    final passagers = 2;
    final billets = 20000.0;
    final majoration = unitFee * passagers;
    final totalApp = billets + majoration;
    final gateway = totalApp * 0.025;

    return _buildSectionCard(
      icon: Icons.calculate_outlined,
      iconColor: _accent,
      title: 'Exemple concret',
      children: [
        _paragraph(
          v != null && v.hasMajorationPaieElectronique
              ? 'Calcul pour ce voyage ($passagers passagers, Mobile Money) :'
              : 'Calcul type ($passagers passagers, frais plateforme '
                  '${unitFee.toStringAsFixed(0)} $deviseFee/passager, Mobile Money) :',
        ),
        const SizedBox(height: 10),
        _exampleLine('Prix des billets', '${billets.toStringAsFixed(0)} $deviseFee'),
        _exampleLine(
          'Frais plateforme Rusa Travel ($passagers × ${unitFee.toStringAsFixed(0)})',
          '+ ${majoration.toStringAsFixed(0)} $deviseFee',
        ),
        _exampleLine(
          'Total affiché dans l\'app',
          '= ${totalApp.toStringAsFixed(0)} $deviseFee',
          bold: true,
        ),
        const SizedBox(height: 8),
        _exampleLine(
          'Frais de transaction (~2,5 %)',
          '≈ ${gateway.toStringAsFixed(0)} $deviseFee (hors app)',
          muted: true,
        ),
        const SizedBox(height: 8),
        _paragraph(
          'Vous validez ${totalApp.toStringAsFixed(0)} $deviseFee dans Rusa ; '
          'le débit Mobile Money peut atteindre environ '
          '${(totalApp + gateway).toStringAsFixed(0)} $deviseFee.',
          muted: true,
        ),
      ],
    );
  }

  Widget _stepRow(String number, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: _accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _paragraph(String text, {bool muted = false}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: muted
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.82),
        fontSize: 13,
        height: 1.45,
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _paragraph(text)),
        ],
      ),
    );
  }

  Widget _highlightBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentOrange.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _exampleLine(
    String label,
    String value, {
    bool bold = false,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: muted
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: muted
                  ? _accentBlue.withValues(alpha: 0.85)
                  : (bold ? _accent : Colors.white),
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
