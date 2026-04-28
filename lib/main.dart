import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/widgets/OnboardingScreen.dart';
import 'package:rusa/widgets/MyNavigationWrapper.dart';
import 'package:rusa/screens/client/AcceuilScreen.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la session au démarrage de l'app
  await SessionService().initializeSession();

  runApp(const RusaTravelApp());
}

class RusaTravelApp extends StatelessWidget {
  const RusaTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rusa Travel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Fond sombre
        primaryColor: const Color(0xFF00E676), // Accent vert fluo
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF222222), // Couleur des cartes
        ),
        // Application de la police style pinceau sur les titres
        textTheme: TextTheme(
          displayLarge: GoogleFonts.caveat(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: GoogleFonts.caveat(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(color: Colors.white70, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SessionService _sessionService = SessionService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isValid = await _sessionService.isSessionValid();
      setState(() {
        _isAuthenticated = isValid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Vérification de la session...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated
        ? const MyNavigationWrapper()
        : const OnboardingScreen();
  }
}
