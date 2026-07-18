import 'dart:math' as math;

double distanceMeters({
  required double firstLatitude,
  required double firstLongitude,
  required double secondLatitude,
  required double secondLongitude,
}) {
  const earthRadius = 6371000.0;
  double radians(double degrees) => degrees * math.pi / 180;
  final latitudeDelta = radians(secondLatitude - firstLatitude);
  final longitudeDelta = radians(secondLongitude - firstLongitude);
  final firstLat = radians(firstLatitude);
  final secondLat = radians(secondLatitude);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(firstLat) *
          math.cos(secondLat) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return 2 *
      earthRadius *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}
