import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:rusa/models/client_model.dart';
import 'package:rusa/models/voyage_model.dart';
import 'package:rusa/models/reservation_model.dart';
import 'package:rusa/models/destination_model.dart';
import 'package:rusa/models/bus_model.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/reservation_with_paiement_response.dart';
import 'package:rusa/models/reservation_api_model.dart';

class CacheService {
  static const String _clientBox = 'clientBox';
  static const String _voyagesBox = 'voyagesBox';
  static const String _reservationsBox = 'reservationsBox';
  static const String _destinationsBox = 'destinationsBox';
  static const String _busesBox = 'busesBox';
  static const String _authResponseBox = 'authResponseBox';
  /// V2 : schéma Billet étendu (idReservationPassenger, isUsed) — évite lecture Hive corrompue.
  static const String _reservationWithPaiementBox =
      'reservationWithPaiementBoxV2';
  static const String _reservationWithPaiementBoxLegacy =
      'reservationWithPaiementBox';

  static Future<void> init() async {
    try {
      // Vérifier que Hive est initialisé
      if (!Hive.isAdapterRegistered(0)) {
        debugPrint(
          'HIVE: Les adaptateurs ne sont pas enregistrés. Veuillez appeler registerHiveAdapters() d\'abord.',
        );
        return;
      }

      // Ouvrir les boîtes avec récupération automatique si cache corrompu.
      await _openBoxWithRecovery<ClientModel>(_clientBox);
      await _openBoxWithRecovery(_voyagesBox);
      await _openBoxWithRecovery(_reservationsBox);
      await _openBoxWithRecovery(_destinationsBox);
      await _openBoxWithRecovery(_busesBox);
      await _openBoxWithRecovery<AuthResponse>(_authResponseBox);
      await _openBoxWithRecovery<ReservationWithPaiementResponse>(
        _reservationWithPaiementBox,
      );
      try {
        await Hive.deleteBoxFromDisk(_reservationWithPaiementBoxLegacy);
      } catch (_) {}

      debugPrint('HIVE: Initialisation terminée');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<void> _openBoxWithRecovery<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return;
    try {
      if (T == dynamic) {
        await Hive.openBox(boxName);
      } else {
        await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      debugPrint('HIVE: Box "$boxName" corrompue, recréation... ($e)');
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {
        // Ignorer: la box peut déjà être fermée/inexistante.
      }
      if (T == dynamic) {
        await Hive.openBox(boxName);
      } else {
        await Hive.openBox<T>(boxName);
      }
      debugPrint('HIVE: Box "$boxName" recréée avec succès');
    }
  }

  static Future<void> saveClient(ClientModel client) async {
    try {
      final box = await Hive.openBox<ClientModel>(_clientBox);
      await box.put('client', client);
      debugPrint(
        'HIVE: Client sauvegardé (id=${client.id}, clientId=${client.clientId})',
      );
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<ClientModel?> getClient() async {
    try {
      final box = await Hive.openBox<ClientModel>(_clientBox);
      return box.get('client');
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveVoyages(List<Voyage> voyages) async {
    try {
      final box = await Hive.openBox(_voyagesBox);
      final jsonList = voyages.map((v) => v.toJson()).toList();
      await box.put('voyages', jsonEncode(jsonList));
      debugPrint('HIVE: ${voyages.length} voyages sauvegardés');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<List<Voyage>?> getVoyages() async {
    try {
      final box = await Hive.openBox(_voyagesBox);
      final jsonString = box.get('voyages');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => Voyage.fromJson(j)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveAuthResponse(AuthResponse authResponse) async {
    try {
      final box = await Hive.openBox<AuthResponse>(_authResponseBox);
      await box.put('auth', authResponse);
      debugPrint('HIVE: AuthResponse sauvegardée');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<AuthResponse?> getAuthResponse() async {
    try {
      final box = await Hive.openBox<AuthResponse>(_authResponseBox);
      final auth = box.get('auth');
      if (auth != null) {
        // Check for client_id mismatch and auto-correct
        final utilisateurClientId = auth.utilisateur.idClient;
        final clientId = auth.client.idClient;
        
        if (utilisateurClientId != null && 
            utilisateurClientId > 0 && 
            utilisateurClientId != clientId) {
          debugPrint('⚠️ AuthResponse cache: client_id mismatch detected');
          debugPrint('   client.idClient=$clientId, utilisateur.idClient=$utilisateurClientId');
          debugPrint('   Correcting client.idClient to $utilisateurClientId');
          
          // Create corrected copy
          final corrected = AuthResponse(
            success: auth.success,
            message: auth.message,
            accessToken: auth.accessToken,
            refreshToken: auth.refreshToken,
            tokenType: auth.tokenType,
            expiresIn: auth.expiresIn,
            expiresAt: auth.expiresAt,
            utilisateur: auth.utilisateur,
            doitChangerMotDePasse: auth.doitChangerMotDePasse,
            nomRole: auth.nomRole,
            nomSociete: auth.nomSociete,
            acceptNotification: auth.acceptNotification,
            permissions: auth.permissions,
            roles: auth.roles,
            primaryRole: auth.primaryRole,
            client: Client(
              idClient: utilisateurClientId,
              nomClient: auth.client.nomClient,
              codeCons: auth.client.codeCons,
              telephone: auth.client.telephone,
              emailClient: auth.client.emailClient,
              genreClient: auth.client.genreClient,
              adresseClient: auth.client.adresseClient,
              statut: auth.client.statut,
              isActif: auth.client.isActif,
              idAxe: auth.client.idAxe,
              usages: auth.client.usages,
              usagesCount: auth.client.usagesCount,
            ),
            agent: auth.agent,
          );
          await box.put('auth', corrected);
          debugPrint('✅ AuthResponse corrected in Hive cache');
          return corrected;
        }
      }
      return auth;
    } catch (e) {
      debugPrint('HIVE ERREUR getAuthResponse: $e');
      return null;
    }
  }

  static Future<void> saveReservations(
    List<ReservationModel> reservations,
  ) async {
    try {
      final box = await Hive.openBox(_reservationsBox);
      final jsonList = reservations.map((r) => r.toJson()).toList();
      await box.put('reservations', jsonEncode(jsonList));
      debugPrint('HIVE: ${reservations.length} réservations sauvegardées');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<List<ReservationModel>?> getReservations() async {
    try {
      final box = await Hive.openBox(_reservationsBox);
      final jsonString = box.get('reservations');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => ReservationModel.fromJson(j)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveClientReservations(
    int clientId,
    List<Reservation> reservations,
  ) async {
    try {
      final box = await Hive.openBox(_reservationsBox);
      final jsonList = reservations.map((r) => r.toJson()).toList();
      await box.put('client_reservations_$clientId', jsonEncode(jsonList));
      debugPrint(
        'HIVE: ${reservations.length} réservations client sauvegardées (clientId=$clientId)',
      );
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<List<Reservation>?> getClientReservations(int clientId) async {
    try {
      final box = await Hive.openBox(_reservationsBox);
      final jsonString = box.get('client_reservations_$clientId');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => Reservation.fromJson(j)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveDestinations(List<Destination> destinations) async {
    try {
      final box = await Hive.openBox(_destinationsBox);
      final jsonList = destinations.map((d) => d.toJson()).toList();
      await box.put('destinations', jsonEncode(jsonList));
      debugPrint('HIVE: ${destinations.length} destinations sauvegardées');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<List<Destination>?> getDestinations() async {
    try {
      final box = await Hive.openBox(_destinationsBox);
      final jsonString = box.get('destinations');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => Destination.fromJson(j)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveBuses(List<Bus> buses) async {
    try {
      final box = await Hive.openBox(_busesBox);
      final jsonList = buses.map((b) => b.toJson()).toList();
      await box.put('buses', jsonEncode(jsonList));
      debugPrint('HIVE: ${buses.length} bus sauvegardés');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<List<Bus>?> getBuses() async {
    try {
      final box = await Hive.openBox(_busesBox);
      final jsonString = box.get('buses');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => Bus.fromJson(j)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveReservationWithPaiement(
    ReservationWithPaiementResponse response,
  ) async {
    try {
      final box = await Hive.openBox<ReservationWithPaiementResponse>(
        _reservationWithPaiementBox,
      );
      await box.put('reservation_with_paiement', response);
      debugPrint('HIVE: ReservationWithPaiement sauvegardée');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<ReservationWithPaiementResponse?>
  getReservationWithPaiement() async {
    try {
      final box = await Hive.openBox<ReservationWithPaiementResponse>(
        _reservationWithPaiementBox,
      );
      return box.get('reservation_with_paiement');
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      // Vider complètement toutes les boîtes Hive
      await Hive.deleteBoxFromDisk(_clientBox);
      await Hive.deleteBoxFromDisk(_voyagesBox);
      await Hive.deleteBoxFromDisk(_reservationsBox);
      await Hive.deleteBoxFromDisk(_destinationsBox);
      await Hive.deleteBoxFromDisk(_busesBox);
      await Hive.deleteBoxFromDisk(_authResponseBox);
      await Hive.deleteBoxFromDisk(_reservationWithPaiementBox);
      await Hive.deleteBoxFromDisk(_reservationWithPaiementBoxLegacy);

      // Fermer toutes les boîtes ouvertes
      await Hive.close();

      debugPrint('HIVE: Cache vidé complètement');
    } catch (e) {
      debugPrint('HIVE ERREUR: $e');
    }
  }

  static Future<void> debugPrintCacheStatus() async {
    try {
      debugPrint('\n========== HIVE CACHE STATUS ==========');
      final client = await getClient();
      if (client != null) {
        debugPrint('CLIENT: id=${client.id}, clientId=${client.clientId}');
      } else {
        debugPrint('CLIENT: null');
      }
      final voyages = await getVoyages();
      if (voyages != null) {
        debugPrint('VOYAGES: ${voyages.length} items');
        for (final v in voyages) {
          debugPrint('  - ${v.id}: ${v.villeDepart} -> ${v.villeArrivee}');
        }
      } else {
        debugPrint('VOYAGES: null');
      }
      final auth = await getAuthResponse();
      if (auth != null) {
        debugPrint('AUTH: ${auth.utilisateur.nomComplet}');
      } else {
        debugPrint('AUTH: null');
      }
      debugPrint('=======================================\n');
    } catch (e) {
      debugPrint('HIVE DEBUG: $e');
    }
  }
}
