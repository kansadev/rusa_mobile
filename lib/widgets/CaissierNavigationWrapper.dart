import 'package:flutter/material.dart';
import 'package:rusa/screens/caissier/CaissierDashboardScreen.dart';
import 'package:rusa/screens/caissier/CaissierProfileScreen.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';

class CaissierNavigationWrapper extends StatefulWidget {
  const CaissierNavigationWrapper({super.key});

  @override
  State<CaissierNavigationWrapper> createState() =>
      _CaissierNavigationWrapperState();
}

class _CaissierNavigationWrapperState extends State<CaissierNavigationWrapper> {
  int _index = 0;

  final List<Widget> _screens = const [
    CaissierDashboardScreen(),
    AllVoyagesScreen(showBack: false),
    CaissierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF222222),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_filled_outlined),
            label: 'Voyages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
