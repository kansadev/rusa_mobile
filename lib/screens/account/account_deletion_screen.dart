import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/services/api_service.dart';
import 'package:rusa/services/session_service.dart';

/// Page de demande de suppression de compte (safe delete, délai de grâce 90 jours).
class AccountDeletionScreen extends StatefulWidget {
  final int userId;

  const AccountDeletionScreen({super.key, required this.userId});

  static const String confirmationPhrase = 'Supprimer mon compte';
  static const String supportEmail = 'support@rusatravel.cd';

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1E1E1E);
  static const Color _accent = Color(0xFF00E676);

  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  bool get _phraseMatches =>
      _confirmController.text.trim() == AccountDeletionScreen.confirmationPhrase;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletion() async {
    if (_isDeleting || !_phraseMatches) return;

    setState(() => _isDeleting = true);
    try {
      final result = await ApiService.toggleUtilisateurStatut(widget.userId);
      if (!mounted) return;

      if (!result.ok) {
        _showError(
          result.errorMessage ?? 'Impossible de supprimer le compte.',
        );
        return;
      }

      await SessionService().logout();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(
            registrationSuccessMessage:
                'Votre demande de suppression a été enregistrée. '
                'Vous avez été déconnecté.',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de la suppression : $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'Supprimer mon compte',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
        children: [
          _buildSorryBanner(),
          const SizedBox(height: 20),
          _infoCard(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFFFFB74D),
            title: 'Suppression progressive',
            body:
                'Vos données ne seront pas effacées immédiatement. '
                'La suppression définitive peut prendre jusqu\'à 90 jours '
                'après votre demande.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.support_agent_rounded,
            iconColor: _accent,
            title: 'Délai de récupération',
            body:
                'Pendant ces 90 jours, vous pouvez contacter notre support à '
                '${AccountDeletionScreen.supportEmail} pour réactiver votre compte '
                'et récupérer vos données.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.redAccent,
            title: 'Après 90 jours',
            body:
                'Passé ce délai sans demande de récupération, votre compte et '
                'vos données associées seront définitivement supprimés.',
          ),
          const SizedBox(height: 28),
          Text(
            'Confirmation',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pour confirmer, saisissez exactement le texte ci-dessous :',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              AccountDeletionScreen.confirmationPhrase,
              style: GoogleFonts.poppins(
                color: _accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            enabled: !_isDeleting,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AccountDeletionScreen.confirmationPhrase,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _phraseMatches ? _accent : Colors.white12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isDeleting || !_phraseMatches ? null : _submitDeletion,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Supprimer définitivement',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context),
              child: const Text(
                'Annuler et garder mon compte',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSorryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2A22),
            _card,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_outlined,
            color: Colors.white.withValues(alpha: 0.7),
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            'Nous sommes désolés de vous voir partir',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Votre expérience compte pour nous. Si quelque chose n\'a pas fonctionné '
            'comme prévu, notre équipe reste disponible avant que vous ne partiez.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
