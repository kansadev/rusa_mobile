import 'package:flutter/material.dart';
import 'package:rusa/screens/client/AcceuilScreen.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:rusa/screens/client/ClientBilletCheckScreen.dart';
import 'package:rusa/screens/client/ReservationsScreen.dart';
import 'package:rusa/screens/client/ProfileScreen.dart';

class MyNavigationWrapper extends StatefulWidget {
  const MyNavigationWrapper({super.key});

  @override
  State<MyNavigationWrapper> createState() => _MyNavigationWrapperState();
}

class _MyNavigationWrapperState extends State<MyNavigationWrapper> {
  int _bottomNavIndex = 0;

  /// Onglets déjà ouverts au moins une fois (évite de créer le scanner au démarrage).
  final Set<int> _visitedTabs = {0};

  /// Cache des écrans sans caméra pour conserver leur état entre les onglets.
  final Map<int, Widget> _screenCache = {};

  static const int _billetCheckTabIndex = 3;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const SearchTripScreen();
      case 1:
        return const AllVoyagesScreen(showBack: false);
      case 2:
        return const ReservationsScreen();
      case _billetCheckTabIndex:
        return const ClientBilletCheckScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _screenFor(int index) {
    if (index == _billetCheckTabIndex) {
      return _buildScreen(index);
    }
    return _screenCache.putIfAbsent(index, () => _buildScreen(index));
  }

  void _onTabSelected(int index) {
    setState(() {
      _bottomNavIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: List.generate(5, (index) {
          if (!_visitedTabs.contains(index)) {
            return const SizedBox.shrink();
          }
          return _screenFor(index);
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onTabSelected,
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF222222),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_rounded),
            label: 'Voyages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Réservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Vérifier billet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
      ),
    );
  }
}
