import 'package:flutter/material.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/screens/client/AcceuilScreen.dart';
import 'package:rusa/screens/auth/RegisterPage.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/widgets/MyNavigationWrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      debugPrint(
        'Sauvegarde des données d\'authentification avec SessionService...',
      );

      // Utiliser SessionService pour sauvegarder les données
      await SessionService().saveAuthData(authResponse);

      debugPrint('Données d\'authentification sauvegardées avec succès!');
      debugPrint('Sauvegarde des données terminée avec succès!');
    } catch (e) {
      debugPrint('Erreur détaillée lors de la sauvegarde des données: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Tentative de connexion avec: ${_emailController.text}');

      final authResponse = await ApiService.authenticateUser(
        _emailController.text,
        _passwordController.text,
      );

      debugPrint(
        'Réponse de l\'API: ${authResponse != null ? "Succès" : "Null"}',
      );

      if (authResponse != null) {
        debugPrint('Données utilisateur:');
        debugPrint('  - ID: ${authResponse.utilisateur.idUtilisateur}');
        debugPrint('  - Nom: ${authResponse.utilisateur.nomComplet}');
        debugPrint('  - Email: ${authResponse.utilisateur.email}');
        debugPrint('  - Téléphone: ${authResponse.utilisateur.telephone}');
        debugPrint('  - Genre: ${authResponse.utilisateur.genre}');
        debugPrint('  - ID Client: ${authResponse.client.idClient}');
        debugPrint('  - Nom Client: ${authResponse.client.nomClient}');
        debugPrint('  - Email Client: ${authResponse.client.emailClient}');
        debugPrint('  - Téléphone Client: ${authResponse.client.telephone}');

        // Sauvegarder les données d'authentification
        await _saveAuthData(authResponse);

        // Connexion réussie
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie!'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyNavigationWrapper(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email ou mot de passe incorrect',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur détaillée lors de l\'authentification: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/img4.png"),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bon retour !',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: Color(0xFF00E676)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Connexion',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas de compte ? '),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(color: Color(0xFF00E676)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
