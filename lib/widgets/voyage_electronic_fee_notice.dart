import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/widgets/payment_fee_notice.dart';

/// Affiche les frais plateforme `montAddPaieElectronique` d'un voyage (listes, détail).
class VoyageElectronicFeeNotice extends StatelessWidget {
  final Voyage voyage;
  final bool compact;
  final bool showLearnMore;
  final bool isCaissier;

  const VoyageElectronicFeeNotice({
    super.key,
    required this.voyage,
    this.compact = true,
    this.showLearnMore = true,
    this.isCaissier = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!voyage.hasMajorationPaieElectronique) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.contactless_rounded,
              color: Color(0xFF64B5F6),
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frais plateforme Rusa Travel',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${voyage.libelleFraisPaieElectroniqueUnitaire} '
                    'en Mobile Money ou carte — inclus dans le total affiché.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                  if (showLearnMore) ...[
                    const SizedBox(height: 4),
                    PaymentFeesLearnMoreText(
                      prefix: 'Comment ce montant est calculé ?',
                      voyage: voyage,
                      isCaissier: isCaissier,
                      fontSize: 10,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Color(0xFF64B5F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Frais plateforme Rusa Travel',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'En cas de règlement par Mobile Money ou carte bancaire, '
            '${voyage.libelleFraisPaieElectroniqueUnitaire} '
            's\'ajoute au prix des billets pour chaque passager. '
            'Ce montant est déjà inclus dans le total avant validation.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (showLearnMore) ...[
            const SizedBox(height: 6),
            PaymentFeesLearnMoreText(
              prefix: 'Voir le détail des frais et un exemple de calcul',
              voyage: voyage,
              isCaissier: isCaissier,
            ),
          ],
        ],
      ),
    );
  }
}
