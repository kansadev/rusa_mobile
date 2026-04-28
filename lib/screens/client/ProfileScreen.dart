import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rusa/models/client_model.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';

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

  @override
  void initState() {
    super.initState();
    // Charger les données en arrière-plan sans bloquer l'UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    // Charger les données utilisateur directement depuis SessionService
    final session = SessionService();
    final userData = await session.getUserInfo();

    if (userData != null && mounted) {
      // Créer un ClientModel à partir des données de session
      final name = userData['name'] ?? '';
      final nameParts = name.split(' ');

      String? photoUrl;
      try {
        final prefs = await SharedPreferences.getInstance();
        final authData = prefs.getString('auth_data');
        if (authData != null) {
          final authJson = json.decode(authData);
          photoUrl = authJson['utilisateur']?['photoUrl'];
        }
      } catch (e) {
        debugPrint('Impossible de récupérer photoUrl: $e');
      }

      setState(() {
        _client = ClientModel(
          id: int.tryParse(userData['id'] ?? '0') ?? 0,
          clientId:int.tryParse(userData['client_id'] ?? '0')??0,
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
          photoUrl: photoUrl,
        );
        _isLoading = false; 
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
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
                  // --- CARTE PROFIL ---
                  _buildCard(cardColor, [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF00E676),
                        backgroundImage:
                            _client != null && _client!.photoUrl != null
                            ? NetworkImage(_client!.photoUrl!)
                            : null,
                        child: _client == null || _client!.photoUrl == null
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
                      onTap: () {
                        // Navigation vers l'édition du profil si nécessaire
                      },
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
                      title: 'General settings',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- GROUPE 2 ---
                  _buildCard(cardColor, [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      value: _darkMode,
                      activeColor: accentGreen,
                      onChanged: (val) => setState(() => _darkMode = val),
                    ),
                    _buildActionTile(
                      icon: Icons.translate,
                      title: 'Language',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.people_outline,
                      title: 'My Contact', // Orthographe de la maquette
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- GROUPE 3 ---
                  _buildCard(cardColor, [
                    _buildActionTile(
                      icon: Icons.help_outline,
                      title: 'FAQ',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.info_outline,
                      title: 'Terms of service',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.person_outline,
                      title: 'User policy',
                      onTap: () {},
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
                        'Log Out',
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Widget utilitaire pour créer les blocs arrondis (Cartes)
  Widget _buildCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
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

  // Widget utilitaire pour les lignes avec Switch
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
