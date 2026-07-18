const earthRadiusMeters = 6_371_000;

const radians = (degrees: number): number => (degrees * Math.PI) / 180;

export function distanceMeters(
  first: { latitude: number; longitude: number },
  second: { latitude: number; longitude: number },
): number {
  const latitudeDelta = radians(second.latitude - first.latitude);
  const longitudeDelta = radians(second.longitude - first.longitude);
  const firstLatitude = radians(first.latitude);
  const secondLatitude = radians(second.latitude);

  const haversine =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(firstLatitude) *
      Math.cos(secondLatitude) *
      Math.sin(longitudeDelta / 2) ** 2;

  return (
    2 *
    earthRadiusMeters *
    Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))
  );
}

export function offsetMidpoint(
  origin: { latitude: number; longitude: number },
  destination: { latitude: number; longitude: number },
  offsetMeters: number,
): { latitude: number; longitude: number } {
  const latitude = (origin.latitude + destination.latitude) / 2;
  const longitude = (origin.longitude + destination.longitude) / 2;
  const latitudeOffset = offsetMeters / 111_320;
  const longitudeOffset =
    offsetMeters / (111_320 * Math.max(Math.cos(radians(latitude)), 0.2));

  return {
    latitude: latitude + latitudeOffset,
    longitude: longitude - longitudeOffset,
  };
}
