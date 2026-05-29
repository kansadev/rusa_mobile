import 'package:hive/hive.dart';
import '../models/client_model.dart';
import '../models/voyage_model.dart';
import '../models/reservation_model.dart';
import '../models/destination_model.dart';
import '../models/bus_model.dart';
import '../models/auth_models.dart';
import '../models/reservation_with_paiement_response.dart';

// Adapter pour ClientModel
class ClientModelAdapter extends TypeAdapter<ClientModel> {
  @override
  final typeId = 0;

  @override
  ClientModel read(BinaryReader reader) {
    return ClientModel(
      id: reader.readInt(),
      username: reader.readString(),
      email: reader.readString(),
      nom: reader.readString(),
      postnom: reader.readString(),
      telephone: reader.readString(),
      genre: reader.readString(),
      statut: reader.readBool(),
      dateCreation: reader.readString(),
      idRole: reader.readInt(),
      idSociete: reader.readInt(),
      photoUrl: reader.readString(),
      clientId: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ClientModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.username);
    writer.writeString(obj.email);
    writer.writeString(obj.nom);
    writer.writeString(obj.postnom);
    writer.writeString(obj.telephone);
    writer.writeString(obj.genre);
    writer.writeBool(obj.statut);
    writer.writeString(obj.dateCreation);
    writer.writeInt(obj.idRole);
    writer.writeInt(obj.idSociete);
    writer.writeString(obj.photoUrl ?? '');
    writer.writeInt(obj.clientId);
  }
}

// Adapter pour Voyage
class VoyageAdapter extends TypeAdapter<Voyage> {
  @override
  final typeId = 1;

  @override
  Voyage read(BinaryReader reader) {
    return Voyage(
      id: reader.readInt(),
      dateDepart: reader.readString(),
      heureDepart: reader.readString(),
      prix: reader.readDouble(),
      idBus: reader.readInt(),
      idDestination: reader.readInt(),
      idSociete: reader.readInt(),
      statut: reader.readBool(),
      dateCreation: reader.readString(),
      dateModification: reader.readString(),
      numeroBus: reader.readString(),
      libelleTypeBus: reader.readString(),
      nomSociete: reader.readString(),
      villeDepart: reader.readString(),
      villeArrivee: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Voyage obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.dateDepart);
    writer.writeString(obj.heureDepart);
    writer.writeDouble(obj.prix);
    writer.writeInt(obj.idBus);
    writer.writeInt(obj.idDestination);
    writer.writeInt(obj.idSociete);
    writer.writeBool(obj.statut);
    writer.writeString(obj.dateCreation);
    writer.writeString(obj.dateModification ?? '');
    writer.writeString(obj.numeroBus);
    writer.writeString(obj.libelleTypeBus);
    writer.writeString(obj.nomSociete ?? '');
    writer.writeString(obj.villeDepart);
    writer.writeString(obj.villeArrivee);
  }
}

// Adapter pour ReservationModel
class ReservationModelAdapter extends TypeAdapter<ReservationModel> {
  @override
  final typeId = 2;

  @override
  ReservationModel read(BinaryReader reader) {
    return ReservationModel(
      idReservation: reader.readInt(),
      idVoyage: reader.readInt(),
      idClient: reader.readInt(),
      statutReservation: reader.readString(),
      statut: reader.readBool(),
      dateReservation: reader.readString(),
      voyage: VoyageInfo(
        id: reader.readInt(),
        dateDepart: reader.readString(),
        prix: reader.readDouble(),
      ),
      client: ClientInfo(
        idClient: reader.readInt(),
        nom: reader.readString(),
        email: reader.readString(),
      ),
      paiement: PaiementInfo(
        idPaiement: reader.readInt(),
        montant: reader.readDouble(),
        methodePaiement: reader.readString(),
        statut: reader.readBool(),
      ),
    );
  }

  @override
  void write(BinaryWriter writer, ReservationModel obj) {
    writer.writeInt(obj.idReservation);
    writer.writeInt(obj.idVoyage);
    writer.writeInt(obj.idClient);
    writer.writeString(obj.statutReservation);
    writer.writeBool(obj.statut);
    writer.writeString(obj.dateReservation);

    writer.writeInt(obj.voyage.id);
    writer.writeString(obj.voyage.dateDepart);
    writer.writeDouble(obj.voyage.prix);

    writer.writeInt(obj.client.idClient);
    writer.writeString(obj.client.nom);
    writer.writeString(obj.client.email);

    writer.writeInt(obj.paiement.idPaiement);
    writer.writeDouble(obj.paiement.montant);
    writer.writeString(obj.paiement.methodePaiement);
    writer.writeBool(obj.paiement.statut);
  }
}

