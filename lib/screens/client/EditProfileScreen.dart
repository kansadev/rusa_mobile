import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:rusa/models/utilisateur_profile_update.dart';
import 'package:rusa/services/api_service.dart';

/// Écran d'édition des informations de l'utilisateur connecté.
/// Met à jour via `PUT /api/Utilisateur/{id}` (photo encodée en base64).
class EditProfileScreen extends StatefulWidget {
  final int idUtilisateur;

  const EditProfileScreen({super.key, required this.idUtilisateur});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _accent = Color(0xFF00E676);
  static const List<String> _genres = ['Homme', 'Femme'];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _lieuNaissanceController =
      TextEditingController();

  String _genre = 'Homme';
  DateTime? _dateNaissance;
  String? _photoBase64; // base64 brut (sans préfixe)
  Uint8List? _photoPreview;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final u = await ApiService.getUtilisateurById(widget.idUtilisateur);
    if (!mounted) return;
    if (u != null) {
      _nomController.text = u.nomComplet;
      _emailController.text = u.email;
      _telephoneController.text = u.telephone;
      _lieuNaissanceController.text = u.lieuNaissance ?? '';
      _genre = _normalizeGenre(u.genre);
      _dateNaissance = _parseDate(u.dateNaissance);
      final photo = u.photoUrl?.trim() ?? '';
      if (photo.isNotEmpty &&
          !photo.startsWith('http://') &&
          !photo.startsWith('https://')) {
        try {
          final cleaned = photo.contains('base64,')
              ? photo.split('base64,').last
              : photo;
          _photoBase64 = cleaned;
          _photoPreview = base64Decode(cleaned);
        } catch (_) {}
      }
    }
    setState(() => _isLoading = false);
  }

  String _normalizeGenre(String? raw) {
    final g = (raw ?? '').trim().toLowerCase();
    if (g.startsWith('h') || g == 'm' || g.startsWith('mascul')) return 'Homme';
    if (g.startsWith('f')) return 'Femme';
    return 'Autre';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  String? _formatDateForApi(DateTime? d) {
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _dateLabel() {
    final d = _dateNaissance;
    if (d == null) return 'Sélectionner une date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();

      // Redimensionner et recompresser pour limiter la taille du base64.
      final decoded = img.decodeImage(bytes);
      Uint8List finalBytes;
      if (decoded != null) {
        final resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? 512 : null,
          height: decoded.height >= decoded.width ? 512 : null,
        );
        finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
      } else {
        finalBytes = bytes;
      }

      if (!mounted) return;
      setState(() {
        _photoPreview = finalBytes;
        _photoBase64 = base64Encode(finalBytes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger l\'image : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nomController.text.trim().isEmpty ||
        _telephoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom complet et le téléphone sont obligatoires.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final payload = UtilisateurProfileUpdate(
      idUtilisateur: widget.idUtilisateur,
      nomComplet: _nomController.text.trim(),
      email: _emailController.text.trim(),
      telephone: _telephoneController.text.trim(),
      photoUrl: _photoBase64,
      lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
          ? null
          : _lieuNaissanceController.text.trim(),
      dateNaissance: _formatDateForApi(_dateNaissance),
      genre: _genre,
    );

    final result = await ApiService.putUtilisateurProfile(
      widget.idUtilisateur,
      payload,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          backgroundColor: _accent,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Échec de la mise à jour.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Modifier le profil',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildPhotoPicker()),
                    const SizedBox(height: 24),
                    _buildField(
                      'Nom complet *',
                      Icons.person_outline,
                      _nomController,
                    ),
                    _buildField(
                      'Téléphone *',
                      Icons.phone_android,
                      _telephoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      'Email',
                      Icons.email_outlined,
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildField(
                      'Lieu de naissance',
                      Icons.place_outlined,
                      _lieuNaissanceController,
                    ),
                    _buildDateField(),
                    _buildGenreDropdown(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          disabledBackgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildPhotoPicker() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: _accent,
          backgroundImage: _photoPreview != null
              ? MemoryImage(_photoPreview!)
              : null,
          child: _photoPreview == null
              ? const Icon(Icons.person, color: Colors.black, size: 52)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: _accent, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: _accent, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: _accent),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(15),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            labelStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.cake_outlined, color: _accent),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            _dateLabel(),
            style: TextStyle(
              color: _dateNaissance == null ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _genre,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF1A1A1A),
            icon: const Icon(Icons.arrow_drop_down, color: _accent),
            items: _genres
                .map(
                  (g) => DropdownMenuItem<String>(
                    value: g,
                    child: Row(
                      children: [
                        const Icon(Icons.wc, color: _accent),
                        const SizedBox(width: 12),
                        Text(g, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _genre = v ?? 'Autre'),
          ),
        ),
      ),
    );
  }
}
