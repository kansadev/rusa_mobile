import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/screens/payment/electronic_payment_fees_help_screen.dart';

/// Ouvre la page d'aide sur les frais de paiement électronique.
void openElectronicPaymentFeesHelp(
  BuildContext context, {
  Voyage? voyage,
  bool isCaissier = false,
}) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ElectronicPaymentFeesHelpScreen(
        voyage: voyage,
        isCaissier: isCaissier,
      ),
    ),
  );
}

/// Lien « En savoir plus » vers la page d'aide (texte optionnel en préfixe).
class PaymentFeesLearnMoreText extends StatefulWidget {
  final String? prefix;
  final Voyage? voyage;
  final bool isCaissier;
  final double fontSize;
  final TextAlign textAlign;

  const PaymentFeesLearnMoreText({
    super.key,
    this.prefix,
    this.voyage,
    this.isCaissier = false,
    this.fontSize = 11,
    this.textAlign = TextAlign.start,
  });

  @override
  State<PaymentFeesLearnMoreText> createState() =>
      _PaymentFeesLearnMoreTextState();
}

class _PaymentFeesLearnMoreTextState extends State<PaymentFeesLearnMoreText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()
      ..onTap = _openHelp;
  }

  void _openHelp() {
    openElectronicPaymentFeesHelp(
      context,
      voyage: widget.voyage,
      isCaissier: widget.isCaissier,
    );
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.prefix?.trim();
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: widget.fontSize,
          height: 1.35,
        ),
        children: [
          if (prefix != null && prefix.isNotEmpty) TextSpan(text: '$prefix '),
          TextSpan(
            text: 'En savoir plus',
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontWeight: FontWeight.w600,
            ),
            recognizer: _recognizer,
          ),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
