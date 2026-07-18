import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/models.dart';

enum LocationAccess {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

abstract interface class LocationService {
  Future<LocationAccess> checkAccess();
  Future<LocationAccess> ensureAccess();
  Future<LocationReading> current();
  Future<void> openSettings();
  Stream<LocationReading> watch();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 2,
  );

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return switch (await Geolocator.checkPermission()) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Future<LocationReading> current() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings,
    );
    return _fromPosition(position);
  }

  @override
  Future<void> openSettings() async {
    final access = await checkAccess();
    if (access == LocationAccess.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Stream<LocationReading> watch() => Geolocator.getPositionStream(
    locationSettings: _settings,
  ).map(_fromPosition);

  LocationReading _fromPosition(Position position) => LocationReading(
    accuracy: position.accuracy,
    latitude: position.latitude,
    longitude: position.longitude,
    recordedAt: position.timestamp,
    speed: position.speed < 0 ? 0 : position.speed,
  );
}

class DemoLocationService implements LocationService {
  const DemoLocationService();

  @override
  Future<LocationAccess> checkAccess() async => LocationAccess.granted;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;

  @override
  Future<LocationReading> current() async => _reading(0);

  @override
  Future<void> openSettings() async {}

  @override
  Stream<LocationReading> watch() => Stream<LocationReading>.periodic(
    const Duration(seconds: 1),
    _reading,
  );

  LocationReading _reading(int tick) => LocationReading(
    accuracy: 4.2,
    latitude: 35.15958 + tick * 0.000018,
    longitude: 126.85261 + tick * 0.000027,
    recordedAt: DateTime.now().toUtc(),
    speed: 1.05,
  );
}
