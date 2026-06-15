import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/services/api_message_catalog.dart';
import 'package:rusa/widgets/app_message.dart';

/// Affichage unifié des retours utilisateur (snackbar, dialogue, bannière).
class AppFeedback {
  AppFeedback._();

  static String normalizeMessage(String? raw, {int? httpStatus}) {
    return ApiMessageCatalog.normalize(raw, httpStatus: httpStatus);
  }

  static void showSnack(
    BuildContext context,
    String message, {
    AppMessageType type = AppMessageType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final color = switch (type) {
      AppMessageType.success => const Color(0xFF1E8E3E),
      AppMessageType.error => const Color(0xFFB71C1C),
      AppMessageType.warning => const Color(0xFFE65100),
      AppMessageType.info => const Color(0xFF1565C0),
    };

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: duration,
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showSnack(context, message, type: AppMessageType.success);
  }

  static void showError(
    BuildContext context,
    String message, {
    int? httpStatus,
  }) {
    showSnack(
      context,
      normalizeMessage(message, httpStatus: httpStatus),
      type: AppMessageType.error,
      duration: const Duration(seconds: 6),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Erreur',
    int? httpStatus,
    String confirmLabel = 'OK',
  }) {
    final normalized = normalizeMessage(message, httpStatus: httpStatus);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: AppMessage(
          type: AppMessageType.error,
          message: normalized,
          compact: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Color(0xFF00E676)),
            ),
          ),
        ],
      ),
    );
  }
}
