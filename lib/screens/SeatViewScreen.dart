import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/models/voyage_sieges_disponibles_model.dart';
import 'package:rusa/services/api_service.dart';

enum _SeatStatus { available, occupied, empty }

class SeatViewScreen extends StatefulWidget {
  final int idVoyage;
  final String? title;
  final String? subtitle;

  const SeatViewScreen({
    super.key,
    required this.idVoyage,
    this.title,
    this.subtitle,
  });

  @override
  State<SeatViewScreen> createState() => _SeatViewScreenState();
}

class _SeatViewScreenState extends State<SeatViewScreen> {
  VoyageSiegesDisponibles? _data;
  List<SiegeIndisponible> _indisponibles = const [];
  bool _isLoading = true;
  String? _error;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSieges();
  }

  Future<void> _loadSieges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      ApiService.getSiegesDisponiblesByVoyage(widget.idVoyage),
      ApiService.getSiegesIndisponiblesByVoyage(widget.idVoyage),
    ]);

    if (!mounted) return;

    final disponibles = results[0] as VoyageSiegesDisponibles?;
    final indisponibles = results[1] as List<SiegeIndisponible>;

    if (disponibles == null) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les sièges du voyage.';
      });
      return;
    }

    setState(() {
      _data = disponibles;
      _indisponibles = indisponibles;
      _isLoading = false;
      _selectedCategoryIndex = 0;
    });
  }

  CategorieSiegesDisponiblesDetail? get _selectedCategory {
    final cats = _data?.repartitionCategorieSieges ?? const [];
    if (cats.isEmpty || _selectedCategoryIndex >= cats.length) return null;
    return cats[_selectedCategoryIndex];
  }

  List<SiegeIndisponible> _indisponiblesForCategory(
    CategorieSiegesDisponiblesDetail cat,
  ) {
    final availableIds = <int>{};
    final availableOrders = <int>{};
    for (final s in cat.sieges) {
      availableIds.add(s.idSiege);
      availableOrders.add(s.numeroOrdre);
    }

    final otherCategoryIds = <int>{};
    for (final c in _data?.repartitionCategorieSieges ?? const []) {
      if (c.idCategorieSiege == cat.idCategorieSiege) continue;
      for (final s in c.sieges) {
        otherCategoryIds.add(s.idSiege);
      }
    }

    return _indisponibles.where((s) {
      if (availableIds.contains(s.idSiege) ||
          availableOrders.contains(s.numeroOrdre)) {
        return false;
      }
      if (otherCategoryIds.contains(s.idSiege)) return false;
      if (s.numeroOrdre <= 0) return false;
      if (cat.nombreSiege > 0) return s.numeroOrdre <= cat.nombreSiege;
      return true;
    }).toList();
  }

  int _seatCountForCategory(CategorieSiegesDisponiblesDetail cat) {
    final orders = <int>[
      for (final s in cat.sieges) s.numeroOrdre,
      for (final s in _indisponiblesForCategory(cat)) s.numeroOrdre,
    ];
    final maxOrdre = orders.isEmpty
        ? 0
        : orders.reduce((a, b) => a > b ? a : b);
    return maxOrdre > cat.nombreSiege ? maxOrdre : cat.nombreSiege;
  }

  SiegeIndisponible? _indisponibleAt(
    CategorieSiegesDisponiblesDetail cat,
    int order,
  ) {
    for (final s in _indisponiblesForCategory(cat)) {
      if (s.numeroOrdre == order) return s;
    }
    return null;
  }

  String? _codeForAvailable(CategorieSiegesDisponiblesDetail cat, int order) {
    for (final s in cat.sieges) {
      if (s.numeroOrdre == order) return s.displayLabel;
    }
    return null;
  }

  _SeatStatus _status(CategorieSiegesDisponiblesDetail cat, int order) {
    if (cat.sieges.any((s) => s.numeroOrdre == order)) {
      return _SeatStatus.available;
    }
    if (_indisponibleAt(cat, order) != null) return _SeatStatus.occupied;
    return _SeatStatus.empty;
  }

  void _showOccupiedDetails(SiegeIndisponible seat) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Siège ${seat.displayLabel}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow(Icons.person_outline, 'Passager', seat.nomPassager),
            if (seat.idReservationPassenger > 0)
              _detailRow(
                Icons.confirmation_number_outlined,
                'Réservation passager',
                '#${seat.idReservationPassenger}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  display,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.title ?? 'Sièges disponibles',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty)
              Text(
                widget.subtitle!,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadSieges,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final categories = data.repartitionCategorieSieges;

    if (categories.isEmpty && _indisponibles.isEmpty) {
      return Center(
        child: Text(
          'Aucune information sur les sièges pour ce voyage.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    if (categories.isEmpty) {
      return _buildIndisponiblesOnlyLayout();
    }

    final cat = _selectedCategory!;
    final occupiedInCat = _indisponiblesForCategory(cat);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_seat,
                  color: const Color(0xFF00E676),
                  label: 'Disponibles',
                  value: '${data.nombreSiegesDisponibles}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_seat_outlined,
                  color: Colors.orangeAccent,
                  label: 'Occupés',
                  value: '${_indisponibles.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.length > 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final selected = index == _selectedCategoryIndex;
                  final occ = _indisponiblesForCategory(c).length;
                  return ChoiceChip(
                    label: Text(
                      '${c.label} (${c.sieges.length} libres${occ > 0 ? ', $occ occ.' : ''})',
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF00E676)
                          : Colors.white24,
                    ),
                  );
                },
              ),
            ),
          if (categories.length > 1) const SizedBox(height: 16),
          Expanded(child: _buildBusLayout(cat)),
          if (occupiedInCat.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Appuyez sur un siège occupé pour voir le passager.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndisponiblesOnlyLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
            icon: Icons.event_seat_outlined,
            color: Colors.orangeAccent,
            label: 'Sièges occupés',
            value: '${_indisponibles.length}',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _indisponibles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = _indisponibles[index];
                return ListTile(
                  tileColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                    child: Text(
                      s.displayLabel,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    s.nomPassager.trim().isEmpty
                        ? 'Passager non renseigné'
                        : s.nomPassager,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Siège ${s.displayLabel}',
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                  onTap: () => _showOccupiedDetails(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusLayout(CategorieSiegesDisponiblesDetail cat) {
    final seatCount = _seatCountForCategory(cat);
    if (seatCount <= 0) {
      return Center(
        child: Text(
          'Aucun siège dans la catégorie ${cat.label}.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    final rowCount = (seatCount / 4).ceil();

    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10, width: 2),
        ),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20, bottom: 16),
                child: Icon(
                  Icons.radio_button_checked,
                  color: Colors.white38,
                  size: 25,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: rowCount,
                itemBuilder: (context, rowIndex) {
                  final base = rowIndex * 4;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (base + 1 <= seatCount)
                              _buildSeat(cat, base + 1),
                            if (base + 2 <= seatCount) ...[
                              const SizedBox(width: 4),
                              _buildSeat(cat, base + 2),
                            ],
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            if (base + 3 <= seatCount)
                              _buildSeat(cat, base + 3),
                            if (base + 4 <= seatCount) ...[
                              const SizedBox(width: 4),
                              _buildSeat(cat, base + 4),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeat(CategorieSiegesDisponiblesDetail cat, int order) {
    final status = _status(cat, order);
    final occupied = _indisponibleAt(cat, order);

    String label;
    switch (status) {
      case _SeatStatus.available:
        label = _codeForAvailable(cat, order) ?? '$order';
      case _SeatStatus.occupied:
        label = occupied?.displayLabel ?? '$order';
      case _SeatStatus.empty:
        label = '$order';
    }

    Color seatColor;
    Color borderColor;
    Color textColor;

    switch (status) {
      case _SeatStatus.available:
        seatColor = const Color(0xFF00E676).withValues(alpha: 0.15);
        borderColor = const Color(0xFF00E676);
        textColor = const Color(0xFF00E676);
      case _SeatStatus.occupied:
        seatColor = Colors.orangeAccent.withValues(alpha: 0.15);
        borderColor = Colors.orangeAccent;
        textColor = Colors.orangeAccent;
      case _SeatStatus.empty:
        seatColor = Colors.transparent;
        borderColor = Colors.white12;
        textColor = Colors.white24;
    }

    final seatWidget = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: seatColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );

    if (status == _SeatStatus.occupied && occupied != null) {
      return GestureDetector(
        onTap: () => _showOccupiedDetails(occupied),
        child: seatWidget,
      );
    }

    return seatWidget;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Disponible', const Color(0xFF00E676)),
          _buildLegendItem('Occupé', Colors.orangeAccent),
          _buildLegendItem('Libre', Colors.white12),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color seatColor) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: seatColor.withValues(
              alpha: seatColor == Colors.white12 ? 1 : 0.2,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: seatColor == Colors.white12
                  ? Colors.transparent
                  : seatColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
