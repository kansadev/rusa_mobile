import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/utilisateur_profile_update.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/widgets/app_feedback.dart';
import 'package:rusa/widgets/app_message.dart';

/// Écran d'édition des informations de l'utilisateur connecté.
/// Met à jour via `PUT /api/Utilisateur/{id}` (photo encodée en base64).
class EditProfileScreen extends StatefulWidget {
  final int idUtilisateur;
  final Utilisateur? initialUser;

  const EditProfileScreen({
    super.key,
    required this.idUtilisateur,
    this.initialUser,
  });

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

  String? _genre;
  DateTime? _dateNaissance;
  String? _photoBase64; // base64 brut (sans préfixe)
  Uint8List? _photoPreview;

  bool _isLoading = true;
  bool _isSaving = false;
  AppMessageType? _messageType;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _applyUser(widget.initialUser!);
      _isLoading = false;
      _loadUser(silent: true);
    } else {
      _loadUser();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final u = await ApiService.getUtilisateurById(widget.idUtilisateur);
    if (!mounted) return;
    if (u != null) {
      _applyUser(u);
    }
    setState(() => _isLoading = false);
  }

  void _applyUser(Utilisateur u) {
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

  void _showInlineMessage(String message, AppMessageType type) {
    setState(() {
      _message = message;
      _messageType = type;
    });
  }

  void _clearInlineMessage() {
    if (_message == null) return;
    setState(() {
      _message = null;
      _messageType = null;
    });
  }

  String? _normalizeGenre(String? raw) {
    final g = (raw ?? '').trim().toLowerCase();
    if (g.isEmpty) return null;
    if (g == 'm' || g.startsWith('h') || g.startsWith('mascul')) return 'Homme';
    if (g == 'f' || g.startsWith('fem')) return 'Femme';
    return null;
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
      _showInlineMessage(
        'Impossible de charger l\'image : $e',
        AppMessageType.error,
      );
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nomController.text.trim().isEmpty ||
        _telephoneController.text.trim().isEmpty) {
      _showInlineMessage(
        'Le nom complet et le téléphone sont obligatoires.',
        AppMessageType.warning,
      );
      return;
    }

    _clearInlineMessage();
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
      Navigator.pop(context, true);
    } else {
      _showInlineMessage(
        AppFeedback.normalizeMessage(result.errorMessage, httpStatus: 400),
        AppMessageType.error,
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
                    if (_message != null && _messageType != null) ...[
                      AppMessage(
                        type: _messageType!,
                        message: _message!,
                      ),
                      const SizedBox(height: 16),
                    ],
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
    const unspecifiedLabel = 'Non renseigné (facultatif)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _genre,
                isExpanded: true,
                hint: const Text(
                  unspecifiedLabel,
                  style: TextStyle(color: Colors.white38),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1A1A1A),
                icon: const Icon(Icons.arrow_drop_down, color: _accent),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: _accent),
                        SizedBox(width: 12),
                        Text(
                          unspecifiedLabel,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  ..._genres.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g,
                      child: Row(
                        children: [
                          const Icon(Icons.wc, color: _accent),
                          const SizedBox(width: 12),
                          Text(g, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _genre = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
