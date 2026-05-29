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

class UtilisateurProfileUpdate {
  final int idUtilisateur;
  final String nomComplet;
  final String email;
  final String telephone;
  final String? photoUrl;
  final String? lieuNaissance;
  final String? dateNaissance;
  final String genre;

  UtilisateurProfileUpdate({
    required this.idUtilisateur,
    required this.nomComplet,
    required this.email,
    required this.telephone,
    this.photoUrl,
    this.lieuNaissance,
    this.dateNaissance,
    required this.genre,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUtilisateur': idUtilisateur,
      'nomComplet': nomComplet,
      'email': email,
      'telephone': telephone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (lieuNaissance != null) 'lieuNaissance': lieuNaissance,
      if (dateNaissance != null) 'dateNaissance': dateNaissance,
      'genre': genre,
    };
  }
}
