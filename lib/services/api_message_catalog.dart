/// Traduction des messages API en libellés compréhensibles pour l'utilisateur.
class ApiMessageCatalog {
  ApiMessageCatalog._();

  static String normalize(String? raw, {int? httpStatus}) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _fallbackForStatus(httpStatus);
    }

    final lower = trimmed.toLowerCase();

    if (lower.contains('aucune configuration flexpay')) {
      return 'Le paiement Mobile Money n\'est pas configuré pour ce point de vente. '
          'Choisissez un autre mode de paiement ou contactez l\'administrateur.';
    }
    if (lower.contains('flexpay') && lower.contains('inactif')) {
      return 'Le service de paiement électronique est temporairement indisponible. '
          'Réessayez plus tard ou payez en espèces.';
    }
    if (lower.contains('siège') && lower.contains('disponible')) {
      return 'Ce siège n\'est plus disponible. Veuillez en choisir un autre.';
    }
    if (lower.contains('places insuffisantes') ||
        lower.contains('nombre de place')) {
      return 'Il n\'y a plus assez de places pour ce voyage.';
    }
    if (lower.contains('token') && lower.contains('expir')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    if (lower.contains('non autorisé') || lower.contains('unauthorized')) {
      return 'Accès refusé. Vérifiez vos droits ou reconnectez-vous.';
    }

    return trimmed;
  }

  static String _fallbackForStatus(int? httpStatus) {
    if (httpStatus != null && httpStatus >= 500) {
      return 'Le serveur est indisponible. Réessayez dans quelques instants.';
    }
    return switch (httpStatus) {
      400 => 'La demande est invalide. Vérifiez les informations saisies.',
      401 => 'Session expirée. Veuillez vous reconnecter.',
      403 => 'Vous n\'avez pas l\'autorisation pour cette action.',
      404 => 'Ressource introuvable.',
      409 => 'Conflit : cette opération ne peut pas être effectuée.',
      422 => 'Certaines informations sont incorrectes.',
      _ => 'Une erreur est survenue. Veuillez réessayer.',
    };
  }
}
