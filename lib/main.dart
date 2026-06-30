import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rusa/widgets/OnboardingScreen.dart';
import 'package:rusa/widgets/CaissierNavigationWrapper.dart';
import 'package:rusa/widgets/MyNavigationWrapper.dart';
import 'package:rusa/screens/auth/UnsupportedRoleScreen.dart';
import 'package:rusa/services/session_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/adapters/hive_adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureProductionErrorHandling();

  // Initialiser Hive avec hive_flutter
  await Hive.initFlutter();

  registerHiveAdapters();
  await CacheService.init();

  // Initialiser la session au démarrage de l'app
  await SessionService().initializeSession();

  // DEBUG: Vérifier la cohérence CacheService ? Modèles
  await CacheService.debugPrintCacheStatus();

  runApp(const RusaTravelApp());
}

/// Réduit le bruit des avertissements Flutter connus en production.
void _configureProductionErrorHandling() {
  if (!kReleaseMode) return;

  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = '${details.exceptionAsString()}\n${details.summary}';
    if (_isBenignFrameworkNoise(text)) return;
    if (defaultOnError != null) {
      defaultOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
}

bool _isBenignFrameworkNoise(String message) {
  return message.contains(
        'ListTile background color or ink splashes may be invisible',
      ) ||
      message.contains('overflowed by');
}

class RusaTravelApp extends StatelessWidget {
  const RusaTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rusa Travel',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Fond sombre
        primaryColor: const Color(0xFF00E676), // Accent vert fluo
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF222222), // Couleur des cartes
        ),
        // Application de la police style pinceau sur les titres
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xFF252525),
          selectedTileColor: Color(0xFF2C2C2C),
          iconColor: Colors.white70,
          textColor: Colors.white,
        ),
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
  bool _isClientRole = false;
  bool _isCaissierRole = false;
  String? _roleName;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  /// Demande la permission de localisation dès l'ouverture de l'application
  /// (utilisée pour filtrer les voyages selon la ville de l'utilisateur).
  Future<void> _requestStartupPermissions() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      debugPrint('Permission localisation au démarrage: $permission');
    } catch (e) {
      debugPrint('Erreur demande permission localisation: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isValid = await _sessionService.isSessionValid();
      String? roleName;
      bool isClientRole = false;
      bool isCaissierRole = false;
      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        final clientId = prefs.getString('client_id');
        roleName = (await CacheService.getAuthResponse())?.nomRole;
        final loweredRole = (roleName ?? '').toLowerCase();
        isCaissierRole = loweredRole.contains('caiss');
        isClientRole = clientId != null && clientId != '0';
      }
      setState(() {
        _isAuthenticated = isValid;
        _isClientRole = isClientRole;
        _isCaissierRole = isCaissierRole;
        _roleName = roleName;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
      setState(() {
        _isAuthenticated = false;
        _isClientRole = false;
        _isCaissierRole = false;
        _roleName = null;
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

    if (!_isAuthenticated) {
      return const OnboardingScreen();
    }
    if (_isCaissierRole) {
      return const CaissierNavigationWrapper();
    }
    if (!_isClientRole) {
      return UnsupportedRoleScreen(roleName: _roleName);
    }
    return const MyNavigationWrapper();
  }
}
