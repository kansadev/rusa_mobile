import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/client_model.dart';
import '../models/reservation_model.dart';
import '../models/create_reservation_request.dart';
import '../models/auth_models.dart';
import '../models/destination_model.dart';
import '../models/bus_model.dart';
import '../models/voyage_model.dart';
import '../models/reservation_with_paiement_request.dart';
import '../models/reservation_with_paiement_response.dart';
import 'session_service.dart';

class ApiService {
  static const String baseUrl = 'https://dev-rusatravel.asdc-rdc.org/api';
  // Pour le développement: static const String baseUrl = 'https://localhost:7110/api';

  // Méthode pour ajouter le token d'authentification aux requêtes
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        debugPrint(
          'Aucun token trouvé, retour des headers sans authentification',
        );
        return {'Content-Type': 'application/json'};
      }

      debugPrint('Token récupéré pour l\'authentification');
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      return {'Content-Type': 'application/json'};
    }
  }

  // ========== MÉTHODES CLIENT ==========

  // Récupérer le profil du client connecté
  static Future<ClientModel?> getClientProfile() async {
    try {
      // Utiliser les données de la session au lieu de l'API
      final session = SessionService();
      final userData = await session.getUserInfo();

      if (userData == null) {
        debugPrint(
          'Impossible de récupérer les données utilisateur de la session',
        );
        return null;
      }

      // Créer un ClientModel à partir des données de session
      final name = userData['name'] ?? '';
      final nameParts = name.split(' ');

      // Récupérer photoUrl depuis les données utilisateur si disponible
      String? photoUrl;
      try {
        // Essayer de récupérer les données utilisateur complètes pour photoUrl
        final prefs = await SharedPreferences.getInstance();
        final authData = prefs.getString('auth_data');
        if (authData != null) {
          final authJson = json.decode(authData);
          photoUrl = authJson['utilisateur']?['photoUrl'];
        }
      } catch (e) {
        debugPrint('Impossible de récupérer photoUrl: $e');
      }

      return ClientModel(
        id: int.tryParse(userData['id'] ?? '0') ?? 0,
        clientId: int.tryParse(userData['client_id'] ?? '0') ?? 0,
        username: name,
        email: userData['email'] ?? '',
        nom: nameParts.isNotEmpty ? nameParts.first : '',
        postnom: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        telephone: userData['phone'] ?? '',
        genre: 'Masculin', // Valeur par défaut
        statut: true,
        dateCreation: DateTime.now().toIso8601String(),
        idRole: 6, // Role Client par défaut
        idSociete: 1, // Société par défaut
        photoUrl: photoUrl,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil client: $e');
      return null;
    }
  }

  // Mettre à jour le profil du client
  static Future<bool> updateClientProfile(ClientModel client) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/Utilisateur/update/${client.id}'),
        headers: headers,
        body: jsonEncode({
          'nom': client.nom,
          'postnom': client.postnom,
          'telephone': client.telephone,
          'email': client.email,
          'genre': client.genre,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'];
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil client: $e');
      return false;
    }
  }

  // ========== MÉTHODES CAISSIER ==========

  // Récupérer les réservations (pour le caissier)
  static Future<List<ReservationModel>?> getReservations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Reservation/get-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => ReservationModel.fromJson(json)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      return null;
    }
  }

  // Récupérer les réservations d'un client spécifique
  static Future<List<ReservationModel>?> getReservationsByClient(
    int idClient,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Reservation/client/$idClient'),
        headers: headers,
      );

      debugPrint(
        'Requête réservations client: $baseUrl/Reservation/client/$idClient',
      );
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          // Si la réponse est directement une liste
          return jsonResponse
              .map((json) => ReservationModel.fromJson(json))
              .toList();
        } else if (jsonResponse['success'] == true) {
          // Si la réponse a une structure avec success/data
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => ReservationModel.fromJson(json)).toList();
        } else if (jsonResponse is List) {
          // Cas où la réponse est une liste sans wrapper
          return jsonResponse
              .map((json) => ReservationModel.fromJson(json))
              .toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération des réservations du client: $e',
      );
      return null;
    }
  }

  // Créer une nouvelle réservation
  static Future<bool> createReservation(
    CreateReservationRequest request,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      debugPrint('Requête création réservation: $baseUrl/Reservation');
      debugPrint('Données: ${request.toJson()}');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Parser et logger la réponse en détail
      try {
        final responseData = json.decode(response.body);
        debugPrint('Response parsed: $responseData');

        if (responseData is Map) {
          debugPrint('Response keys: ${responseData.keys.toList()}');
          responseData.forEach((key, value) {
            debugPrint('  $key: $value (${value.runtimeType})');
          });
        }
      } catch (e) {
        debugPrint('Error parsing response: $e');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true || response.statusCode == 201;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la création de la réservation: $e');
      return false;
    }
  }

  // Créer une réservation avec paiement (tout-en-un)
  static Future<ReservationWithPaiementResponse?> reservationWithPaiement(
    ReservationWithPaiementRequest request,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation/reservation_with_paiement'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      debugPrint(
        'Requête réservation avec paiement: $baseUrl/Reservation/reservation_with_paiement',
      );
      debugPrint('Données: ${request.toJson()}');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('Response parsed: $jsonResponse');

        return ReservationWithPaiementResponse.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      debugPrint(
        'Erreur lors de la création de la réservation avec paiement: $e',
      );
      return null;
    }
  }

  // Valider un paiement (action caissier)
  static Future<bool> validatePayment(int paiementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/Paiement/validate/$paiementId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la validation du paiement: $e');
      return false;
    }
  }

  // Rejeter un paiement (action caissier)
  static Future<bool> rejectPayment(int paiementId, String raison) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/Paiement/reject/$paiementId'),
        headers: headers,
        body: jsonEncode({'raison': raison}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'];
      }
      return false;
    } catch (e) {
      print('Erreur lors du rejet du paiement: $e');
      return false;
    }
  }

  // ========== MÉTHODES AUTHENTIFICATION ==========

  // Authentifier un utilisateur
  static Future<AuthResponse?> authenticateUser(
    String emailOuTelephone,
    String motDePasse,
  ) async {
    try {
      final authRequest = AuthRequest(
        emailOuTelephone: emailOuTelephone,
        motDePasse: motDePasse,
      );

      debugPrint(
        'Requête d\'authentification vers: $baseUrl/Utilisateur/authentifier',
      );
      debugPrint('Corps de la requête: ${jsonEncode(authRequest.toJson())}');

      final response = await http.post(
        Uri.parse('$baseUrl/Utilisateur/authentifier'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(authRequest.toJson()),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse brute: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          debugPrint('JSON décodé avec succès');
          debugPrint('Success field: ${jsonResponse['success']}');

          if (jsonResponse['success'] == true) {
            debugPrint('Tentative de création de AuthResponse...');
            final authResponse = AuthResponse.fromJson(jsonResponse);
            debugPrint('AuthResponse créé avec succès');
            return authResponse;
          } else {
            debugPrint('API a retourné success=false');
          }
        } catch (jsonError) {
          debugPrint('Erreur lors du décodage JSON: $jsonError');
          debugPrint('Type d\'erreur JSON: ${jsonError.runtimeType}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'authentification: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // ========== MÉTHODES DESTINATION ==========

  // Récupérer les destinations avec pagination
  static Future<DestinationResponse?> getDestinations({
    int pageNumber = 1,
    int pageSize = 4,
    String? searchTerm,
    String? sortBy,
    bool sortDescending = false,
  }) async {
    try {
      final headers = await _getHeaders();

      // Construction de l'URL avec les paramètres de query
      final uri = Uri.parse('$baseUrl/Destination/paged').replace(
        queryParameters: {
          'PageNumber': pageNumber.toString(),
          'PageSize': pageSize.toString(),
          if (searchTerm != null && searchTerm.isNotEmpty)
            'SearchTerm': searchTerm,
          if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
          'SortDescending': sortDescending.toString(),
        },
      );

      debugPrint('Requête destinations vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse destinations: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final destinationResponse = DestinationResponse.fromJson(jsonResponse);
        debugPrint(
          'Destinations récupérées: ${destinationResponse.data.length} sur ${destinationResponse.totalCount}',
        );
        return destinationResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des destinations: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }

  // ========== MÉTHODES BUS ==========

  // Récupérer les informations d'un bus spécifique
  static Future<Bus?> getBusById(int idBus) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Bus/$idBus');

      debugPrint('Requête bus vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse bus: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final bus = Bus.fromJson(jsonResponse);
        debugPrint('Bus récupéré: ${bus.marques} - ${bus.numeroDePlaque}');
        return bus;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du bus: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }

  // ========== MÉTHODES RAFRAÎCHISSEMENT TOKEN ==========

  // Rafraîchir le token d'accès
  static Future<AuthResponse?> refreshToken(
    String refreshToken,
    String deviceInfo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Utilisateur/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
          'deviceInfo': deviceInfo,
        }),
      );

      debugPrint('Status code refresh token: ${response.statusCode}');
      debugPrint('Réponse refresh token: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final authResponse = AuthResponse.fromJson(jsonResponse);
          debugPrint('Token rafraîchi avec succès');
          return authResponse;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }

  // ========== MÉTHODES VOYAGE ==========

  // Récupérer tous les voyages
  static Future<List<Voyage>> getAllVoyages() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Voyage');

      debugPrint('Requête tous les voyages vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse voyages: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final voyages = jsonResponse
            .map((item) => Voyage.fromJson(item))
            .toList();
        debugPrint('Voyages récupérés: ${voyages.length}');
        return voyages;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des voyages: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return [];
    }
  }

  // Récupérer les voyages pour une destination spécifique
  static Future<List<Voyage>> getVoyagesByDestination(int idDestination) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Voyage/destination/$idDestination');

      debugPrint('Requête voyages vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse voyages: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final voyages = jsonResponse
            .map((item) => Voyage.fromJson(item))
            .toList();
        debugPrint('Voyages récupérés: ${voyages.length}');
        return voyages;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des voyages: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return [];
    }
  }
}