// Adapter pour Destination
class DestinationAdapter extends TypeAdapter<Destination> {
  @override
  final typeId = 3;

  @override
  Destination read(BinaryReader reader) {
    return Destination(
      idDestination: reader.readInt(),
      villeDepart: reader.readString(),
      villeArrivee: reader.readString(),
      montant: reader.readDouble(),
      jourDepart: null,
      statut: reader.readBool(),
      dateCreation: reader.readString(),
      dateModification: reader.readString(),
      idSociete: reader.readInt(),
      nomSociete: reader.readString(),
      deviseSociete: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Destination obj) {
    writer.writeInt(obj.idDestination);
    writer.writeString(obj.villeDepart);
    writer.writeString(obj.villeArrivee);
    writer.writeDouble(obj.montant);
    writer.writeBool(obj.statut);
    writer.writeString(obj.dateCreation);
    writer.writeString(obj.dateModification ?? '');
    writer.writeInt(obj.idSociete);
    writer.writeString(obj.nomSociete);
    writer.writeString(obj.deviseSociete ?? '');
  }
}

// Adapter pour Bus
class BusAdapter extends TypeAdapter<Bus> {
  @override
  final typeId = 4;

  @override
  Bus read(BinaryReader reader) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String asString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    bool asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.toLowerCase().trim();
        return v == 'true' || v == '1';
      }
      return false;
    }

    final idVehicule = asInt(reader.read());
    final marques = asString(reader.read());
    final thirdField = reader.read();
    final fourthField = reader.read();
    final fifthField = reader.read();
    final nombreSiege = asInt(reader.read());
    final idSociete = asInt(reader.read());
    final numeroDePlaque = asString(reader.read());
    final photo = asString(reader.read());
    final statut = asBool(reader.read());
    final dateCreation = asString(reader.read());
    final dateModificationRaw = reader.read();
    final nomSociete = asString(reader.read());

    // Compatibilité:
    // - ancien format: (numeroBus:int, idTypeBus:int, libelleTypeBus:String)
    // - nouveau format: (aliasVehicule:String, idTypeVehicule:int, libelleTypeVehicule:String?)
    final aliasVehicule =
        thirdField is String ? thirdField : asString(thirdField);
    final idTypeVehicule = asInt(fourthField);
    final libelleTypeVehicule = asString(fifthField);
    final dateModification = asString(dateModificationRaw);

    return Bus(
      idVehicule: idVehicule,
      marques: marques,
      aliasVehicule: aliasVehicule,
      idTypeVehicule: idTypeVehicule,
      libelleTypeVehicule:
          libelleTypeVehicule.isEmpty ? null : libelleTypeVehicule,
      nombreSiege: nombreSiege,
      idSociete: idSociete,
      numeroDePlaque: numeroDePlaque,
      photo: photo,
      statut: statut,
      dateCreation: dateCreation,
      dateModification: dateModification.isEmpty ? null : dateModification,
      nomSociete: nomSociete,
    );
  }

  @override
  void write(BinaryWriter writer, Bus obj) {
    writer.writeInt(obj.idVehicule);
    writer.writeString(obj.marques);
    writer.writeString(obj.aliasVehicule);
    writer.writeInt(obj.idTypeVehicule);
    writer.writeString(obj.libelleTypeVehicule ?? '');
    writer.writeInt(obj.nombreSiege);
    writer.writeInt(obj.idSociete);
    writer.writeString(obj.numeroDePlaque);
    writer.writeString(obj.photo);
    writer.writeBool(obj.statut);
    writer.writeString(obj.dateCreation);
    writer.writeString(obj.dateModification ?? '');
    writer.writeString(obj.nomSociete);
  }
}

// Adapter pour AuthResponse
class AuthResponseAdapter extends TypeAdapter<AuthResponse> {
  @override
  final typeId = 5;

