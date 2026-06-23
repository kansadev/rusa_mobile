import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/client_model.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/screens/client/ClientContactsScreen.dart';
import 'package:rusa/screens/client/EditProfileScreen.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/services/location_service.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/screens/legal/legal_document_screen.dart';
import 'package:rusa/widgets/password_change_reminder.dart';
import 'package:rusa/utils/account_deletion_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ClientModel? _client;
  bool _isLoading = false;

  // États pour les interrupteurs (Switches)
  bool _pauseNotifications = true;
  bool _darkMode = false;
  bool _filterByMyCity = false;
  bool _resolvingCity = false;
  String? _myCity;

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

  @override
  void initState() {
    super.initState();
    _loadCityFilterPref();
    // Charger les données en arrière-plan sans bloquer l'UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final cachedAuth = await CacheService.getAuthResponse();
    if (cachedAuth != null && mounted) {
      final fullName = cachedAuth.utilisateur.nomComplet.trim();
      final nameParts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final nom = nameParts.isNotEmpty ? nameParts.first : '';
      final postnom = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      final username = fullName.isNotEmpty ? fullName : 'Utilisateur';

      setState(() {
        _client = ClientModel(
          id: cachedAuth.utilisateur.idUtilisateur,
          clientId: cachedAuth.effectiveClientId,
          username: username,
          email: cachedAuth.utilisateur.email,
          nom: nom,
          postnom: postnom,
          telephone: cachedAuth.utilisateur.telephone,
          genre: cachedAuth.utilisateur.genre,
          statut: cachedAuth.utilisateur.statut,
          dateCreation: DateTime.now().toIso8601String(),
          idRole: cachedAuth.utilisateur.idRole ?? 6,
          idSociete: cachedAuth.utilisateur.idSociete,
          photoUrl: cachedAuth.utilisateur.photoUrl,
        );
        _isLoading = false;
      });
      return;
    }

    // Fallback session (sans provoquer de déconnexion automatique)
    final session = SessionService();
    final userData = await session.getUserInfo();
    if (!mounted) return;

    if (userData != null) {
      final name = userData['name'] ?? '';
      final nameParts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      setState(() {
        _client = ClientModel(
          id: int.tryParse(userData['id'] ?? '0') ?? 0,
          clientId: int.tryParse(userData['client_id'] ?? '0') ?? 0,
          username: name,
          email: userData['email'] ?? '',
          nom: nameParts.isNotEmpty ? nameParts.first : '',
          postnom: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
          telephone: userData['phone'] ?? '',
          genre: 'Masculin',
          statut: true,
          dateCreation: DateTime.now().toIso8601String(),
          idRole: 6,
          idSociete: 1,
          photoUrl: null,
        );
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCityFilterPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _filterByMyCity = prefs.getBool('filter_by_my_city') ?? false;
        _myCity = prefs.getString('my_city');
      });
    } catch (_) {}
  }

  Future<void> _onToggleCityFilter(bool value) async {
    if (!value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('filter_by_my_city', false);
      if (!mounted) return;
      setState(() => _filterByMyCity = false);
      return;
    }

    // Activation : résoudre la ville via la géolocalisation.
    setState(() => _resolvingCity = true);
    final result = await LocationService.getCurrentCity();
    if (!mounted) return;
    setState(() => _resolvingCity = false);

    if (!result.success || result.city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Localisation indisponible.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final city = result.city!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_by_my_city', true);
    await prefs.setString('my_city', city);
    if (!mounted) return;
    setState(() {
      _filterByMyCity = true;
      _myCity = city;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtre activé : voyages au départ de $city'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final id = _client?.id ?? 0;
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur introuvable.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(idUtilisateur: id),
      ),
    );
    if (updated == true && mounted) {
      setState(() => _isLoading = true);
      // Rafraîchir le cache d'auth avec les données fraîches du serveur,
      // afin que toute l'app reflète les modifications.
      try {
        final cachedAuth = await CacheService.getAuthResponse();
        final freshUser = await ApiService.getUtilisateurById(id);
        if (cachedAuth != null && freshUser != null) {
          final map = cachedAuth.toJson();
          map['utilisateur'] = freshUser.toJson();
          await CacheService.saveAuthResponse(AuthResponse.fromJson(map));
        }
      } catch (_) {}
      await _loadUserData();
    }
  }

  Future<void> _logout() async {
    // Afficher le dialog d'attente
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
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
        // Fermer le dialog d'attente
        Navigator.pop(context);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Fermer le dialog d'attente
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
    // Couleurs basées sur ton design
    const backgroundColor = Color(0xFF0D0D0D);
    const cardColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const subtitleColor = Colors.white54;
    const accentGreen = Color(0xFF00E676); // Vert fluo du Switch
    const tileSplash = Color(0x14FFFFFF);
    const tileHover = Color(0x0AFFFFFF);

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  const PasswordChangeReminder(
                    margin: EdgeInsets.only(bottom: 16),
                  ),
                  // --- CARTE PROFIL ---
                  _buildCard(cardColor, [
                    ListTile(
                      tileColor: Colors.transparent,
                      splashColor: tileSplash,
                      hoverColor: tileHover,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF00E676),
                        backgroundImage: _buildProfileImageProvider(
                          _client?.photoUrl,
                        ),
                        child:
                            _buildProfileImageProvider(_client?.photoUrl) ==
                                null
                            ? const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 28,
                              )
                            : null,
                      ),
                      title: Text(
                        _client != null
                            ? '${_client!.nom} ${_client!.postnom}'
                            : 'Utilisateur',
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _client != null ? '@${_client!.username}' : '@username',
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
                  const SizedBox(height: 16),

                  // --- GROUPE 1 ---
                  _buildCard(cardColor, [
                    _buildSwitchTile(
                      icon: Icons.notifications_off_outlined,
                      title: 'Pause notifications',
                      value: _pauseNotifications,
                      activeColor: accentGreen,
                      onChanged: (val) =>
                          setState(() => _pauseNotifications = val),
                    ),
                    _buildActionTile(
                      icon: Icons.tune,
                      title: 'Paramètres généraux',
                      onTap: () {},
                    ),
                    _buildCityFilterTile(accentGreen),
                  ]),
                  const SizedBox(height: 16),

                  // --- GROUPE 2 ---
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
                    _buildActionTile(
                      icon: Icons.people_outline,
                      title: 'Mes contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientContactsScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- GROUPE 3 ---
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

                  // --- BOUTON DÉCONNEXION ---
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
                      onPressed: _client?.id != null && _client!.id > 0
                          ? () => AccountDeletionHelper.openDeletionPage(
                                context,
                                userId: _client!.id,
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

  // Widget utilitaire pour créer les blocs arrondis (Cartes)
  Widget _buildCard(Color color, List<Widget> children) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  // Widget utilitaire pour les lignes avec icône et flèche
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      splashColor: const Color(0x14FFFFFF),
      hoverColor: const Color(0x0AFFFFFF),
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

  // Tuile dédiée au filtre des voyages selon la ville de l'utilisateur.
  Widget _buildCityFilterTile(Color activeColor) {
    final subtitle = _filterByMyCity && (_myCity?.trim().isNotEmpty ?? false)
        ? 'Départ : ${_myCity!}'
        : 'Afficher les voyages au départ de votre ville';
    return ListTile(
      tileColor: Colors.transparent,
      splashColor: const Color(0x14FFFFFF),
      hoverColor: const Color(0x0AFFFFFF),
      leading: const Icon(Icons.location_on_outlined,
          color: Colors.white70, size: 22),
      title: const Text(
        'Filtrer les voyages d\'après ma ville',
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: _resolvingCity
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              ),
            )
          : Switch(
              value: _filterByMyCity,
              onChanged: _resolvingCity ? null : _onToggleCityFilter,
              activeThumbColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white24,
            ),
    );
  }

  // Widget utilitaire pour les lignes avec Switch
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      splashColor: const Color(0x14FFFFFF),
      hoverColor: const Color(0x0AFFFFFF),
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
