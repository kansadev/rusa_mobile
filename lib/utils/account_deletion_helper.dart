import 'package:flutter/material.dart';
import 'package:rusa/screens/account/account_deletion_screen.dart';

/// Navigation vers la page de suppression de compte.
class AccountDeletionHelper {
  AccountDeletionHelper._();

  static void openDeletionPage(BuildContext context, {required int userId}) {
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur introuvable.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDeletionScreen(userId: userId),
      ),
    );
  }
}