  @override
  AuthResponse read(BinaryReader reader) {
    final success = reader.readBool();
    final message = reader.readString();
    final accessToken = reader.readString();
    final refreshToken = reader.readString();
    final tokenType = reader.readString();
    final expiresIn = reader.readInt();
    final expiresAt = reader.readString();

    // Lire utilisateur
    final idUtilisateur = reader.readInt();
    final referenceUtilisateur = reader.readString();
    final nomComplet = reader.readString();
    final email = reader.readString();
    final telephone = reader.readString();
    final photoUrl = reader.readString();
    final lieuNaissance = reader.readString();
    final dateNaissance = reader.readString();
    final genre = reader.readString();
    final doitChangerMotDePasse = reader.readBool();
    final statut = reader.readBool();
    final idRole = reader.readInt();
    final idSociete = reader.readInt();
    final adresseResidence = reader.readString();
    final idAgent = reader.readInt();
    final clientIdValue = reader.readInt();
    final rolesCount = reader.readInt();
    final roles = <dynamic>[];
    for (var i = 0; i < rolesCount; i++) {
      roles.add(reader.readString());
    }
    final hasPrimaryRole = reader.readBool();
    final primaryRole = hasPrimaryRole
        ? Role(
            idRole: reader.readInt(),
            nom: reader.readString(),
            description: reader.readString(),
            niveau: reader.readInt(),
            statut: reader.readBool(),
          )
        : null;

    final utilisateur = Utilisateur(
      idUtilisateur: idUtilisateur,
      referenceUtilisateur: referenceUtilisateur,
      nomComplet: nomComplet,
      email: email,
      telephone: telephone,
      photoUrl: photoUrl,
      lieuNaissance: lieuNaissance,
      dateNaissance: dateNaissance,
      genre: genre,
      doitChangerMotDePasse: doitChangerMotDePasse,
      statut: statut,
      idRole: idRole,
      idSociete: idSociete,
      adresseResidence: adresseResidence,
      idAgent: idAgent,
      idClient: clientIdValue,
      roles: roles,
      primaryRole: primaryRole,
    );

    final doitChangerMotDePasse2 = reader.readBool();
    final nomRole = reader.readString();
    final nomSociete = reader.readString();
    final acceptNotification = reader.readBool();
    final permissionsCount = reader.readInt();
    final permissions = <String>[];
    for (var i = 0; i < permissionsCount; i++) {
      permissions.add(reader.readString());
    }
    final rolesCount2 = reader.readInt();
    final roles2 = <Role>[];
    for (var i = 0; i < rolesCount2; i++) {
      roles2.add(
        Role(
          idRole: reader.readInt(),
          nom: reader.readString(),
          description: reader.readString(),
          niveau: reader.readInt(),
          statut: reader.readBool(),
        ),
      );
    }
    final hasPrimaryRole2 = reader.readBool();
    final primaryRole2 = hasPrimaryRole2
        ? Role(
            idRole: reader.readInt(),
            nom: reader.readString(),
            description: reader.readString(),
            niveau: reader.readInt(),
            statut: reader.readBool(),
          )
        : Role(idRole: 0, nom: 'Client', niveau: 0, statut: true);

    final idClient = reader.readInt();
    final nomClient = reader.readString();
    final codeCons = reader.readString();
    final telephoneClient = reader.readString();
    final emailClient = reader.readString();
    final genreClient = reader.readString();
    final adresseClient = reader.readString();
    final statutClient = reader.readBool();
    final isActifClient = reader.readBool();
    final idAxeClient = reader.readInt();
    final clientUsagesCount = reader.readInt();
    final client = Client(
      idClient: idClient,
      nomClient: nomClient,
      codeCons: codeCons,
      telephone: telephoneClient,
      emailClient: emailClient,
      genreClient: genreClient,
      adresseClient: adresseClient,
      statut: statutClient,
      isActif: isActifClient,
      idAxe: idAxeClient,
      usagesCount: clientUsagesCount,
      usages: List<String>.generate(clientUsagesCount, (_) => reader.readString()),
    );

    final hasAgent = reader.readBool();
    final agent = hasAgent
        ? Agent(idAgent: reader.readInt(), nomComplet: reader.readString())
        : null;

    return AuthResponse(
      success: success,
      message: message,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      expiresAt: expiresAt,
      utilisateur: utilisateur,
      doitChangerMotDePasse: doitChangerMotDePasse2,
      nomRole: nomRole,
      nomSociete: nomSociete,
      acceptNotification: acceptNotification,
      permissions: permissions,
      roles: roles2,
      primaryRole: primaryRole2,
      client: client,
      agent: agent,
    );
  }

