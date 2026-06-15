import 'package:flutter/material.dart';

/// Salutation contextuelle selon l'heure locale (texte + emoji).
class TimeBasedGreeting extends StatelessWidget {
  final TextStyle? style;
  final DateTime? now;

  const TimeBasedGreeting({super.key, this.style, this.now});

  static TimeGreeting resolve([DateTime? reference]) {
    final hour = (reference ?? DateTime.now()).hour;

    if (hour >= 5 && hour < 12) {
      return const TimeGreeting(text: 'Bonjour', emoji: '☀️');
    }
    if (hour >= 12 && hour < 14) {
      return const TimeGreeting(text: 'Bon midi', emoji: '🍽️');
    }
    if (hour >= 14 && hour < 18) {
      return const TimeGreeting(text: 'Bon après-midi', emoji: '🌤️');
    }
    if (hour >= 18 && hour < 22) {
      return const TimeGreeting(text: 'Bonsoir', emoji: '🌆');
    }
    return const TimeGreeting(text: 'Bonne nuit', emoji: '🌙');
  }

  @override
  Widget build(BuildContext context) {
    final greeting = resolve(now);
    final effectiveStyle =
        style ?? const TextStyle(color: Color(0xFF093120), fontSize: 13);

    return Text(
      '${greeting.text} ${greeting.emoji}',
      style: effectiveStyle,
    );
  }
}

class TimeGreeting {
  final String text;
  final String emoji;

  const TimeGreeting({required this.text, required this.emoji});

  String get full => '$text $emoji';
}
