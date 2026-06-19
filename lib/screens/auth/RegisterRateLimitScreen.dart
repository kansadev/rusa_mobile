import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de blocage temporaire après trop de tentatives d'inscription (HTTP 429).
class RegisterRateLimitScreen extends StatefulWidget {
  final int retryAfterSeconds;
  final String? message;

  const RegisterRateLimitScreen({
    super.key,
    required this.retryAfterSeconds,
    this.message,
  });

  @override
  State<RegisterRateLimitScreen> createState() => _RegisterRateLimitScreenState();
}

class _RegisterRateLimitScreenState extends State<RegisterRateLimitScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _accent = Color(0xFF00E676);
  static const Color _warning = Color(0xFFFFB74D);

  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.retryAfterSeconds > 0 ? widget.retryAfterSeconds : 600;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    if (_secondsLeft <= 1) {
      timer.cancel();
      setState(() => _secondsLeft = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    setState(() => _secondsLeft--);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = widget.retryAfterSeconds > 0 ? widget.retryAfterSeconds : 600;
    if (total <= 0) return 0;
    return 1 - (_secondsLeft / total);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.message?.trim().isNotEmpty == true
        ? widget.message!.trim()
        : 'Trop de tentatives. Veuillez réessayer plus tard.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _warning.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: _warning.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: _warning,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Inscription temporairement bloquée',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  info,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  _countdownLabel,
                  style: GoogleFonts.poppins(
                    color: _accent,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temps restant',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Retour automatique au formulaire d\'inscription à la fin du délai.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