  @override
  void write(BinaryWriter writer, AuthResponse obj) {
    writer.writeBool(obj.success ?? false);
    writer.writeString(obj.message ?? '');
    writer.writeString(obj.accessToken ?? '');
    writer.writeString(obj.refreshToken ?? '');
    writer.writeString(obj.tokenType ?? '');
    writer.writeInt(obj.expiresIn);
    writer.writeString(obj.expiresAt ?? '');

    writer.writeInt(obj.utilisateur.idUtilisateur);
    writer.writeString(obj.utilisateur.referenceUtilisateur);
    writer.writeString(obj.utilisateur.nomComplet);
    writer.writeString(obj.utilisateur.email);
    writer.writeString(obj.utilisateur.telephone);
    writer.writeString(obj.utilisateur.photoUrl ?? '');
    writer.writeString(obj.utilisateur.lieuNaissance ?? '');
    writer.writeString(obj.utilisateur.dateNaissance ?? '');
    writer.writeString(obj.utilisateur.genre);
    writer.writeBool(obj.utilisateur.doitChangerMotDePasse);
    writer.writeBool(obj.utilisateur.statut);
    writer.writeInt(obj.utilisateur.idRole ?? 0);
    writer.writeInt(obj.utilisateur.idSociete);
    writer.writeString(obj.utilisateur.adresseResidence ?? '');
    writer.writeInt(obj.utilisateur.idAgent ?? 0);
    writer.writeInt(obj.utilisateur.idClient ?? 0);
    writer.writeInt(obj.utilisateur.roles.length);
    for (final role in obj.utilisateur.roles) {
      writer.writeString(role.toString());
    }
    writer.writeBool(obj.utilisateur.primaryRole != null);
    if (obj.utilisateur.primaryRole != null) {
      writer.writeInt(obj.utilisateur.primaryRole!.idRole);
      writer.writeString(obj.utilisateur.primaryRole!.nom);
      writer.writeString(obj.utilisateur.primaryRole!.description ?? '');
      writer.writeInt(obj.utilisateur.primaryRole!.niveau);
      writer.writeBool(obj.utilisateur.primaryRole!.statut);
    }

    writer.writeBool(obj.doitChangerMotDePasse ?? false);
    writer.writeString(obj.nomRole);
    writer.writeString(obj.nomSociete);
    writer.writeBool(obj.acceptNotification ?? false);
    writer.writeInt(obj.permissions.length);
    for (final perm in obj.permissions) {
      writer.writeString(perm);
    }
    writer.writeInt(obj.roles.length);
    for (final role in obj.roles) {
      writer.writeInt(role.idRole);
      writer.writeString(role.nom);
      writer.writeString(role.description ?? '');
      writer.writeInt(role.niveau);
      writer.writeBool(role.statut);
    }
    // ignore: unnecessary_null_comparison
    writer.writeBool(obj.primaryRole != null);
    writer.writeInt(obj.primaryRole.idRole);
    writer.writeString(obj.primaryRole.nom);
    writer.writeString(obj.primaryRole.description ?? '');
    writer.writeInt(obj.primaryRole.niveau);
    writer.writeBool(obj.primaryRole.statut);

    writer.writeInt(obj.client.idClient);
    writer.writeString(obj.client.nomClient);
    writer.writeString(obj.client.codeCons ?? '');
    writer.writeString(obj.client.telephone);
    writer.writeString(obj.client.emailClient);
    writer.writeString(obj.client.genreClient);
    writer.writeString(obj.client.adresseClient ?? '');
    writer.writeBool(obj.client.statut);
    writer.writeBool(obj.client.isActif);
    writer.writeInt(obj.client.idAxe ?? 0);
    writer.writeInt(obj.client.usages.length);
    for (final usage in obj.client.usages) {
      writer.writeString(usage.toString());
    }

    writer.writeBool(obj.agent != null);
    if (obj.agent != null) {
      writer.writeInt(obj.agent!.idAgent);
      writer.writeString(obj.agent!.nomComplet);
    }
  }
}

