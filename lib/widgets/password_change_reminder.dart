import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/password_change_service.dart';
import 'package:rusa/widgets/app_feedback.dart';
import 'package:rusa/widgets/app_message.dart';

/// Feuille modale de changement de mot de passe.
Future<bool?> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  static const _accent = Color(0xFF00E676);
  static const _card = Color(0xFF141A18);

  final _ancienController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmerController = TextEditingController();

  bool _isSaving = false;
  bool _obscureAncien = true;
  bool _obscureNouveau = true;
  bool _obscureConfirmer = true;
  AppMessageType? _messageType;
  String? _message;

  @override
  void dispose() {
    _ancienController.dispose();
    _nouveauController.dispose();
    _confirmerController.dispose();
    super.dispose();
  }

  void _showMessage(String text, AppMessageType type) {
    setState(() {
      _message = text;
      _messageType = type;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final ancien = _ancienController.text;
    final nouveau = _nouveauController.text;
    final confirmer = _confirmerController.text;

    if (ancien.isEmpty || nouveau.isEmpty) {
      _showMessage(
        'Veuillez renseigner l\'ancien et le nouveau mot de passe.',
        AppMessageType.warning,
      );
      return;
    }
    if (nouveau.length < 6) {
      _showMessage(
        'Le nouveau mot de passe doit contenir au moins 6 caractères.',
        AppMessageType.warning,
      );
      return;
    }
    if (nouveau != confirmer) {
      _showMessage(
        'La confirmation ne correspond pas au nouveau mot de passe.',
        AppMessageType.warning,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
      _messageType = null;
    });

    final result = await ApiService.changerMotDePasse(
      ancienMotDePasse: ancien,
      nouveauMotDePasse: nouveau,
    );

    if (!mounted) return;

    if (result.ok) {
      await PasswordChangeService.markChanged();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isSaving = false);
    _showMessage(
      AppFeedback.normalizeMessage(result.errorMessage, httpStatus: 400),
      AppMessageType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Changer le mot de passe',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choisissez un mot de passe fort que vous n\'utilisez pas ailleurs.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (_message != null && _messageType != null) ...[
                AppMessage(type: _messageType!, message: _message!),
                const SizedBox(height: 14),
              ],
              _passwordField(
                controller: _ancienController,
                label: 'Mot de passe actuel',
                obscure: _obscureAncien,
                onToggle: () =>
                    setState(() => _obscureAncien = !_obscureAncien),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _nouveauController,
                label: 'Nouveau mot de passe',
                obscure: _obscureNouveau,
                onToggle: () =>
                    setState(() => _obscureNouveau = !_obscureNouveau),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _confirmerController,
                label: 'Confirmer le nouveau mot de passe',
                obscure: _obscureConfirmer,
                onToggle: () =>
                    setState(() => _obscureConfirmer = !_obscureConfirmer),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1A211E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}

/// Bannière de rappel si `doitChangerMotDePasse` est actif (persisté en prefs).
class PasswordChangeReminder extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const PasswordChangeReminder({super.key, this.margin});

  @override
  State<PasswordChangeReminder> createState() => _PasswordChangeReminderState();
}

class _PasswordChangeReminderState extends State<PasswordChangeReminder> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final required = await PasswordChangeService.isChangeRequired();
    if (mounted) setState(() => _visible = required);
  }

  Future<void> _openChangePassword() async {
    final changed = await showChangePasswordSheet(context);
    if (changed == true && mounted) {
      setState(() => _visible = false);
      AppFeedback.showSuccess(
        context,
        'Mot de passe mis à jour. Votre compte est plus sécurisé.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AppMessage(
        type: AppMessageType.warning,
        title: 'Sécurité du compte',
        message:
            'Pour plus de sécurité, veuillez changer votre mot de passe dès que possible.',
        trailing: TextButton(
          onPressed: _openChangePassword,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFB74D),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Changer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
