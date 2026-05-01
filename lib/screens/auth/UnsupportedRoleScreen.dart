import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/screens/auth/LoginScreen.dart';
import 'package:rusa/services/session_service.dart';

class UnsupportedRoleScreen extends StatefulWidget {
  final String? roleName;

  const UnsupportedRoleScreen({super.key, this.roleName});

  @override
  State<UnsupportedRoleScreen> createState() => _UnsupportedRoleScreenState();
}

class _UnsupportedRoleScreenState extends State<UnsupportedRoleScreen> {
  bool _isLoggingOut = false;

  Future<void> _logoutAndBackToLogin() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await SessionService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.roleName == null || widget.roleName!.trim().isEmpty)
        ? 'Non défini'
        : widget.roleName!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.orange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Rôle non pris en charge',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ce compte est authentifié, mais son rôle n\'est pas compatible avec cette application client.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rôle détecté : $role',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoggingOut ? null : _logoutAndBackToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Se déconnecter',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
