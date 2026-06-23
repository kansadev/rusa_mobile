import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/screens/auth/RegisterRateLimitScreen.dart';
import 'package:rusa/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isSubmitting = false;

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _nomClientController = TextEditingController();
  final TextEditingController _adresseClientController =
      TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailClientController = TextEditingController();
  String? _selectedGenre;

  @override
  void dispose() {
    _nomClientController.dispose();
    _adresseClientController.dispose();
    _telephoneController.dispose();
    _emailClientController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;

    // Nom, téléphone et adresse (min. 5 caractères) sont obligatoires côté API.
    final nom = _nomClientController.text.trim();
    final telephone = _telephoneController.text.trim();
    final adresse = _adresseClientController.text.trim();

    if (nom.isEmpty || telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom et le numéro de téléphone sont obligatoires.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (adresse.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "L'adresse est obligatoire et doit contenir au moins 5 caractères.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final genre = _selectedGenre == null
          ? null
          : (_selectedGenre == 'Femme' ? 'F' : 'M');
      final result = await ApiService.registerClient(
        nomClient: _nomClientController.text.trim(),
        emailClient: _emailClientController.text,
        telephone: _telephoneController.text.trim(),
        adresseClient: _adresseClientController.text,
        genreClient: genre,
        acceptTerms: true,
        subscribeNewsletter: true,
        marketingConsent: true,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final welcome = result.welcomeMessage;
        await _showDefaultPasswordDialog(welcomeMessage: welcome);
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(
              registrationSuccessMessage:
                  'Compte créé. Connectez-vous avec votre téléphone et le mot de passe affiché.',
            ),
          ),
          (route) => false,
        );
      } else if (result.isRateLimited) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => RegisterRateLimitScreen(
              retryAfterSeconds: result.retryAfterSeconds ?? 600,
              message: result.apiMessage,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _copyDefaultPassword(BuildContext dialogContext) async {
    await Clipboard.setData(
      const ClipboardData(text: ApiService.defaultClientPassword),
    );
    if (!dialogContext.mounted) return;
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe copié dans le presse-papiers'),
        backgroundColor: Color(0xFF00E676),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDefaultPasswordDialog({String? welcomeMessage}) {
    final intro = welcomeMessage?.trim().isNotEmpty == true
        ? welcomeMessage!.trim()
        : 'Votre compte a bien été créé. Votre mot de passe par défaut est :';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF00E676), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compte créé',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intro,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ApiService.defaultClientPassword,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00E676),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyDefaultPassword(ctx),
                      tooltip: 'Copier le mot de passe',
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pensez à le modifier depuis votre profil pour sécuriser votre compte.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('J\'ai compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(30, 24, 30, keyboardInset + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Créer un compte',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Renseignez vos informations pour créer votre compte.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              _buildRegFieldWithController(
                'Nom complet *',
                Icons.person_outline,
                _nomClientController,
              ),
              _buildRegFieldWithController(
                'Téléphone *',
                Icons.phone_android,
                _telephoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildGenreDropdown(),
              _buildRegFieldWithController(
                'Email (facultatif)',
                Icons.email_outlined,
                _emailClientController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildRegFieldWithController(
                'Adresse complète *',
                Icons.home_outlined,
                _adresseClientController,
              ),
              const Text(
                '* Champs obligatoires. L\'adresse doit contenir au moins '
                '5 caractères.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
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
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Créer mon compte',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                      children: [
                        TextSpan(text: "Vous avez déjà un compte ? "),
                        TextSpan(
                          text: "Connectez-vous",
                          style: TextStyle(color: Color(0xFF00E676)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    const unspecifiedLabel = 'Non renseigné (facultatif)';
    const genres = ['Homme', 'Femme'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Genre (facultatif)',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedGenre,
                isExpanded: true,
                hint: const Text(
                  unspecifiedLabel,
                  style: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF222222),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E676)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline,
                            color: Color(0xFF00E676)),
                        SizedBox(width: 12),
                        Text(
                          unspecifiedLabel,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  ...genres.map((String genre) {
                    return DropdownMenuItem<String?>(
                      value: genre,
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF00E676)),
                          const SizedBox(width: 12),
                          Text(genre,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (String? newValue) {
                  setState(() => _selectedGenre = newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegFieldWithController(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
          filled: true,
          fillColor: const Color(0xFF222222),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
