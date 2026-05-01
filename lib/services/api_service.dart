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
import '../models/reservation_api_model.dart';
import 'session_service.dart';

class ApiService {
  static const String baseUrl = 'https://dev-rusatravel.asdc-rdc.org/api';
  // Pour le développement: static const String baseUrl = 'https://localhost:7110/api';

  // Méthode pour ajouter le token d'authentification aux requêtes
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        if (requiresAuth) {
          throw Exception('Token d\'authentification manquant');
        }
        return {'Content-Type': 'application/json', 'Accept': 'application/json'};
      }

      debugPrint('Token récupéré pour l\'authentification');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      rethrow;
    }
  }

  // ========== MÉTHODES CLIENT ==========

  static Future<http.Response> _postClientRegister({
    required String nomClient,
    required String emailClient,
    required String telephone,
    required String adresseClient,
    required String genreClient,
    required String province,
    required String ville,
    required String commune,
    required String avenue,
    required String numero,
    bool acceptTerms = true,
    bool subscribeNewsletter = true,
    bool marketingConsent = true,
  }) async {
    final headers = await _getHeaders(requiresAuth: false);
    return http.post(
      Uri.parse('$baseUrl/Client/register'),
      headers: headers,
      body: jsonEncode({
        'nomClient': nomClient,
        'emailClient': emailClient,
        'telephone': telephone,
        'adresseClient': adresseClient,
        'genreClient': genreClient,
        'province': province,
        'ville': ville,
        'commune': commune,
        'avenue': avenue,
        'numero': numero,
        'acceptTerms': acceptTerms,
        'subscribeNewsletter': subscribeNewsletter,
        'marketingConsent': marketingConsent,
      }),
    );
  }

  // Enregistrer un nouveau client
  static Future<Map<String, dynamic>?> registerClient({
    required String nomClient,
    required String emailClient,
    required String telephone,
    required String adresseClient,
    required String genreClient,
    required String province,
    required String ville,
    required String commune,
    required String avenue,
    required String numero,
    bool acceptTerms = true,
    bool subscribeNewsletter = true,
    bool marketingConsent = true,
  }) async {
    try {
      final response = await _postClientRegister(
        nomClient: nomClient,
        emailClient: emailClient,
        telephone: telephone,
        adresseClient: adresseClient,
        genreClient: genreClient,
        province: province,
        ville: ville,
        commune: commune,
        avenue: avenue,
        numero: numero,
        acceptTerms: acceptTerms,
        subscribeNewsletter: subscribeNewsletter,
        marketingConsent: marketingConsent,
      );

      debugPrint('Requête inscription client: $baseUrl/Client/register');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse inscription: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription client: $e');
      return null;
    }
  }

  /// Même inscription que [registerClient], avec code HTTP et corps pour afficher les erreurs (ex. caisse).
  static Future<({int statusCode, Map<String, dynamic>? body})>
      registerClientWithStatus({
    required String nomClient,
    required String emailClient,
    required String telephone,
    required String adresseClient,
    required String genreClient,
    required String province,
    required String ville,
    required String commune,
    required String avenue,
    required String numero,
    bool acceptTerms = true,
    bool subscribeNewsletter = false,
    bool marketingConsent = false,
  }) async {
    try {
      final response = await _postClientRegister(
        nomClient: nomClient,
        emailClient: emailClient,
        telephone: telephone,
        adresseClient: adresseClient,
        genreClient: genreClient,
        province: province,
        ville: ville,
        commune: commune,
        avenue: avenue,
        numero: numero,
        acceptTerms: acceptTerms,
        subscribeNewsletter: subscribeNewsletter,
        marketingConsent: marketingConsent,
      );

      debugPrint('Inscription client (caisse): ${response.statusCode}');
      debugPrint('Corps: ${response.body}');

      Map<String, dynamic>? map;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}

      return (statusCode: response.statusCode, body: map);
    } catch (e) {
      debugPrint('Erreur inscription client (caisse): $e');
      return (statusCode: 0, body: null);
    }
  }

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

  // Dashboard caissier
  static Future<Map<String, dynamic>?> getCaissierDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/CaissierDashboard'),
        headers: headers,
      );

      debugPrint('Requête dashboard caissier: $baseUrl/CaissierDashboard');
      debugPrint('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du dashboard caissier: $e');
      return null;
    }
  }

  /// Liste des clients (`GET /api/Client`) — réservé aux rôles autorisés (token requis).
  static Future<List<Client>?> getAllClients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Client'),
        headers: headers,
      );

      debugPrint('Requête clients: $baseUrl/Client — ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => Client.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      debugPrint('getAllClients: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Erreur getAllClients: $e');
      return null;
    }
  }

  /// Détail d'un client (`GET /api/Client/{id}`).
  static Future<Client?> getClientById(int idClient) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Client/$idClient'),
        headers: headers,
      );

      debugPrint('Requête client/$idClient: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Client.fromJson(decoded);
        }
      }
      debugPrint('getClientById: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Erreur getClientById: $e');
      return null;
    }
  }

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
  static Future<List<Reservation>?> getReservationsByClient(
    int idClient,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/Reservation/client/$idClient'), headers: headers)
          .timeout(const Duration(seconds: 20));

      debugPrint(
        'Requête réservations client: $baseUrl/Reservation/client/$idClient',
      );
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Vérifier si la réponse est vide ou null
        if (jsonResponse == null) {
          debugPrint('Réponse API null');
          return [];
        }

        if (jsonResponse is List) {
          // Si la réponse est directement une liste
          debugPrint(
            'Réponse de type List avec ${jsonResponse.length} éléments',
          );
          return jsonResponse
              .map((json) => Reservation.fromJson(json))
              .toList();
        } else if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse['success'] == true) {
            // Si la réponse a une structure avec success/data
            final List<dynamic> data = jsonResponse['data'] ?? [];
            debugPrint('Réponse avec success=true, ${data.length} éléments');
            return data.map((json) => Reservation.fromJson(json)).toList();
          } else {
            debugPrint('Réponse Map mais success=false ou absent');
            return [];
          }
        } else {
          debugPrint('Type de réponse non géré: ${jsonResponse.runtimeType}');
          return [];
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
        headers: await _getHeaders(requiresAuth: false),
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
        headers: await _getHeaders(requiresAuth: false),
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

          final accessTokenValue = authResponse.accessToken?.trim() ?? '';
          final refreshTokenValue = authResponse.refreshToken?.trim() ?? '';
          final expiresAtValue = authResponse.expiresAt?.trim() ?? '';

          // Contrat API du projet: on accepte expiresIn/ids même à 0
          // tant que les tokens sont présents.
          if (accessTokenValue.isEmpty || refreshTokenValue.isEmpty) {
            debugPrint('Refresh token refusé: tokens manquants');
            return null;
          }

          final hasValidExpiresIn = authResponse.expiresIn > 0;
          final parsedExpiresAt = expiresAtValue.isNotEmpty
              ? DateTime.tryParse(expiresAtValue)
              : null;
          final hasValidExpiresAt =
              parsedExpiresAt != null &&
              parsedExpiresAt.isAfter(DateTime.now());

          // Le backend doit fournir au moins un indicateur d'expiration valide.
          if (!hasValidExpiresIn && !hasValidExpiresAt) {
            debugPrint(
              'Refresh token refusé: expiration invalide '
              '(expiresIn=${authResponse.expiresIn}, expiresAt="$expiresAtValue")',
            );
            return null;
          }

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

  // Récupérer un voyage par son ID
  static Future<Voyage?> getVoyageById(int idVoyage) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Voyage/$idVoyage');

      debugPrint('Requête voyage vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse voyage: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final voyage = Voyage.fromJson(jsonResponse);
        debugPrint(
          'Voyage récupéré: ${voyage.villeDepart} -> ${voyage.villeArrivee}',
        );
        return voyage;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du voyage: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }

  // Récupérer le billet d'une réservation
  static Future<ReservationWithPaiementResponse?> getBilletByReservation(
    int idReservation,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Billet/reservation/$idReservation');

      debugPrint('Requête billet vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse billet: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // L'API retourne une liste, prendre le premier élément
        if (jsonResponse is List) {
          if (jsonResponse.isNotEmpty) {
            dynamic first = jsonResponse.first;
            if (first is Map<String, dynamic>) {
              debugPrint('Billet récupéré (premier élément de la liste)');
              return _buildReservationWithPaiementFromFlatObject(first);
            } else {
              debugPrint('Élément de liste inattendu: ${first.runtimeType}');
              return null;
            }
          } else {
            debugPrint('Liste de billets vide');
            return null;
          }
        } else if (jsonResponse is Map<String, dynamic>) {
          // Au cas où l'API changerait et retournerait un objet unique
          return _buildReservationWithPaiementFromFlatObject(jsonResponse);
        } else {
          debugPrint(
            'Format de réponse inattendu: ${jsonResponse.runtimeType}',
          );
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du billet: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }

  // Scanner un billet via QR code (endpoint caissier)
  static Future<ReservationWithPaiementResponse?> getBilletByQrCode(
    String qrCode,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/Billet/qrcode/${Uri.encodeComponent(qrCode)}');

      debugPrint('Requête billet par QR vers: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('Status code billet QR: ${response.statusCode}');
      debugPrint('Réponse billet QR: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse is List) {
          if (jsonResponse.isEmpty) return null;
          final first = jsonResponse.first;
          if (first is Map<String, dynamic>) {
            return _buildReservationWithPaiementFromFlatObject(first);
          }
          return null;
        }

        if (jsonResponse is Map<String, dynamic>) {
          return _buildReservationWithPaiementFromFlatObject(jsonResponse);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur scan billet QR: $e');
      return null;
    }
  }

  // Helper: construit ReservationWithPaiementResponse à partir d'un objet plat (format API Billet/reservation/{id})
  static ReservationWithPaiementResponse
  _buildReservationWithPaiementFromFlatObject(Map<String, dynamic> data) {
    //extraire paiement si présent, sinon construire un PaiementData par défaut à partir des champs disponibles
    PaiementData paiement;
    if (data.containsKey('paiement') &&
        data['paiement'] is Map<String, dynamic>) {
      paiement = PaiementData.fromJson(data['paiement']);
    } else {
      // Construire PaiementData à partir des champs de premier niveau (comme dans la réponse API)
      paiement = PaiementData(
        idPaiement: data['idPaiement'] ?? 0,
        montantAPaye: (data['montantAPaye'] ?? data['prixVoyage'] ?? 0)
            .toDouble(),
        montantPaye: (data['montantPaye'] ?? data['prixVoyage'] ?? 0)
            .toDouble(),
        resteAPaye: (data['resteAPaye'] ?? 0).toDouble(),
        methodePaiement: data['methodePaiement'] ?? 'Mobile Money',
        referenceTransaction: data['referenceTransaction'] ?? '',
        statut: data['statut'] ?? true,
        dateCreation: data['dateCreation'] ?? '',
        dateEmissionBillet:
            data['dateEmissionBillet'] ?? data['dateCreation'] ?? '',
        idBilletEmis: data['idBilletEmis'] ?? data['id'] ?? 0,
        idReservation: data['idReservation'] ?? 0,
        idSociete: data['idSociete'] ?? 1,
        estComplet: data['estComplet'] ?? true,
        estPartiel: data['estPartiel'] ?? false,
      );
    }

    // Extraire billet si présent, sinon construire un BilletData à partir des champs de premier niveau
    BilletData billet;
    if (data.containsKey('billet') && data['billet'] is Map<String, dynamic>) {
      billet = BilletData.fromJson(data['billet']);
    } else {
      billet = BilletData(
        id: data['id'] ?? 0,
        qrCode: data['qrCode'] ?? '',
        dateGeneration: data['dateGeneration'] ?? data['dateCreation'] ?? '',
        idReservation: data['idReservation'] ?? 0,
        idClient: data['idClient'] ?? 1,
        idSociete: data['idSociete'] ?? 1,
        urlBillet: data['urlBillet'] ?? '',
      );
    }

    // Construire ReservationData à partir des champs de premier niveau
    ReservationData reservation = ReservationData(
      idReservation: data['idReservation'] ?? 0,
      idUtilisateur: data['idUtilisateur'] ?? 0,
      idClient: data['idClient'] ?? 1,
      idVoyage: data['idVoyage'] ?? 0,
      statutReservation: data['statutReservation'] ?? '',
      statut: data['statut'] ?? false,
      dateReservation: data['dateReservation'] ?? '',
      idSociete: data['idSociete'] ?? 1,
      dateCreation: data['dateCreation'] ?? '',
      dateModification: data['dateModification'],
      nomUtilisateur: data['nomUtilisateur'],
      emailUtilisateur: data['emailUtilisateur'],
      nomClient: data['nomClient'],
      prenomClient: data['prenomClient'],
      telephoneClient: data['telephoneClient'],
      dateVoyage: data['dateVoyage'],
      heureVoyage: data['heureVoyage'] != null
          ? _parseHeureVoyage(data['heureVoyage'])
          : null,
      prixVoyage: (data['prixVoyage'] ?? 0).toDouble(),
      numeroBus: data['numeroBus'],
      villeDepart: data['villeDepart'],
      villeArrivee: data['villeArrivee'],
    );

    return ReservationWithPaiementResponse(
      reservation: reservation,
      paiement: paiement,
      billet: billet,
      transactionId: data['transactionId'] ?? 'N/A',
      statut: data['statut'] ?? 'Succes',
      message: data['message'] ?? 'Billet récupéré',
      dateCreation: data['dateCreation'] ?? '',
    );
  }

  // Helper: parsing heureVoyage string vers HeureVoyage
  static HeureVoyage? _parseHeureVoyage(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;
        return HeureVoyage(
          ticks: 0,
          days: 0,
          hours: h,
          milliseconds: 0,
          minutes: m,
          seconds: s,
          totalDays: 0,
          totalHours: h.toDouble(),
          totalMilliseconds: 0,
          totalMinutes: m.toDouble(),
          totalSeconds: s.toDouble(),
        );
      }
      return null;
    }
    if (value is Map<String, dynamic>) {
      // Si l'API renvoie un objet HeureVoyage (rare), utiliser fromJson
      try {
        return HeureVoyage.fromJson(value);
      } catch (e) {
        debugPrint('Erreur parsing HeureVoyage from map: $e');
        return null;
      }
    }
    return null;
  }
}
