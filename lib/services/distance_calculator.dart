import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:livraisonb2b/models/order.dart'
    as my_models; // Ajouter un alias

class DistanceCalculator {
  static const double earthRadiusKm = 6371.0;

  static double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Utiliser l'alias my_models.Order
  static double? calculateOrderDistance(
    my_models.Order order,
    Position driverPosition,
  ) {
    if (order.deliveryLocation == null) return null;

    return calculateDistanceInMeters(
      driverPosition.latitude,
      driverPosition.longitude,
      order.deliveryLocation!.latitude,
      order.deliveryLocation!.longitude,
    );
  }

  static String formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return 'Distance inconnue';
    if (distanceInMeters < 1000) return '${distanceInMeters.round()} m';
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }
}
