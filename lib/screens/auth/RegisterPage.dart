import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _nomClientController = TextEditingController();
  final TextEditingController _adresseClientController =
      TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailClientController = TextEditingController();
  String _selectedGenre = 'Homme'; // Valeur par défaut pour le dropdown
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _avenueController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      body: Column(
        children: [
          const SizedBox(height: 50),
          // Indicateur de progression
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: Colors.white12,
              color: const Color(0xFF00E676),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Étape ${_currentPage + 1}/4',
                  style: const TextStyle(color: Colors.white54),
                ),
                Text(
                  _currentPage == 0
                      ? 'Infos Perso'
                      : _currentPage == 1
                      ? 'Contact'
                      : _currentPage == 2
                      ? 'Adresse 1'
                      : 'Adresse 2',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              physics: const BouncingScrollPhysics(), // Permet le swipe naturel
              children: [
                // Page 1: Informations personnelles
                _buildStep(
                  title: 'Informations Personnelles',
                  subtitle: 'Votre identité',
                  fields: [
                    _buildRegFieldWithController(
                      'Nom complet',
                      Icons.person_outline,
                      _nomClientController,
                    ),
                    _buildGenreDropdown(),
                  ],
                ),
                // Page 2: Contact
                _buildStep(
                  title: 'Coordonnées',
                  subtitle: 'Comment vous contacter',
                  fields: [
                    _buildRegFieldWithController(
                      'Email',
                      Icons.email_outlined,
                      _emailClientController,
                    ),
                    _buildRegFieldWithController(
                      'Téléphone',
                      Icons.phone_android,
                      _telephoneController,
                    ),
                  ],
                ),
                // Page 3: Adresse principale
                _buildStep(
                  title: 'Adresse Principale',
                  subtitle: 'Votre lieu de résidence',
                  fields: [
                    _buildRegFieldWithController(
                      'Adresse complète',
                      Icons.home,
                      _adresseClientController,
                    ),
                    _buildRegFieldWithController(
                      'Province',
                      Icons.location_city,
                      _provinceController,
                    ),
                    _buildRegFieldWithController(
                      'Ville',
                      Icons.location_city,
                      _villeController,
                    ),
                  ],
                ),
                // Page 4: Adresse détaillée
                _buildStep(
                  title: 'Adresse Détaillée',
                  subtitle: 'Complétez votre adresse',
                  fields: [
                    _buildRegFieldWithController(
                      'Commune',
                      Icons.apartment,
                      _communeController,
                    ),
                    _buildRegFieldWithController(
                      'Avenue',
                      Icons.signpost,
                      _avenueController,
                    ),
                    _buildRegFieldWithController(
                      'Numéro',
                      Icons.home,
                      _numeroController,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _currentPage == 3 ? () {} : _nextPage,
                child: Text(
                  _currentPage == 3 ? 'Terminer' : 'Suivant',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required List<Widget> fields,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 40),
          // Afficher les champs directement sans scroll
          ...fields,
        ],
      ),
    );
  }

  Widget _buildGenreDropdown() {
    final List<String> genres = ['Homme', 'Femme'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGenre,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF222222),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E676)),
            items: genres.map((String genre) {
              return DropdownMenuItem<String>(
                value: genre,
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF00E676)),
                    const SizedBox(width: 12),
                    Text(genre, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGenre = newValue!;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRegFieldWithController(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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