// Adapter pour ReservationWithPaiementResponse
class ReservationWithPaiementResponseAdapter
    extends TypeAdapter<ReservationWithPaiementResponse> {
  @override
  final typeId = 6;

  @override
  ReservationWithPaiementResponse read(BinaryReader reader) {
    return ReservationWithPaiementResponse(
      reservation: ReservationData(
        idReservation: reader.readInt(),
        idUtilisateur: reader.readInt(),
        idClient: reader.readInt(),
        idVoyage: reader.readInt(),
        statutReservation: reader.readString(),
        statut: reader.readBool(),
        dateReservation: reader.readString(),
        idSociete: reader.readInt(),
        dateCreation: reader.readString(),
        dateModification: reader.readString(),
        nomUtilisateur: reader.readString(),
        emailUtilisateur: reader.readString(),
        nomClient: reader.readString(),
        prenomClient: reader.readString(),
        telephoneClient: reader.readString(),
        dateVoyage: reader.readString(),
        prixVoyage: reader.readDouble(),
        numeroBus: reader.readString(),
        villeDepart: reader.readString(),
        villeArrivee: reader.readString(),
      ),
      paiement: PaiementData(
        idPaiement: reader.readInt(),
        montantAPaye: reader.readDouble(),
        montantPaye: reader.readDouble(),
        resteAPaye: reader.readDouble(),
        methodePaiement: reader.readString(),
        referenceTransaction: reader.readString(),
        statut: reader.readBool(),
        dateCreation: reader.readString(),
        dateEmissionBillet: reader.readString(),
        idBilletEmis: reader.readInt(),
        idReservation: reader.readInt(),
        idSociete: reader.readInt(),
        estComplet: reader.readBool(),
        estPartiel: reader.readBool(),
      ),
      billet: reader.readBool()
          ? BilletData(
              id: reader.readInt(),
              qrCode: reader.readString(),
              dateGeneration: reader.readString(),
              idReservation: reader.readInt(),
              idClient: reader.readInt(),
              idSociete: reader.readInt(),
              urlBillet: reader.readString(),
              idReservationPassenger: reader.readInt(),
              isUsed: reader.readBool(),
            )
          : null,
      // Liste multi-billets non persistée (compatibilité boîte Hive existante).
      billets: const [],
      transactionId: reader.readString(),
      statut: reader.readString(),
      message: reader.readString(),
      dateCreation: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ReservationWithPaiementResponse obj) {
    writer.writeInt(obj.reservation.idReservation);
    writer.writeInt(obj.reservation.idUtilisateur);
    writer.writeInt(obj.reservation.idClient);
    writer.writeInt(obj.reservation.idVoyage);
    writer.writeString(obj.reservation.statutReservation);
    writer.writeBool(obj.reservation.statut);
    writer.writeString(obj.reservation.dateReservation);
    writer.writeInt(obj.reservation.idSociete);
    writer.writeString(obj.reservation.dateCreation);
    writer.writeString(obj.reservation.dateModification ?? "");
    writer.writeString(obj.reservation.nomUtilisateur ?? "");
    writer.writeString(obj.reservation.emailUtilisateur ?? "");
    writer.writeString(obj.reservation.nomClient ?? "");
    writer.writeString(obj.reservation.prenomClient ?? "");
    writer.writeString(obj.reservation.telephoneClient ?? "");
    writer.writeString(obj.reservation.dateVoyage ?? "");

    writer.writeDouble(obj.reservation.prixVoyage ?? 0.0);
    writer.writeString(obj.reservation.numeroBus ?? "");
    writer.writeString(obj.reservation.villeDepart ?? "");
    writer.writeString(obj.reservation.villeArrivee ?? "");

    writer.writeInt(obj.paiement.idPaiement);
    writer.writeDouble(obj.paiement.montantAPaye);
    writer.writeDouble(obj.paiement.montantPaye);
    writer.writeDouble(obj.paiement.resteAPaye);
    writer.writeString(obj.paiement.methodePaiement);
    writer.writeString(obj.paiement.referenceTransaction);
    writer.writeBool(obj.paiement.statut);
    writer.writeString(obj.paiement.dateCreation);
    writer.writeString(obj.paiement.dateEmissionBillet);
    writer.writeInt(obj.paiement.idBilletEmis);
    writer.writeInt(obj.paiement.idReservation);
    writer.writeInt(obj.paiement.idSociete);
    writer.writeBool(obj.paiement.estComplet);
    writer.writeBool(obj.paiement.estPartiel);

    writer.writeBool(obj.billet != null);
    if (obj.billet != null) {
      writer.writeInt(obj.billet!.id);
      writer.writeString(obj.billet!.qrCode);
      writer.writeString(obj.billet!.dateGeneration);
      writer.writeInt(obj.billet!.idReservation);
      writer.writeInt(obj.billet!.idClient);
      writer.writeInt(obj.billet!.idSociete);
      writer.writeString(obj.billet!.urlBillet);
      writer.writeInt(obj.billet!.idReservationPassenger);
      writer.writeBool(obj.billet!.isUsed);
    }

    writer.writeString(obj.transactionId);
    writer.writeString(obj.statut);
    writer.writeString(obj.message);
    writer.writeString(obj.dateCreation);
  }
}

void registerHiveAdapters() {
  Hive.registerAdapter(ClientModelAdapter());
  Hive.registerAdapter(VoyageAdapter());
  Hive.registerAdapter(ReservationModelAdapter());
  Hive.registerAdapter(DestinationAdapter());
  Hive.registerAdapter(BusAdapter());
  Hive.registerAdapter(AuthResponseAdapter());
  Hive.registerAdapter(ReservationWithPaiementResponseAdapter());
}
