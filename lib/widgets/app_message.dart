import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppMessageType { success, error, warning, info }

/// Carte / bandeau de message réutilisable (erreur API, succès, avertissement).
class AppMessage extends StatelessWidget {
  final String message;
  final AppMessageType type;
  final String? title;
  final bool compact;
  final Widget? trailing;

  const AppMessage({
    super.key,
    required this.message,
    this.type = AppMessageType.info,
    this.title,
    this.compact = false,
    this.trailing,
  });

  Color get _accentColor => switch (type) {
        AppMessageType.success => const Color(0xFF00E676),
        AppMessageType.error => const Color(0xFFFF5252),
        AppMessageType.warning => const Color(0xFFFFB74D),
        AppMessageType.info => const Color(0xFF64B5F6),
      };

  IconData get _icon => switch (type) {
        AppMessageType.success => Icons.check_circle_outline_rounded,
        AppMessageType.error => Icons.error_outline_rounded,
        AppMessageType.warning => Icons.warning_amber_rounded,
        AppMessageType.info => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(16);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: _accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accentColor, size: compact ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: compact ? 12.5 : 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// État plein écran centré (écran d'attente, erreur, succès).
class AppMessageState extends StatelessWidget {
  final AppMessageType type;
  final String message;
  final String? title;
  final List<Widget>? actions;
  final Widget? top;

  const AppMessageState({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.actions,
    this.top,
  });

  Color get _accentColor => switch (type) {
        AppMessageType.success => const Color(0xFF00E676),
        AppMessageType.error => const Color(0xFFFF5252),
        AppMessageType.warning => const Color(0xFFFFB74D),
        AppMessageType.info => const Color(0xFF64B5F6),
      };

  IconData get _icon => switch (type) {
        AppMessageType.success => Icons.check_circle_rounded,
        AppMessageType.error => Icons.error_outline_rounded,
        AppMessageType.warning => Icons.warning_amber_rounded,
        AppMessageType.info => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (top != null) ...[top!, const SizedBox(height: 20)],
        Icon(_icon, color: _accentColor, size: 52),
        if (title != null && title!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...actions!,
        ],
      ],
    );
  }
}
