import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/auth_models.dart';
import 'package:rusa/services/api_service.dart';

/// Formulaire d’inscription client depuis la caisse (client absent du système).
class CaissierAddClientScreen extends StatefulWidget {
  const CaissierAddClientScreen({super.key});

  @override
  State<CaissierAddClientScreen> createState() =>
      _CaissierAddClientScreenState();
}

class _CaissierAddClientScreenState extends State<CaissierAddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _provinceController = TextEditingController();
  final _villeController = TextEditingController();
  final _communeController = TextEditingController();
  final _avenueController = TextEditingController();
  final _numeroController = TextEditingController();

  String? _genre;
  bool _isSubmitting = false;

  static const _bg = Color(0xFF0A0F0D);
  static const _card = Color(0xFF141A18);
  static const _accent = Color(0xFF29F58B);

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _provinceController.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _avenueController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  String? _messageFromBody(Map<String, dynamic>? body) {
    if (body == null) return null;
    final m = body['message'] ?? body['title'] ?? body['detail'];
    if (m != null) return m.toString();
    final errs = body['errors'];
    if (errs is Map) {
      final parts = <String>[];
      for (final e in errs.entries) {
        final v = e.value;
        if (v is List) {
          parts.add('${e.key}: ${v.join(", ")}');
        } else {
          parts.add('${e.key}: $v');
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }
    return null;
  }

  Client? _clientFromBody(Map<String, dynamic>? body) {
    if (body == null) return null;
    try {
      if (body['idClient'] != null) {
        return Client.fromJson(Map<String, dynamic>.from(body));
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return Client.fromJson(data);
      }
      if (data is Map) {
        return Client.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final outcome = await ApiService.registerClientWithStatus(
        nomClient: _nomController.text.trim(),
        emailClient: _emailController.text,
        telephone: _telephoneController.text.trim(),
        adresseClient: _adresseController.text,
        genreClient: _genre,
        province: _provinceController.text,
        ville: _villeController.text,
        commune: _communeController.text,
        avenue: _avenueController.text,
        numero: _numeroController.text,
        acceptTerms: true,
        subscribeNewsletter: false,
        marketingConsent: false,
      );

      if (!mounted) return;

      final body = outcome.body;
      final result = RegisterClientResult(
        statusCode: outcome.statusCode,
        body: body,
      );
      final ok = result.isSuccess;

      if (ok) {
        final msg =
            _messageFromBody(body) ??
            (body?['welcomeMessage'] ?? 'Client enregistré avec succès')
                .toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _accent));
        final created = _clientFromBody(body);
        if (created != null && created.idClient > 0) {
          Navigator.pop(context, created);
        } else {
          Navigator.pop(context, true);
        }
        return;
      }

      if (outcome.statusCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur réseau ou serveur indisponible. Réessayez.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final errText = result.userMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errText),
          backgroundColor: result.isRateLimited ? Colors.orange : Colors.red,
          duration: Duration(seconds: result.isRateLimited ? 6 : 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.2),
          ),
        ),
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Nouveau client',
          style: GoogleFonts.caveat(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Créez un compte client lorsque la personne n’existe pas encore dans le système. Les champs marqués par la validation sont obligatoires.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            _field(label: 'Nom complet', controller: _nomController),
            Text(
              'Genre (facultatif)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Homme'),
                  selected: _genre == 'M',
                  onSelected: _isSubmitting
                      ? null
                      : (_) => setState(
                            () => _genre = _genre == 'M' ? null : 'M',
                          ),
                  selectedColor: _accent.withValues(alpha: 0.35),
                  labelStyle: TextStyle(
                    color: _genre == 'M' ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Femme'),
                  selected: _genre == 'F',
                  onSelected: _isSubmitting
                      ? null
                      : (_) => setState(
                            () => _genre = _genre == 'F' ? null : 'F',
                          ),
                  selectedColor: _accent.withValues(alpha: 0.35),
                  labelStyle: TextStyle(
                    color: _genre == 'F' ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              label: 'E-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (!v.contains('@')) return 'E-mail invalide';
                return null;
              },
            ),
            _field(
              label: 'Téléphone',
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
            ),
            _field(
              label: 'Adresse (ligne principale)',
              controller: _adresseController,
            ),
            _field(label: 'Province', controller: _provinceController),
            _field(label: 'Ville', controller: _villeController),
            _field(label: 'Commune', controller: _communeController),
            _field(label: 'Avenue', controller: _avenueController),
            _field(label: 'Numéro', controller: _numeroController),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : Text(
                        'Enregistrer le client',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
