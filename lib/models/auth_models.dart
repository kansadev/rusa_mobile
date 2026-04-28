// Modèles pour l'authentification

class AuthResponse {
  final bool? success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final String ?tokenType;
  final int expiresIn;
  final String? expiresAt;
  final Utilisateur utilisateur;
  final bool? doitChangerMotDePasse;
  final String nomRole;
  final String nomSociete;
  final bool? acceptNotification;
  final List<String> permissions;
  final List<Role> roles;
  final Role primaryRole;
  final Client client;
  final Agent? agent;

  AuthResponse({
     this.success,
     this.message,
     this.accessToken,
     this.refreshToken,
     this.tokenType,
    required this.expiresIn,
     this.expiresAt,
    required this.utilisateur,
     this.doitChangerMotDePasse,
    required this.nomRole,
    required this.nomSociete,
     this.acceptNotification,
    required this.permissions,
    required this.roles,
    required this.primaryRole,
    required this.client,
    this.agent,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      expiresAt: json['expiresAt'] ?? '',
      utilisateur: Utilisateur.fromJson(json['utilisateur'] ?? {}),
      doitChangerMotDePasse: json['doitChangerMotDePasse'] ?? false,
      nomRole: json['nomRole'] ?? '',
      nomSociete: json['nomSociete'] ?? '',
      acceptNotification: json['acceptNotification'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      roles:
          (json['roles'] as List?)?.map((r) => Role.fromJson(r)).toList() ?? [],
      primaryRole: json['primaryRole'] != null
          ? Role.fromJson(json['primaryRole'])
          : Role(idRole: 0, nom: '', niveau: 0, statut: false),
      client: Client.fromJson(json['client'] ?? {}),
      agent: json['agent'] != null ? Agent.fromJson(json['agent']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'expiresAt': expiresAt,
      'utilisateur': utilisateur.toJson(),
      'doitChangerMotDePasse': doitChangerMotDePasse,
      'nomRole': nomRole,
      'nomSociete': nomSociete,
      'acceptNotification': acceptNotification,
      'permissions': permissions,
      'roles': roles.map((r) => r.toJson()).toList(),
      'primaryRole': primaryRole.toJson(),
      'client': client.toJson(),
      'agent': agent?.toJson(),
    };
  }
}

class Utilisateur {
  final int idUtilisateur;
  final String referenceUtilisateur;
  final String nomComplet;
  final String email;
  final String telephone;
  final String? photoUrl;
  final String? lieuNaissance;
  final String? dateNaissance;
  final String genre;
  final bool doitChangerMotDePasse;
  final bool statut;
  final int? idRole;
  final int idSociete;
  final String? adresseResidence;
  final int? idAgent;
  final int?
  idClient; // ID du client associé (peut être différent de l'ID utilisateur)
  final List<dynamic> roles;
  final Role? primaryRole;

  Utilisateur({
    required this.idUtilisateur,
    required this.referenceUtilisateur,
    required this.nomComplet,
    required this.email,
    required this.telephone,
    this.photoUrl,
    this.lieuNaissance,
    this.dateNaissance,
    required this.genre,
    required this.doitChangerMotDePasse,
    required this.statut,
    this.idRole,
    required this.idSociete,
    this.adresseResidence,
    this.idAgent,
    this.idClient,
    required this.roles,
    this.primaryRole,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idUtilisateur: json['idUtilisateur'] ?? 0,
      referenceUtilisateur: json['referenceUtilisateur'] ?? '',
      nomComplet: json['nomComplet'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      photoUrl: json['photoUrl'],
      lieuNaissance: json['lieuNaissance'],
      dateNaissance: json['dateNaissance'],
      genre: json['genre'] ?? '',
      doitChangerMotDePasse: json['doitChangerMotDePasse'] ?? false,
      statut: json['statut'] ?? false,
      idRole: json['idRole'],
      idSociete: json['idSociete'] ?? 0,
      adresseResidence: json['adresseResidence'],
      idAgent: json['idAgent'],
      idClient: json['idClient'],
      roles: (json['roles'] as List?) ?? [],
      primaryRole: json['primaryRole'] != null
          ? Role.fromJson(json['primaryRole'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUtilisateur': idUtilisateur,
      'referenceUtilisateur': referenceUtilisateur,
      'nomComplet': nomComplet,
      'email': email,
      'telephone': telephone,
      'photoUrl': photoUrl,
      'lieuNaissance': lieuNaissance,
      'dateNaissance': dateNaissance,
      'genre': genre,
      'doitChangerMotDePasse': doitChangerMotDePasse,
      'statut': statut,
      'idRole': idRole,
      'idSociete': idSociete,
      'adresseResidence': adresseResidence,
      'idAgent': idAgent,
      'idClient': idClient,
      'roles': roles,
      'primaryRole': primaryRole?.toJson(),
    };
  }
}

class Role {
  final int idRole;
  final String nom;
  final String? description;
  final int niveau;
  final bool statut;

  Role({
    required this.idRole,
    required this.nom,
    this.description,
    required this.niveau,
    required this.statut,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      idRole: json['idRole'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'],
      niveau: json['niveau'] ?? 0,
      statut: json['statut'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idRole': idRole,
      'nom': nom,
      'description': description,
      'niveau': niveau,
      'statut': statut,
    };
  }
}

class Client {
  final int idClient;
  final String nomClient;
  final String? codeCons;
  final String telephone;
  final String emailClient;
  final String genreClient;
  final String? adresseClient;
  final bool statut;
  final bool isActif;
  final int? idAxe;
  final List<dynamic> usages;
  final int usagesCount;

  Client({
    required this.idClient,
    required this.nomClient,
    this.codeCons,
    required this.telephone,
    required this.emailClient,
    required this.genreClient,
    this.adresseClient,
    required this.statut,
    required this.isActif,
    this.idAxe,
    required this.usages,
    this.usagesCount = 0,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      idClient: json['idClient'] ?? 0,
      nomClient: json['nomClient'] ?? '',
      codeCons: json['codeCons'],
      telephone: json['telephone'] ?? '',
      emailClient: json['emailClient'] ?? '',
      genreClient: json['genreClient'] ?? '',
      adresseClient: json['adresseClient'],
      statut: json['statut'] ?? false,
      isActif: json['isActif'] ?? false,
      idAxe: json['idAxe'],
      usages: (json['usages'] as List?) ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idClient': idClient,
      'nomClient': nomClient,
      'codeCons': codeCons,
      'telephone': telephone,
      'emailClient': emailClient,
      'genreClient': genreClient,
      'adresseClient': adresseClient,
      'statut': statut,
      'isActif': isActif,
      'idAxe': idAxe,
      'usages': usages,
    };
  }
}

class Agent {
  final int idAgent;
  final String nomAgent;

  Agent({required this.idAgent, required this.nomAgent});

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      idAgent: json['idAgent'] ?? 0,
      nomAgent: json['nomAgent'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'idAgent': idAgent, 'nomAgent': nomAgent};
  }
}

// Modèle pour la requête d'authentification
class AuthRequest {
  final String emailOuTelephone;
  final String motDePasse;

  AuthRequest({required this.emailOuTelephone, required this.motDePasse});

  Map<String, dynamic> toJson() {
    return {'emailOuTelephone': emailOuTelephone, 'motDePasse': motDePasse};
  }
}
