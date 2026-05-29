import 'package:flutter/material.dart';

/// Texte tronqué : au-delà de [maxLength] caractères, on coupe et on ajoute
/// le suffixe [ellipsis] (un point « . » par défaut).
///
/// Exemple : « Kasumbalesa » (11) → « Kasumbales. » avec maxLength = 10.
class TruncatedText extends StatelessWidget {
  final String text;
  final int maxLength;
  final String ellipsis;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TruncatedText(
    this.text, {
    super.key,
    this.maxLength = 10,
    this.ellipsis = '.',
    this.style,
    this.textAlign,
  });

  /// Tronque [value] à [maxLength] caractères, en ajoutant [ellipsisSuffix].
  static String truncate(
    String value, {
    int maxLength = 10,
    String ellipsisSuffix = '.',
  }) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}$ellipsisSuffix';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      truncate(text, maxLength: maxLength, ellipsisSuffix: ellipsis),
      style: style,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
