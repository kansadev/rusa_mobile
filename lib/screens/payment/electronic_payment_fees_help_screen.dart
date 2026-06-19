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
    final voyageInfo = voyage;

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
          'Frais de paiement',
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
          const SizedBox(height: 20),
          _buildSectionCard(
            icon: Icons.people_outline_rounded,
            iconColor: _accent,
            title: 'Qui est concerné ?',
            children: [
              _paragraph(
                isCaissier
                    ? 'Ces règles s\'appliquent lorsque vous vendez un billet '
                        'avec un paiement électronique (Mobile Money ou carte bancaire).'
                    : 'Ces règles s\'appliquent lorsque vous payez votre billet '
                        'par Mobile Money ou carte bancaire.',
              ),
              const SizedBox(height: 10),
              _paragraph(
                'Les mêmes principes valent pour les clients et pour les caissiers '
                'dès qu\'un paiement électronique est utilisé. Le paiement en espèces '
                '(cash) n\'entraîne ni frais de transaction ni frais passerelle.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.receipt_long_outlined,
            iconColor: _accentOrange,
            title: 'Frais de transaction (par passager)',
            children: [
              _paragraph(
                'Pour certains voyages, une majoration fixe par passager peut '
                's\'appliquer lors d\'un paiement électronique. Elle correspond aux '
                'frais de transaction liés au billet.',
              ),
              if (voyageInfo != null &&
                  voyageInfo.hasMajorationPaieElectronique) ...[
                const SizedBox(height: 12),
                _highlightBox(
                  child: Text(
                    'Sur ce voyage : '
                    '${voyageInfo.montAddPaieElectronique.toStringAsFixed(0)} '
                    '${voyageInfo.deviseMajorationPaieElectronique} '
                    'par passager.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _bullet('Calcul : montant unitaire × nombre de passagers.'),
              _bullet('Inclus dans le total affiché par l\'application.'),
              _bullet('Non appliqué en cas de paiement en espèces.'),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: _accentBlue,
            title: 'Frais passerelle (~2,5 %)',
            children: [
              _paragraph(
                'La passerelle de paiement (FlexPay) peut majorer d\'environ 2,5 % '
                'le montant total à payer. Cette majoration porte sur le total du '
                'billet — et non sur chaque passager individuellement.',
              ),
              const SizedBox(height: 10),
              _bullet(
                'Appliqué par la passerelle au moment du paiement, pas par Rusa.',
              ),
              _bullet(
                'Non calculé ni affiché dans le total de l\'application.',
              ),
              _bullet(
                'Le montant réellement débité peut donc être légèrement supérieur '
                'au total affiché.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.calculate_outlined,
            iconColor: _accent,
            title: 'Exemple',
            children: [
              _paragraph(
                'Billets : 20 000 FC · 2 passagers · majoration 500 FC/passager '
                '(si applicable) · paiement Mobile Money.',
              ),
              const SizedBox(height: 10),
              _exampleLine('Billets', '20 000 FC'),
              _exampleLine('Frais de transaction (2 × 500)', '+ 1 000 FC'),
              _exampleLine('Total affiché dans l\'app', '= 21 000 FC', bold: true),
              const SizedBox(height: 8),
              _exampleLine(
                'Frais passerelle (~2,5 % sur 21 000)',
                '≈ 525 FC (hors app)',
                muted: true,
              ),
              const SizedBox(height: 8),
              _paragraph(
                'Le client ou le caissier paiera environ 21 525 FC via la '
                'passerelle, alors que l\'application affiche 21 000 FC.',
                muted: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.payments_outlined,
            iconColor: Colors.white70,
            title: 'Paiement en espèces',
            children: [
              _paragraph(
                'Réservé au caissier. Aucune majoration électronique ni frais '
                'passerelle ne s\'applique : seul le montant des billets est dû.',
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
              Icon(Icons.info_outline_rounded, color: _accent, size: 22),
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
            'L\'application affiche le total du billet. La passerelle peut ensuite '
            'ajouter ses propres frais au moment du paiement électronique.',
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
