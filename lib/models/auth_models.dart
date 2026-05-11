// Modèles pour l'authentification

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

int _asInt(dynamic value, {int fallback = 0}) {
  return _asNullableInt(value) ?? fallback;
}

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

  int get effectiveClientId {
    final userClientId = utilisateur.idClient ?? 0;
    if (userClientId > 0) return userClientId;
    return client.idClient;
  }

  bool get hasClientProfile => effectiveClientId > 0;
  bool get hasAgentProfile => (agent?.idAgent ?? utilisateur.idAgent ?? 0) > 0;

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
    final clientData = _normalizeSection(json['client']);
    final agentData = _normalizeSection(json['agent']);

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
      client: Client.fromJson(clientData ?? {}),
      agent: agentData != null ? Agent.fromJson(agentData) : null,
    );
  }

  static Map<String, dynamic>? _normalizeSection(dynamic section) {
    if (section is Map<String, dynamic>) return section;
    if (section is List && section.isNotEmpty && section.first is Map<String, dynamic>) {
      return section.first as Map<String, dynamic>;
    }
    return null;
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
  final int? idSite;
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
    this.idSite,
    required this.roles,
    this.primaryRole,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idUtilisateur: _asInt(json['idUtilisateur']),
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
      idRole: _asNullableInt(json['idRole']),
      idSociete: _asInt(json['idSociete']),
      adresseResidence: json['adresseResidence'],
      idAgent: _asNullableInt(json['idAgent']),
      idClient: _asNullableInt(
        json['idClient'] ?? json['clientId'] ?? json['client_id'],
      ),
      idSite: _asNullableInt(json['idSite']),
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
      'idSite': idSite,
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

  factory Client.empty() {
    return Client(
      idClient: 0,
      nomClient: '',
      telephone: '',
      emailClient: '',
      genreClient: '',
      statut: false,
      isActif: false,
      usages: const [],
    );
  }

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
  final String nomComplet;
  final String? matricule;
  final String? genre;
  final String? dateNaissance;
  final String? telephoneAgent;
  final String? emailAgent;
  final bool? statut;
  final String? fonction;
  final String? roleAgent;
  final String? photoUrl;
  final int? idSociete;
  final int? idSite;
  final String? adresseResidence;
  final String? zone;

  String get nomAgent => nomComplet;

  Agent({
    required this.idAgent,
    required this.nomComplet,
    this.matricule,
    this.genre,
    this.dateNaissance,
    this.telephoneAgent,
    this.emailAgent,
    this.statut,
    this.fonction,
    this.roleAgent,
    this.photoUrl,
    this.idSociete,
    this.idSite,
    this.adresseResidence,
    this.zone,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      idAgent: _asInt(json['idAgent']),
      nomComplet: json['nomComplet'] ?? json['nomAgent'] ?? '',
      matricule: json['matricule'],
      genre: json['genre'],
      dateNaissance: json['dateNaissance'],
      telephoneAgent: json['telephoneAgent'],
      emailAgent: json['emailAgent'],
      statut: json['statut'],
      fonction: json['fonction'],
      roleAgent: json['roleAgent'],
      photoUrl: json['photoUrl'],
      idSociete: _asNullableInt(json['idSociete']),
      idSite: _asNullableInt(json['idSite']),
      adresseResidence: json['adresseResidence'],
      zone: json['zone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idAgent': idAgent,
      'nomComplet': nomComplet,
      'matricule': matricule,
      'genre': genre,
      'dateNaissance': dateNaissance,
      'telephoneAgent': telephoneAgent,
      'emailAgent': emailAgent,
      'statut': statut,
      'fonction': fonction,
      'roleAgent': roleAgent,
      'photoUrl': photoUrl,
      'idSociete': idSociete,
      'idSite': idSite,
      'adresseResidence': adresseResidence,
      'zone': zone,
    };
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
