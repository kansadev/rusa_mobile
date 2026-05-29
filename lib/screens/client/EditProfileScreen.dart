import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/models/utilisateur_profile_update.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/cache_service.dart';
import 'package:rusa/services/session_service.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _lieuController = TextEditingController();

  /// Nouvelle photo choisie (galerie), avant envoi en base64.
  Uint8List? _pickedPhotoBytes;

  bool _loadingData = true;
  bool _saving = false;
  String? _loadError;

  DateTime? _birthDate;
  String _genreCode = 'M';

  Utilisateur? _baseUtilisateur;

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _accent = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  String _genreToCode(String genre) {
    final g = genre.trim().toUpperCase();
    if (g == 'F' || g.startsWith('F')) return 'F';
    if (g.contains('FÉM') || g.contains('FEM')) return 'F';
    return 'M';
  }

  String _birthIso(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseBirth(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.length >= 10 ? raw.substring(0, 10) : raw;
    return DateTime.tryParse(s);
  }

  /// Aperçu : nouvelle image ou photo déjà enregistrée (URL / base64).
  ImageProvider? _profileImageProvider() {
    if (_pickedPhotoBytes != null) {
      return MemoryImage(_pickedPhotoBytes!);
    }
    final raw = _baseUtilisateur?.photoUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }
    try {
      final cleaned = raw.contains('base64,') ? raw.split('base64,').last : raw;
      final bytes = base64Decode(cleaned);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  /// Champ API `photoUrl` : JPEG compressé en base64 si nouvelle sélection, sinon valeur serveur.
  String? _photoPayloadValue() {
    if (_pickedPhotoBytes != null) {
      return base64Encode(_pickedPhotoBytes!);
    }
    final prev = _baseUtilisateur?.photoUrl?.trim();
    if (prev == null || prev.isEmpty) return null;
    return prev;
  }

  Uint8List _compressPhotoJpeg(Uint8List raw) {
    try {
      final decoded = img.decodeImage(raw);
      if (decoded == null) return raw;
      final resized = decoded.width > 1024
          ? img.copyResize(decoded, width: 1024)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    } catch (_) {
      return raw;
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isIOS) {
      final s = await Permission.photos.request();
      return s.isGranted || s.isLimited;
    }
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> _pickPhotoFromGallery() async {
    final ok = await _ensureGalleryPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Accès à la galerie refusé. Autorisez l’app dans les paramètres.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 92,
      );
      if (xfile == null || !mounted) return;
      final raw = await xfile.readAsBytes();
      final compressed = _compressPhotoJpeg(raw);
      setState(() => _pickedPhotoBytes = compressed);
    } catch (e) {
      debugPrint('pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de lire l’image : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });

    try {
      final cached = await CacheService.getAuthResponse();
      final u = cached?.utilisateur;

      if (!mounted) return;

      if (u == null || u.idUtilisateur <= 0) {
        setState(() {
          _loadingData = false;
          _loadError =
              'Impossible de charger le profil. Vérifiez votre connexion.';
        });
        return;
      }

      _baseUtilisateur = u;
      _nomController.text = u.nomComplet;
      _emailController.text = u.email;
      _telController.text = u.telephone;
      _pickedPhotoBytes = null;
      _lieuController.text = u.lieuNaissance ?? '';
      _genreCode = _genreToCode(u.genre);
      _birthDate = _parseBirth(u.dateNaissance);

      setState(() => _loadingData = false);
    } catch (e, st) {
      debugPrint('EditProfileScreen._load: $e\n$st');
      if (mounted) {
        setState(() {
          _loadingData = false;
          _loadError =
              'Erreur lors du chargement. Réessayez ou vérifiez la connexion.';
        });
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: _card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = await CacheService.getAuthResponse();
    if (auth == null || _baseUtilisateur == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session invalide. Reconnectez-vous.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final payload = UtilisateurProfileUpdate(
      idUtilisateur: widget.userId,
      nomComplet: _nomController.text.trim(),
      email: _emailController.text.trim(),
      telephone: _telController.text.trim(),
      photoUrl: _photoPayloadValue(),
      lieuNaissance: _lieuController.text.trim().isEmpty
          ? null
          : _lieuController.text.trim(),
      dateNaissance: _birthDate != null ? _birthIso(_birthDate!) : null,
      genre: _genreCode,
    );

    final result = await ApiService.putUtilisateurProfile(
      widget.userId,
      payload,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Échec de la mise à jour.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final merged =
        result.utilisateur ??
        auth.utilisateur.copyWith(
          nomComplet: payload.nomComplet,
          email: payload.email,
          telephone: payload.telephone,
          photoUrl: payload.photoUrl,
          lieuNaissance: payload.lieuNaissance,
          dateNaissance: payload.dateNaissance,
          genre: payload.genre,
        );

    await SessionService().saveAuthData(
      AuthResponse(
        success: auth.success,
        message: auth.message,
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        tokenType: auth.tokenType,
        expiresIn: auth.expiresIn,
        expiresAt: auth.expiresAt,
        utilisateur: merged,
        doitChangerMotDePasse: auth.doitChangerMotDePasse,
        nomRole: auth.nomRole,
        nomSociete: auth.nomSociete,
        acceptNotification: auth.acceptNotification,
        permissions: auth.permissions,
        roles: auth.roles,
        primaryRole: auth.primaryRole,
        client: auth.client,
        agent: auth.agent,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil mis à jour.',
            style: GoogleFonts.poppins(color: Colors.black87),
          ),
          backgroundColor: _accent,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(color: Colors.white54),
      hintStyle: GoogleFonts.poppins(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent),
      ),
      filled: true,
      fillColor: _card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Modifier le profil',
          style: GoogleFonts.caveat(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      style: FilledButton.styleFrom(backgroundColor: _accent),
                      child: Text(
                        'Réessayer',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Photo de profil',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: _card,
                        backgroundImage: _profileImageProvider(),
                        child: _profileImageProvider() == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 56,
                                color: Colors.white38,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickPhotoFromGallery,
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: _accent,
                      ),
                      label: Text(
                        'Choisir dans la galerie',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    if (_pickedPhotoBytes != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _pickedPhotoBytes = null),
                        child: Text(
                          'Annuler le nouveau choix',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nomController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _decoration('Nom complet'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Champ requis';
                        }
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _telController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('Téléphone'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lieuController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _decoration('Lieu de naissance'),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _saving ? null : _pickBirthDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoration('Date de naissance'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthDate != null
                                  ? '${_birthDate!.day.toString().padLeft(2, '0')}/'
                                        '${_birthDate!.month.toString().padLeft(2, '0')}/'
                                        '${_birthDate!.year}'
                                  : 'Non renseignée',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Genre',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'M',
                          label: Text('Masculin'),
                        ),
                        ButtonSegment<String>(
                          value: 'F',
                          label: Text('Féminin'),
                        ),
                      ],
                      selected: {_genreCode},
                      onSelectionChanged: _saving
                          ? null
                          : (Set<String> next) {
                              if (next.isEmpty) return;
                              setState(() => _genreCode = next.first);
                            },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.black
                              : Colors.white70,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? _accent
                              : _card,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Enregistrer',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
}
