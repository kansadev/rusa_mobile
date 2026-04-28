import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../models/voyage_model.dart';
import '../models/reservation_model.dart';
import '../models/destination_model.dart';
import '../models/bus_model.dart';
import '../models/auth_models.dart';
import '../models/reservation_with_paiement_response.dart';

class CacheService {
  static const String _clientKey = 'cached_client';
  static const String _voyagesKey = 'cached_voyages';
  static const String _reservationsKey = 'cached_reservations';
  static const String _destinationsKey = 'cached_destinations';
  static const String _busesKey = 'cached_buses';
  static const String _authResponseKey = 'cached_auth_response';
  static const String _reservationWithPaiementKey = 'cached_reservation_with_paiement';

  // Durée de cache en secondes (1 heure par défaut)
  static const int _defaultCacheDuration = 3600;

  // Sauvegarder un ClientModel
  static Future<void> saveClient(ClientModel client) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientJson = client.toJson();
      final cacheData = {
        'data': clientJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_clientKey, jsonEncode(cacheData));
      debugPrint('Client mis en cache: ${client.id}');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache du client: $e');
    }
  }

  // Récupérer un ClientModel
  static Future<ClientModel?> getClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_clientKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_clientKey);
        return null;
      }
      
      return ClientModel.fromJson(cacheData['data']);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du client depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder une liste de VoyageModel
  static Future<void> saveVoyages(List<Voyage> voyages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voyagesJson = voyages.map((v) => v.toJson()).toList();
      final cacheData = {
        'data': voyagesJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_voyagesKey, jsonEncode(cacheData));
      debugPrint('${voyages.length} voyages mis en cache');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache des voyages: $e');
    }
  }

  // Récupérer une liste de VoyageModel
  static Future<List<Voyage>?> getVoyages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_voyagesKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_voyagesKey);
        return null;
      }
      
      final voyagesJson = cacheData['data'] as List;
      return voyagesJson.map((v) => Voyage.fromJson(v)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des voyages depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder une liste de ReservationModel
  static Future<void> saveReservations(List<ReservationModel> reservations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservationsJson = reservations.map((r) => r.toJson()).toList();
      final cacheData = {
        'data': reservationsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_reservationsKey, jsonEncode(cacheData));
      debugPrint('${reservations.length} réservations mises en cache');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache des réservations: $e');
    }
  }

  // Récupérer une liste de ReservationModel
  static Future<List<ReservationModel>?> getReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_reservationsKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_reservationsKey);
        return null;
      }
      
      final reservationsJson = cacheData['data'] as List;
      return reservationsJson.map((r) => ReservationModel.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des réservations depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder une liste de DestinationModel
  static Future<void> saveDestinations(List<Destination> destinations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final destinationsJson = destinations.map((d) => d.toJson()).toList();
      final cacheData = {
        'data': destinationsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_destinationsKey, jsonEncode(cacheData));
      debugPrint('${destinations.length} destinations mises en cache');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache des destinations: $e');
    }
  }

  // Récupérer une liste de DestinationModel
  static Future<List<Destination>?> getDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_destinationsKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_destinationsKey);
        return null;
      }
      
      final destinationsJson = cacheData['data'] as List;
      return destinationsJson.map((d) => Destination.fromJson(d)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des destinations depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder une liste de BusModel
  static Future<void> saveBuses(List<Bus> buses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busesJson = buses.map((b) => b.toJson()).toList();
      final cacheData = {
        'data': busesJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_busesKey, jsonEncode(cacheData));
      debugPrint('${buses.length} bus mis en cache');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache des bus: $e');
    }
  }

  // Récupérer une liste de BusModel
  static Future<List<Bus>?> getBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_busesKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_busesKey);
        return null;
      }
      
      final busesJson = cacheData['data'] as List;
      return busesJson.map((b) => Bus.fromJson(b)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des bus depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder AuthResponse
  static Future<void> saveAuthResponse(AuthResponse authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authJson = authResponse.toJson();
      final cacheData = {
        'data': authJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_authResponseKey, jsonEncode(cacheData));
      debugPrint('AuthResponse mis en cache');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache de AuthResponse: $e');
    }
  }

  // Récupérer AuthResponse
  static Future<AuthResponse?> getAuthResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_authResponseKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_authResponseKey);
        return null;
      }
      
      return AuthResponse.fromJson(cacheData['data']);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de AuthResponse depuis le cache: $e');
      return null;
    }
  }

  // Sauvegarder ReservationWithPaiementResponse
  static Future<void> saveReservationWithPaiement(ReservationWithPaiementResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final responseJson = response.toJson();
      final cacheData = {
        'data': responseJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_reservationWithPaiementKey, jsonEncode(cacheData));
      debugPrint('ReservationWithPaiementResponse mise en cache: ${response.reservation.idReservation}');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache de ReservationWithPaiementResponse: $e');
    }
  }

  // Récupérer ReservationWithPaiementResponse
  static Future<ReservationWithPaiementResponse?> getReservationWithPaiement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_reservationWithPaiementKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (_isCacheExpired(timestamp)) {
        await prefs.remove(_reservationWithPaiementKey);
        return null;
      }
      
      return ReservationWithPaiementResponse.fromJson(cacheData['data']);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de ReservationWithPaiementResponse depuis le cache: $e');
      return null;
    }
  }

  // Vérifier si le cache est expiré
  static bool _isCacheExpired(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    return age > (_defaultCacheDuration * 1000);
  }

  // Vider tout le cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_clientKey),
        prefs.remove(_voyagesKey),
        prefs.remove(_reservationsKey),
        prefs.remove(_destinationsKey),
        prefs.remove(_busesKey),
        prefs.remove(_authResponseKey),
        prefs.remove(_reservationWithPaiementKey),
      ]);
      debugPrint('Cache vidé avec succès');
    } catch (e) {
      debugPrint('Erreur lors du vidage du cache: $e');
    }
  }

  // Vider une clé spécifique du cache
  static Future<void> clearCacheKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      debugPrint('Cache clé $key vidée avec succès');
    } catch (e) {
      debugPrint('Erreur lors du vidage de la clé $key du cache: $e');
    }
  }

  // Obtenir la taille du cache (approximative)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        _clientKey,
        _voyagesKey,
        _reservationsKey,
        _destinationsKey,
        _busesKey,
        _authResponseKey,
        _reservationWithPaiementKey,
      ];
      
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Erreur lors du calcul de la taille du cache: $e');
      return 0;
    }
  }
}
