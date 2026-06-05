import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Résultat de la résolution de la ville de l'utilisateur.
class CityResult {
  final bool success;
  final String? city;
  final String? error;

  const CityResult({required this.success, this.city, this.error});

  factory CityResult.ok(String city) => CityResult(success: true, city: city);
  factory CityResult.fail(String error) =>
      CityResult(success: false, error: error);
}

/// Service de géolocalisation : détermine la ville courante de l'utilisateur.
class LocationService {
  LocationService._();

  /// Récupère la ville (locality) à partir de la position GPS actuelle.
  static Future<CityResult> getCurrentCity() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return CityResult.fail(
          'La localisation est désactivée. Activez le GPS puis réessayez.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return CityResult.fail('Permission de localisation refusée.');
      }
      if (permission == LocationPermission.deniedForever) {
        return CityResult.fail(
          'Permission de localisation refusée définitivement. '
          'Activez-la dans les paramètres.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return CityResult.fail('Impossible de déterminer votre ville.');
      }

      final p = placemarks.first;
      final city = _bestCity(p);
      if (city == null || city.trim().isEmpty) {
        return CityResult.fail('Ville introuvable à partir de votre position.');
      }
      return CityResult.ok(city.trim());
    } catch (e) {
      debugPrint('LocationService.getCurrentCity: $e');
      return CityResult.fail('Erreur de localisation : $e');
    }
  }

  /// Choisit le meilleur champ représentant la « ville ».
  static String? _bestCity(Placemark p) {
    final candidates = <String?>[
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
      p.subLocality,
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c;
    }
    return null;
  }
}
