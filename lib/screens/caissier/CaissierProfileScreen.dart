import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/screens/client/EditProfileScreen.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/widgets/app_feedback.dart';
import 'package:rusa/screens/legal/legal_document_screen.dart';
import 'package:rusa/widgets/password_change_reminder.dart';
import 'package:rusa/utils/account_deletion_helper.dart';
/// Profil caissier / agent : même structure que [ProfileScreen], données issues de [AuthResponse].
class CaissierProfileScreen extends StatefulWidget {
  const CaissierProfileScreen({super.key});

  @override
  State<CaissierProfileScreen> createState() => _CaissierProfileScreenState();
}

class _CaissierProfileScreenState extends State<CaissierProfileScreen> {
  AuthResponse? _auth;

  bool _pauseNotifications = true;
  bool _darkMode = false;

  ImageProvider? _buildProfileImageProvider(String? rawPhoto) {
    final value = rawPhoto?.trim() ?? '';
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    try {
      final cleaned = value.contains('base64,')
          ? value.split('base64,').last
          : value;
      final bytes = base64Decode(cleaned);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  String? _effectivePhotoUrl(AuthResponse auth) {
    final u = auth.utilisateur.photoUrl?.trim() ?? '';
    if (u.isNotEmpty) return auth.utilisateur.photoUrl;
    final a = auth.agent?.photoUrl?.trim() ?? '';
    if (a.isNotEmpty) return auth.agent!.photoUrl;
    return null;
  }

  String _displayName(AuthResponse auth) {
    final n = auth.utilisateur.nomComplet.trim();
    if (n.isNotEmpty) return n;
    final an = auth.agent?.nomComplet.trim() ?? '';
    if (an.isNotEmpty) return an;
    return auth.nomRole.trim().isNotEmpty ? auth.nomRole : 'Utilisateur';
  }

  String _displayEmail(AuthResponse auth) {
    final e = auth.utilisateur.email.trim();
    if (e.isNotEmpty) return e;
    return auth.agent?.emailAgent?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _auth = CacheService.getAuthResponseSync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAuth());
  }

  Future<void> _refreshAuth() async {
    final auth = await CacheService.getAuthResponse();
    if (!mounted) return;
    if (auth != null) {
      setState(() => _auth = auth);
    }
  }

  Future<void> _refreshAuthAfterEdit(int id) async {
    try {
      final cachedAuth = await CacheService.getAuthResponse();
      final freshUser = await ApiService.getUtilisateurById(id);
      if (cachedAuth != null && freshUser != null) {
        final map = cachedAuth.toJson();
        map['utilisateur'] = freshUser.toJson();
        final updated = AuthResponse.fromJson(map);
        await CacheService.saveAuthResponse(updated);
        if (mounted) setState(() => _auth = updated);
        return;
      }
    } catch (_) {}
    await _refreshAuth();
  }

  Future<void> _openEditProfile() async {
    final id = _auth?.utilisateur.idUtilisateur ?? 0;
    if (id <= 0) {
      AppFeedback.showError(context, 'Utilisateur introuvable.');
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          idUtilisateur: id,
          initialUser: _auth?.utilisateur,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _refreshAuthAfterEdit(id);
      AppFeedback.showSuccess(context, 'Profil mis à jour avec succès.');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                ),
                SizedBox(height: 16),
                Text(
                  'Déconnexion...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await SessionService().logout();

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0D0D0D);
    const cardColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const subtitleColor = Colors.white54;
    const accentGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const PasswordChangeReminder(
              margin: EdgeInsets.only(bottom: 16),
            ),
            _buildCard(cardColor, [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF00E676),
                  backgroundImage: _auth != null
                      ? _buildProfileImageProvider(
                          _effectivePhotoUrl(_auth!),
                        )
                      : null,
                  child:
                      _auth == null ||
                          _buildProfileImageProvider(
                                _effectivePhotoUrl(_auth!),
                              ) ==
                              null
                      ? const Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 28,
                        )
                      : null,
                ),
                title: Text(
                  _auth != null ? _displayName(_auth!) : 'Utilisateur',
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  _auth == null
                      ? 'Chargement du profil…'
                      : (_displayEmail(_auth!).isEmpty
                            ? _auth!.nomRole
                            : _displayEmail(_auth!)),
                  style: const TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: subtitleColor,
                ),
                onTap: _openEditProfile,
              ),
            ]),
            if (_auth != null) ...[
              const SizedBox(height: 16),
              _buildCard(cardColor, _buildAgentInfoTiles(_auth!, subtitleColor)),
            ],
            const SizedBox(height: 16),
            _buildCard(cardColor, [
              _buildSwitchTile(
                icon: Icons.notifications_off_outlined,
                title: 'Pause notifications',
                value: _pauseNotifications,
                activeColor: accentGreen,
                onChanged: (val) => setState(() => _pauseNotifications = val),
              ),
              _buildActionTile(
                icon: Icons.tune,
                title: 'Paramètres généraux',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard(cardColor, [
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Mode sombre',
                value: _darkMode,
                activeColor: accentGreen,
                onChanged: (val) => setState(() => _darkMode = val),
              ),
              _buildActionTile(
                icon: Icons.translate,
                title: 'Langue',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard(cardColor, [
              _buildActionTile(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () => LegalDocumentScreen.open(
                  context,
                  LegalDocumentType.faq,
                ),
              ),
              _buildActionTile(
                icon: Icons.info_outline,
                title: 'Conditions d\'utilisation',
                onTap: () => LegalDocumentScreen.open(
                  context,
                  LegalDocumentType.terms,
                ),
              ),
              _buildActionTile(
                icon: Icons.person_outline,
                title: 'Politique utilisateur',
                onTap: () => LegalDocumentScreen.open(
                  context,
                  LegalDocumentType.privacy,
                ),
              ),
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _auth != null && _auth!.utilisateur.idUtilisateur > 0
                    ? () => AccountDeletionHelper.openDeletionPage(
                          context,
                          userId: _auth!.utilisateur.idUtilisateur,
                        )
                    : null,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Supprimer mon compte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAgentInfoTiles(AuthResponse auth, Color subtitleColor) {
    final agent = auth.agent;
    final rows = <Widget>[
      _infoRow(
        label: 'Rôle',
        value: auth.nomRole.trim().isEmpty ? '—' : auth.nomRole,
        subtitleColor: subtitleColor,
      ),
      if (auth.nomSociete.trim().isNotEmpty)
        _infoRow(
          label: 'Société',
          value: auth.nomSociete,
          subtitleColor: subtitleColor,
        ),
    ];

    if (agent != null) {
      final mat = agent.matricule?.trim() ?? '';
      if (mat.isNotEmpty) {
        rows.add(_infoRow(
          label: 'Matricule',
          value: mat,
          subtitleColor: subtitleColor,
        ));
      }
      final fn = agent.fonction?.trim() ?? '';
      if (fn.isNotEmpty) {
        rows.add(_infoRow(
          label: 'Fonction',
          value: fn,
          subtitleColor: subtitleColor,
        ));
      }
      final zone = agent.zone?.trim() ?? '';
      if (zone.isNotEmpty) {
        rows.add(_infoRow(
          label: 'Zone',
          value: zone,
          subtitleColor: subtitleColor,
        ));
      }
    }

    final tel = auth.utilisateur.telephone.trim().isNotEmpty
        ? auth.utilisateur.telephone
        : (agent?.telephoneAgent?.trim() ?? '');
    if (tel.isNotEmpty) {
      rows.add(_infoRow(
        label: 'Téléphone',
        value: tel,
        subtitleColor: subtitleColor,
      ));
    }

    return rows;
  }

  Widget _infoRow({
    required String label,
    required String value,
    required Color subtitleColor,
  }) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(color: subtitleColor, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white54,
        size: 22,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: activeColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.white24,
      ),
    );
  }
}
