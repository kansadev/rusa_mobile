import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_model.dart';

/// Chips Jour / Semaine / Mois (+ option « Voir tout »).
class VoyagePeriodeSelector extends StatelessWidget {
  const VoyagePeriodeSelector({
    super.key,
    required this.selected,
    required this.onPeriodeChanged,
    this.onVoirTout,
    this.showVoirTout = true,
  });

  final VoyagePeriode selected;
  final ValueChanged<VoyagePeriode> onPeriodeChanged;
  final VoidCallback? onVoirTout;
  final bool showVoirTout;

  static const _accent = Color(0xFF00E676);

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Color(0xFF1A1A1A) : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: _accent,
      backgroundColor: const Color(0xFF1A1A1A),
      side: BorderSide(color: isSelected ? _accent : Colors.white24),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...VoyagePeriode.values.map((p) {
              final isSelected = p == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  label: p.label,
                  isSelected: isSelected,
                  onTap: () => onPeriodeChanged(p),
                ),
              );
            }),
            if (showVoirTout && onVoirTout != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  label: 'Voir tout',
                  isSelected: false,
                  onTap: onVoirTout!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
