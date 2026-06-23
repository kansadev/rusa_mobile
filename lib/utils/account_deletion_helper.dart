import 'package:flutter/material.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/session_service.dart';

/// Flux de suppression douce du compte (`PUT /Utilisateur/toggle-statut/{id}`).
class AccountDeletionHelper {
  AccountDeletionHelper._();

  static Future<void> requestDeletion(
    BuildContext context, {
    required int userId,
  }) async {
    if (userId <= 0) {
      _showError(context, 'Utilisateur introuvable.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Votre compte sera désactivé et vous serez déconnecté. '
          'Cette action peut être irréversible selon la politique de RusaTravel.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Dialog(
          backgroundColor: Color(0xFF222222),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                ),
                SizedBox(height: 16),
                Text(
                  'Suppression du compte...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.toggleUtilisateurStatut(userId);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (!result.ok) {
        _showError(
          context,
          result.errorMessage ?? 'Impossible de supprimer le compte.',
        );
        return;
      }

      await SessionService().logout();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(
            registrationSuccessMessage:
                'Votre compte a été supprimé avec succès.',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showError(context, 'Erreur lors de la suppression : $e');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}
