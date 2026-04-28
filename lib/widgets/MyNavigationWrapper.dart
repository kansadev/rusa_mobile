import 'package:flutter/material.dart';
import 'package:rusa/screens/client/AcceuilScreen.dart';
import 'package:rusa/screens/client/AllVoyagesScreen.dart';
import 'package:rusa/screens/client/ReservationsScreen.dart';
import 'package:rusa/screens/client/ProfileScreen.dart';

class MyNavigationWrapper extends StatefulWidget {
  const MyNavigationWrapper({super.key});

  @override
  State<MyNavigationWrapper> createState() => _MyNavigationWrapperState();
}

class _MyNavigationWrapperState extends State<MyNavigationWrapper> {
  // Index pour la navigation
  int _bottomNavIndex = 0;

  // Liste des écrans correspondants
  final List<Widget> _screens = [
    const SearchTripScreen(),
    const AllVoyagesScreen(),
    const ReservationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_bottomNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),

        // Couleurs et styles adaptées au thème de l'app
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF222222),
        type: BottomNavigationBarType.fixed,

        // Icônes et labels
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
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],

        // Style du texte
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),

        // Élévation
        elevation: 8,
      ),
    );
  }
}
