import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Vérifie si les services de localisation sont activés
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Demande les permissions
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Récupère la position actuelle
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // Convertit les coordonnées en adresse
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty) {
        final place = places.first;
        return [
          if (place.street != null) place.street,
          if (place.postalCode != null) place.postalCode,
          if (place.locality != null) place.locality,
        ].where((part) => part != null).join(', ');
      }
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      throw Exception('Erreur de géocodage: $e');
    }
  }

  // Convertit une adresse en coordonnées
  static Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de géocodage inverse: $e');
    }
  }
}
