class ClientModel {
  final int id;
  final String username;
  final String email;
  final String nom;
  final String postnom;
  final String telephone;
  final String genre;
  final bool statut;
  final String dateCreation;
  final int idRole;
  final int idSociete;
  final String? photoUrl;
  final int clientId;

  ClientModel({
    required this.id,
    required this.username,
    required this.email,
    required this.nom,
    required this.postnom,
    required this.telephone,
    required this.genre,
    required this.statut,
    required this.dateCreation,
    required this.idRole,
    required this.idSociete,
    this.photoUrl,
    required this.clientId,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      postnom: json['postnom'] ?? '',
      telephone: json['telephone'] ?? '',
      genre: json['genre'] ?? '',
      statut: json['statut'] ?? false,
      dateCreation: json['dateCreation'] ?? '',
      idRole: json['idRole'] ?? 0,
      idSociete: json['idSociete'] ?? 0,
      photoUrl: json['photoUrl'],
      clientId: json['clientId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nom': nom,
      'postnom': postnom,
      'telephone': telephone,
      'genre': genre,
      'statut': statut,
      'dateCreation': dateCreation,
      'idRole': idRole,
      'idSociete': idSociete,
      'photoUrl': photoUrl,
      'clientId': clientId,
    };
  }
}
