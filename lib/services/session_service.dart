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
      debugPrint('Session valide trouvée, démarrage du rafraîchissement automatique');
      await _startRefreshTimer();
    } else {
      debugPrint('Aucune session valide trouvée');
      await clearSession();
    }
  }

  Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      debugPrint('Sauvegarde des données d\'authentification...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authResponse.accessToken ?? "");
      await prefs.setString('refresh_token', authResponse.refreshToken ?? "");
      await prefs.setString('token_type', authResponse.tokenType ?? "");
      await prefs.setInt('expires_in', authResponse.expiresIn);
      await prefs.setString('expires_at', authResponse.expiresAt ?? "");
      await prefs.setString('user_id', authResponse.utilisateur.idUtilisateur.toString());
      await prefs.setString('client_id', authResponse.client.idClient.toString());
      await prefs.setString('user_name', authResponse.utilisateur.nomComplet);
      await prefs.setString('user_email', authResponse.utilisateur.email);
      await prefs.setString('user_phone', authResponse.utilisateur.telephone);
      debugPrint('Données d\'authentification sauvegardées avec succès');
      await CacheService.saveAuthResponse(authResponse);
      debugPrint('AuthResponse sauvegardée dans Hive avec succès');
      await _startRefreshTimer();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des données d\'authentification: $e');
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
      final authResponse = await ApiService.refreshToken(refreshToken, deviceInfo);
      if (authResponse != null) {
        await saveAuthData(authResponse);
        debugPrint('Token rafraîchi avec succès');
        return true;
      } else {
        debugPrint('Échec du rafraîchissement du token');
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
    debugPrint('Timer de rafraîchissement démarré (intervalle: ${_refreshInterval.inMinutes} minutes)');
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
      final userId = prefs.getString('user_id');
      final clientId = prefs.getString('client_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');

      if (userId == null || clientId == null) {
        final isValid = await isSessionValid();
        if (!isValid) return null;
        return getUserInfo();
      }

      debugPrint('=== DEBUG SESSION (PREFS) ===');
      debugPrint('user_id: $userId');
      debugPrint('client_id: $clientId');
      debugPrint('user_name: $userName');
      debugPrint('user_email: $userEmail');
      debugPrint('user_phone: $userPhone');

      final userInfo = {
        'id': userId,
        'client_id': clientId,
        'name': userName ?? '',
        'email': userEmail ?? '',
        'phone': userPhone ?? '',
      };
      await CacheService.saveClient(ClientModel(
        id: int.tryParse(userId) ?? 0,
        clientId: int.tryParse(clientId) ?? 0,
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
      ));
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
      return prefs.getString('client_id');
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
