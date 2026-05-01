import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:rusa/services/api_service.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/client_model.dart';
import 'cache_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1, minutes: 50);

  Future<void> initializeSession() async {
    debugPrint('Initialisation de la session...');
    final isValid = await isSessionValid();
    if (isValid) {
      debugPrint(
        'Session valide trouvée, vérification de la cohérence du client_id...',
      );

      // Migration: fix stale client_id=0
      await _migrateClientIdIfNeeded();

      await _startRefreshTimer();
    } else {
      debugPrint('Aucune session valide trouvée');
      await clearSession();
    }
  }

  Future<void> _migrateClientIdIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedClientId = prefs.getString('client_id');

      if (storedClientId == null || storedClientId == '0') {
        debugPrint('⚠️ client_id corrompu détecté, tentative de migration...');

        // Try to get valid client_id from cached AuthResponse
        final cachedAuth = await CacheService.getAuthResponse();
        if (cachedAuth != null) {
          final validClientId =
              (cachedAuth.utilisateur.idClient != null &&
                  cachedAuth.utilisateur.idClient! > 0)
              ? cachedAuth.utilisateur.idClient
              : (cachedAuth.client.idClient > 0
                    ? cachedAuth.client.idClient
                    : null);

          if (validClientId != null && validClientId > 0) {
            await prefs.setString('client_id', validClientId.toString());
            debugPrint(
              '✅ Migration réussie: client_id mis à jour à $validClientId',
            );

            // Also update Hive AuthResponse cache with corrected client
            final correctedAuth = AuthResponse(
              success: cachedAuth.success,
              message: cachedAuth.message,
              accessToken: cachedAuth.accessToken,
              refreshToken: cachedAuth.refreshToken,
              tokenType: cachedAuth.tokenType,
              expiresIn: cachedAuth.expiresIn,
              expiresAt: cachedAuth.expiresAt,
              utilisateur: cachedAuth.utilisateur,
              doitChangerMotDePasse: cachedAuth.doitChangerMotDePasse,
              nomRole: cachedAuth.nomRole,
              nomSociete: cachedAuth.nomSociete,
              acceptNotification: cachedAuth.acceptNotification,
              permissions: cachedAuth.permissions,
              roles: cachedAuth.roles,
              primaryRole: cachedAuth.primaryRole,
              client: Client(
                idClient: validClientId,
                nomClient: cachedAuth.client.nomClient,
                codeCons: cachedAuth.client.codeCons,
                telephone: cachedAuth.client.telephone,
                emailClient: cachedAuth.client.emailClient,
                genreClient: cachedAuth.client.genreClient,
                adresseClient: cachedAuth.client.adresseClient,
                statut: cachedAuth.client.statut,
                isActif: cachedAuth.client.isActif,
                idAxe: cachedAuth.client.idAxe,
                usages: cachedAuth.client.usages,
                usagesCount: cachedAuth.client.usagesCount,
              ),
              agent: cachedAuth.agent,
            );
            await CacheService.saveAuthResponse(correctedAuth);
            debugPrint('AuthResponse corrigé dans Hive');
          }
        }
      } else {
        debugPrint(
          'client_id valide trouvé: $storedClientId, aucune migration nécessaire',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la migration client_id: $e');
    }
  }

  Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      debugPrint('Sauvegarde des données d\'authentification...');
      final prefs = await SharedPreferences.getInstance();

      // PRIORITY: utilisateur.idClient is the actual client ID
      // The client object may be empty/0 for some user types
      final effectiveClientId = authResponse.effectiveClientId;
      debugPrint('Using effectiveClientId: $effectiveClientId');

      await prefs.setString('access_token', authResponse.accessToken ?? "");
      await prefs.setString('refresh_token', authResponse.refreshToken ?? "");
      await prefs.setString('token_type', authResponse.tokenType ?? "");
      await prefs.setInt('expires_in', authResponse.expiresIn);
      await prefs.setString('expires_at', authResponse.expiresAt ?? "");
      await prefs.setString(
        'user_id',
        authResponse.utilisateur.idUtilisateur.toString(),
      );
      await prefs.setString('client_id', effectiveClientId.toString());
      await prefs.setString('user_name', authResponse.utilisateur.nomComplet);
      await prefs.setString('user_email', authResponse.utilisateur.email);
      await prefs.setString('user_phone', authResponse.utilisateur.telephone);
      debugPrint(
        'Données d\'authentification sauvegardées avec succès (client_id: $effectiveClientId)',
      );

      // Also update the AuthResponse before caching
      final updatedAuth = AuthResponse(
        success: authResponse.success,
        message: authResponse.message,
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        tokenType: authResponse.tokenType,
        expiresIn: authResponse.expiresIn,
        expiresAt: authResponse.expiresAt,
        utilisateur: authResponse.utilisateur,
        doitChangerMotDePasse: authResponse.doitChangerMotDePasse,
        nomRole: authResponse.nomRole,
        nomSociete: authResponse.nomSociete,
        acceptNotification: authResponse.acceptNotification,
        permissions: authResponse.permissions,
        roles: authResponse.roles,
        primaryRole: authResponse.primaryRole,
        client: Client(
          idClient: effectiveClientId,
          nomClient: authResponse.client.nomClient,
          codeCons: authResponse.client.codeCons,
          telephone: authResponse.client.telephone,
          emailClient: authResponse.client.emailClient,
          genreClient: authResponse.client.genreClient,
          adresseClient: authResponse.client.adresseClient,
          statut: authResponse.client.statut,
          isActif: authResponse.client.isActif,
          idAxe: authResponse.client.idAxe,
          usages: authResponse.client.usages,
          usagesCount: authResponse.client.usagesCount,
        ),
        agent: authResponse.agent,
      );

      await CacheService.saveAuthResponse(updatedAuth);
      debugPrint('AuthResponse mise à jour et sauvegardée dans Hive');

      // Mettre aussi en cache le profil client dès le login
      // pour éviter d'attendre un appel ultérieur à getUserInfo().
      final fullName = authResponse.utilisateur.nomComplet.trim();
      final nameParts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final nom = nameParts.isNotEmpty ? nameParts.first : '';
      final postnom = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

      await CacheService.saveClient(
        ClientModel(
          id: authResponse.utilisateur.idUtilisateur,
          clientId: effectiveClientId,
          username: fullName,
          email: authResponse.utilisateur.email,
          nom: nom,
          postnom: postnom,
          telephone: authResponse.utilisateur.telephone,
          genre: authResponse.utilisateur.genre,
          statut: authResponse.utilisateur.statut,
          dateCreation: DateTime.now().toIso8601String(),
          idRole: authResponse.utilisateur.idRole ?? 0,
          idSociete: authResponse.utilisateur.idSociete,
          photoUrl: authResponse.utilisateur.photoUrl,
        ),
      );
      debugPrint('ClientModel sauvegardé dans Hive');

      await _startRefreshTimer();
    } catch (e) {
      debugPrint(
        'Erreur lors de la sauvegarde des données d\'authentification: $e',
      );
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final expiresAt = prefs.getString('expires_at');
      if (accessToken == null || refreshToken == null || expiresAt == null) {
        debugPrint('Token ou refresh token manquant');
        return false;
      }
      final expirationTime = DateTime.parse(expiresAt);
      final now = DateTime.now();
      if (now.isAfter(expirationTime)) {
        debugPrint('Token expiré, tentative de rafraîchissement...');
        final refreshed = await _refreshToken();
        return refreshed;
      }
      debugPrint('Session valide');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la validation de session: $e');
      return false;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) {
        debugPrint('Refresh token non disponible');
        return false;
      }
      final deviceInfo = _getDeviceInfo();
      debugPrint('Tentative de rafraîchissement du token...');
      final authResponse = await ApiService.refreshToken(
        refreshToken,
        deviceInfo,
      );
      if (authResponse != null) {
        await saveAuthData(authResponse);
        debugPrint('Token rafraîchi avec succès');
        return true;
      } else {
        debugPrint('Échec du rafraîchissement token');
        await clearSession();
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      await clearSession();
      return false;
    }
  }

  Future<void> _startRefreshTimer() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      debugPrint('Rafraîchissement automatique du token...');
      final success = await _refreshToken();
      if (!success) {
        debugPrint('Échec du rafraîchissement automatique, arrêt du timer');
        timer.cancel();
      }
    });
    debugPrint(
      'Timer de rafraîchissement démarré (intervalle: ${_refreshInterval.inMinutes} minutes)',
    );
  }

  String _getDeviceInfo() {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      } else {
        return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention des infos appareil: $e');
      return 'Unknown Device';
    }
  }

  Future<Map<String, String>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? clientId = prefs.getString('client_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');

      debugPrint('=== GET USER INFO ===');
      debugPrint('Initial - user_id: $userId, client_id: $clientId');

      // Migration: If client_id is 0, fix from AuthResponse cache
      if (clientId == null || clientId == '0') {
        debugPrint(
          'client_id invalid, attempting migration from cached AuthResponse...',
        );
        final cachedAuth = await CacheService.getAuthResponse();
        if (cachedAuth != null) {
          final extractedClientId =
              cachedAuth.utilisateur.idClient ??
              (cachedAuth.client.idClient > 0
                  ? cachedAuth.client.idClient
                  : null);
          if (extractedClientId != null && extractedClientId > 0) {
            clientId = extractedClientId.toString();
            await prefs.setString('client_id', clientId);
            debugPrint('✅ Migrated client_id from cache: $clientId');
          }
        }
      }

      // Final validation
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ user_id manquant dans getUserInfo');
        return null;
      }

      // Forcer la déconnexion ici causait un logout inattendu sur certains écrans
      // (notamment profil) quand client_id est absent/0.
      // On ne nettoie plus la session; on fournit une valeur neutre.
      if (clientId == null || clientId.isEmpty) {
        clientId = '0';
      }

      debugPrint('✅ Final - user_id: $userId, client_id: $clientId');

      final userInfo = {
        'id': userId,
        'client_id': clientId,
        'name': userName ?? '',
        'email': userEmail ?? '',
        'phone': userPhone ?? '',
      };

      // Update Hive cache uniquement si client_id valide (> 0)
      final parsedClientId = int.tryParse(clientId) ?? 0;
      if (parsedClientId > 0) {
        await CacheService.saveClient(
          ClientModel(
            id: int.tryParse(userId) ?? 0,
            clientId: parsedClientId,
            username: userName ?? '',
            email: userEmail ?? '',
            nom: '',
            postnom: '',
            telephone: userPhone ?? '',
            genre: 'Masculin',
            statut: true,
            dateCreation: DateTime.now().toIso8601String(),
            idRole: 6,
            idSociete: 1,
            photoUrl: null,
          ),
        );
      }
      return userInfo;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos utilisateur: $e');
      return null;
    }
  }

  Future<String?> getClientId() async {
    try {
      final isValid = await isSessionValid();
      if (!isValid) return null;
      final prefs = await SharedPreferences.getInstance();
      var clientId = prefs.getString('client_id');

      // Recovery if client_id is 0 or null
      if (clientId == null || clientId == '0') {
        debugPrint(
          'getClientId: client_id is $clientId, attempting recovery...',
        );
        final cachedAuth = await CacheService.getAuthResponse();
        if (cachedAuth != null) {
          final recovered =
              (cachedAuth.utilisateur.idClient != null &&
                  cachedAuth.utilisateur.idClient! > 0)
              ? cachedAuth.utilisateur.idClient
              : (cachedAuth.client.idClient > 0
                    ? cachedAuth.client.idClient
                    : null);
          if (recovered != null) {
            clientId = recovered.toString();
            await prefs.setString('client_id', clientId);
            debugPrint('Recovered client_id in getClientId: $clientId');
          }
        }
      }

      if (clientId == null || clientId == '0') {
        final cachedClient = await CacheService.getClient();
        if (cachedClient != null && cachedClient.clientId > 0) {
          clientId = cachedClient.clientId.toString();
          await prefs.setString('client_id', clientId);
          debugPrint(
            'Recovered client_id from Hive Client in getClientId: $clientId',
          );
        }
      }

      return clientId;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'ID client: $e');
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('Déconnexion de l\'utilisateur...');
    try {
      await _callLogoutApi();
    } catch (e) {
      debugPrint('Erreur lors de l\'appel API de déconnexion: $e');
    }
    _refreshTimer?.cancel();
    await clearSession();
  }

  Future<void> _callLogoutApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/Utilisateur/deconnecter'),
          headers: headers,
          body: jsonEncode({
            'supprimerTousLesDevices': true,
            'deviceId': '',
            'idUserDevice': 0,
            'fcmToken': '',
          }),
        );
        debugPrint('Status code déconnexion API: ${response.statusCode}');
        debugPrint('Réponse déconnexion API: ${response.body}');
        if (response.statusCode == 200) {
          debugPrint('Déconnexion API réussie');
        }
      }
    } catch (e) {
      debugPrint('Erreur appel API déconnexion: $e');
      rethrow;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('access_token'),
        prefs.remove('refresh_token'),
        prefs.remove('token_expires_at'),
        prefs.remove('user_id'),
        prefs.remove('client_id'),
        prefs.remove('user_name'),
        prefs.remove('user_email'),
        prefs.remove('user_phone'),
        prefs.remove('auth_data'),
      ]);
      await CacheService.clearCache();
      _refreshTimer?.cancel();
      debugPrint('Session et cache vidés avec succès');
    } catch (e) {
      debugPrint('Erreur lors du vidage de la session: $e');
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    debugPrint('SessionService disposed');
  }
}
