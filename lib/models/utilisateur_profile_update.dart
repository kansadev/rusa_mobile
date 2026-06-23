import 'package:rusa/models/auth_models.dart';

class UtilisateurPutResult {
  final bool ok;
  final String? errorMessage;
  final Utilisateur? utilisateur;

  UtilisateurPutResult({
    required this.ok,
    this.errorMessage,
    this.utilisateur,
  });
}

class UtilisateurToggleStatutResult {
  final bool ok;
  final String? errorMessage;

  const UtilisateurToggleStatutResult({
    required this.ok,
    this.errorMessage,
  });
}

class UtilisateurProfileUpdate {
  final int idUtilisateur;
  final String nomComplet;
  final String email;
  final String telephone;
  final String? photoUrl;
  final String? lieuNaissance;
  final String? dateNaissance;
  final String? genre;

  UtilisateurProfileUpdate({
    required this.idUtilisateur,
    required this.nomComplet,
    required this.email,
    required this.telephone,
    this.photoUrl,
    this.lieuNaissance,
    this.dateNaissance,
    this.genre,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUtilisateur': idUtilisateur,
      'nomComplet': nomComplet,
      'email': email.trim().isEmpty ? null : email.trim(),
      'telephone': telephone.trim().isEmpty ? null : telephone.trim(),
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (lieuNaissance != null && lieuNaissance!.trim().isNotEmpty)
        'lieuNaissance': lieuNaissance!.trim(),
      if (dateNaissance != null && dateNaissance!.trim().isNotEmpty)
        'dateNaissance': dateNaissance,
      if (genre != null && genre!.trim().isNotEmpty)
        'genre': genreForApi(genre!),
    };
  }

  static String genreForApi(String genre) {
    final g = genre.trim().toLowerCase();
    if (g == 'homme' || g == 'm' || g.startsWith('mascul')) return 'M';
    if (g == 'femme' || g == 'f') return 'F';
    return genre.trim();
  }
}
