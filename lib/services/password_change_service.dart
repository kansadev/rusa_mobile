import 'package:rusa/models/auth_models.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise et lit l'obligation de changer le mot de passe après connexion.
class PasswordChangeService {
  PasswordChangeService._();

  static const _keyMustChange = 'must_change_password';
  static const _keyUserId = 'must_change_password_user_id';

  static bool requiresChange(AuthResponse auth) {
    return auth.doitChangerMotDePasse == true ||
        auth.utilisateur.doitChangerMotDePasse;
  }

  static Future<void> persistFromAuth(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, auth.utilisateur.idUtilisateur);
    await prefs.setBool(_keyMustChange, requiresChange(auth));
  }

  static Future<bool> isChangeRequired() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId =
        int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
    final storedUserId = prefs.getInt(_keyUserId);

    if (storedUserId != null &&
        currentUserId > 0 &&
        storedUserId != currentUserId) {
      await prefs.setBool(_keyMustChange, false);
      return false;
    }

    if (prefs.getBool(_keyMustChange) == true) return true;

    final auth =
        CacheService.getAuthResponseSync() ??
        await CacheService.getAuthResponse();
    if (auth != null && requiresChange(auth)) {
      await persistFromAuth(auth);
      return true;
    }
    return false;
  }

  static Future<void> markChanged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMustChange, false);

    final auth = await CacheService.getAuthResponse();
    if (auth == null) return;

    final updated = AuthResponse(
      success: auth.success,
      message: auth.message,
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      tokenType: auth.tokenType,
      expiresIn: auth.expiresIn,
      expiresAt: auth.expiresAt,
      utilisateur: auth.utilisateur.copyWith(doitChangerMotDePasse: false),
      doitChangerMotDePasse: false,
      nomRole: auth.nomRole,
      nomSociete: auth.nomSociete,
      acceptNotification: auth.acceptNotification,
      permissions: auth.permissions,
      roles: auth.roles,
      primaryRole: auth.primaryRole,
      client: auth.client,
      agent: auth.agent,
    );
    await CacheService.saveAuthResponse(updated);
  }
}

class PasswordChangeResult {
  final bool ok;
  final String? errorMessage;

  const PasswordChangeResult({required this.ok, this.errorMessage});
}
