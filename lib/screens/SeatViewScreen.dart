import 'package:flutter/material.dart';

class SeatViewScreen extends StatefulWidget {
  final List<int> bookedSeats;

  const SeatViewScreen({super.key, this.bookedSeats = const [3, 7, 12, 14]});

  @override
  State<SeatViewScreen> createState() => _SeatViewScreenState();
}

class _SeatViewScreenState extends State<SeatViewScreen> {
  int? selectedSeat;

  @override
  void initState() {
    super.initState();
    _assignRandomSeat();
  }

  void _assignRandomSeat() {
    // Trouver un siège disponible (non réservé)
    final availableSeats = List.generate(
      16,
      (index) => index + 1,
    ).where((seat) => !widget.bookedSeats.contains(seat)).toList();

    if (availableSeats.isNotEmpty) {
      // Choisir un siège vraiment aléatoire
      final random = DateTime.now().millisecondsSinceEpoch;
      final randomIndex = random % availableSeats.length;
      setState(() {
        selectedSeat = availableSeats[randomIndex];
      });
    }
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
        title: const Text(
          'Vue du siège',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Conteneur du bus
            Expanded(
              child: Center(
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10, width: 2),
                  ),
                  child: Column(
                    children: [
                      // Le volant (pour indiquer l'avant du bus)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 20.0, bottom: 20.0),
                          child: Icon(
                            Icons.radio_button_checked,
                            color: Colors.white38,
                            size: 25,
                          ),
                        ),
                      ),
                      // Génération des rangées de sièges
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: 4, // 4 rangées
                          itemBuilder: (context, rowIndex) {
                            int baseSeatNumber = rowIndex * 4;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Gauche (2 sièges)
                                  Row(
                                    children: [
                                      _buildSeat(baseSeatNumber + 1),
                                      const SizedBox(width: 4),
                                      _buildSeat(baseSeatNumber + 2),
                                    ],
                                  ),
                                  // Couloir (Espace)
                                  const SizedBox(width: 12),
                                  // Droite (2 sièges)
                                  Row(
                                    children: [
                                      _buildSeat(baseSeatNumber + 3),
                                      const SizedBox(width: 4),
                                      _buildSeat(baseSeatNumber + 4),
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
              ),
            ),
            // Légende en dehors du rectangle du bus
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Disponible', Colors.white, Colors.white38),
                  _buildLegendItem(
                    'Votre siège',
                    const Color(0xFF00E676),
                    const Color(0xFF00E676),
                  ),
                  _buildLegendItem(
                    'Occupé',
                    Colors.white10,
                    Colors.transparent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color seatColor, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
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

  Widget _buildSeat(int seatNumber) {
    bool isBooked = widget.bookedSeats.contains(seatNumber);
    bool isSelected = selectedSeat == seatNumber;

    Color seatColor;
    Color borderColor;
    Color textColor;

    if (isBooked) {
      seatColor = Colors.white10;
      borderColor = Colors.transparent;
      textColor = Colors.white24;
    } else if (isSelected) {
      seatColor = const Color(0xFF00E676);
      borderColor = const Color(0xFF00E676);
      textColor = Colors.black;
    } else {
      seatColor = Colors.transparent;
      borderColor = Colors.white38;
      textColor = Colors.white;
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: seatColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$seatNumber',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
