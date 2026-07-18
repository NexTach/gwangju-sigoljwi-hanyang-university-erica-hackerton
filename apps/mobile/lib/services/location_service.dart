import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';
import '../core/models.dart';
import '../demo/yongbong_demo_data.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

abstract interface class LocationService {
  Future<LocationAccess> checkAccess();
  Future<LocationAccess> ensureAccess();
  Future<LocationReading> current();
  Future<void> openSettings();
  Stream<LocationReading> watch();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  LocationSettings _settings({required bool current}) {
    final timeLimit = current ? const Duration(seconds: 12) : null;
    if (kIsWeb) {
      return LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        timeLimit: timeLimit,
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 1),
        timeLimit: timeLimit,
      ),
      TargetPlatform.iOS || TargetPlatform.macOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        timeLimit: timeLimit,
      ),
      _ => LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        timeLimit: timeLimit,
      ),
    };
  }

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
      locationSettings: _settings(current: true),
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
    locationSettings: _settings(current: false),
  ).map(_fromPosition);

  LocationReading _fromPosition(Position position) => LocationReading(
    accuracy: position.accuracy,
    heading: position.heading >= 0 && position.heading.isFinite
        ? position.heading
        : null,
    isMocked: position.isMocked,
    latitude: position.latitude,
    longitude: position.longitude,
    recordedAt: position.timestamp,
    speed: position.speed < 0 ? 0 : position.speed,
    speedAccuracy:
        position.speedAccuracy >= 0 && position.speedAccuracy.isFinite
        ? position.speedAccuracy
        : null,
  );
}

class DemoLocationService implements LocationService {
  const DemoLocationService({
    this.path = YongbongDemoData.demoGpsPath,
    this.playbackInterval = const Duration(seconds: 1),
    this.speedMetersPerSecond = 1.05,
  });

  final List<({double latitude, double longitude})> path;
  final Duration playbackInterval;
  final double speedMetersPerSecond;

  DemoLocationService followingRoute(
    List<({double latitude, double longitude})> coordinates,
  ) => DemoLocationService(
    path: coordinates.length >= 2 ? coordinates : path,
    playbackInterval: playbackInterval,
    speedMetersPerSecond: speedMetersPerSecond,
  );

  @override
  Future<LocationAccess> checkAccess() async => LocationAccess.granted;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;

  @override
  Future<LocationReading> current() async =>
      _reading(Duration.zero, DateTime.now().toUtc());

  @override
  Future<void> openSettings() async {}

  @override
  Stream<LocationReading> watch() {
    final startedAt = DateTime.now().toUtc();
    return Stream<LocationReading>.periodic(playbackInterval, (tick) {
      final elapsed = playbackInterval * (tick + 1);
      return _reading(elapsed, startedAt.add(elapsed));
    });
  }

  LocationReading _reading(Duration elapsed, DateTime recordedAt) {
    final elapsedSeconds =
        elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final point = _pointAtDistance(elapsedSeconds * speedMetersPerSecond);
    return LocationReading(
      accuracy: 4.2,
      isMocked: true,
      latitude: point.latitude,
      longitude: point.longitude,
      recordedAt: recordedAt,
      speed: speedMetersPerSecond,
      speedAccuracy: 0.1,
    );
  }

  ({double latitude, double longitude}) _pointAtDistance(double distance) {
    if (path.length < 2) return path.first;
    final segments =
        <
          ({
            double length,
            double startLat,
            double startLng,
            double endLat,
            double endLng,
          })
        >[];
    var totalLength = 0.0;
    for (var index = 0; index < path.length - 1; index += 1) {
      final start = path[index];
      final end = path[index + 1];
      final length = distanceMeters(
        firstLatitude: start.latitude,
        firstLongitude: start.longitude,
        secondLatitude: end.latitude,
        secondLongitude: end.longitude,
      );
      segments.add((
        length: length,
        startLat: start.latitude,
        startLng: start.longitude,
        endLat: end.latitude,
        endLng: end.longitude,
      ));
      totalLength += length;
    }
    if (totalLength == 0) return path.first;

    // Walk the same road geometry in reverse after reaching the end. Closing
    // the loop with a last-to-first chord would cut across buildings.
    var remaining = distance % (totalLength * 2);
    if (remaining > totalLength) {
      remaining = totalLength * 2 - remaining;
    }
    for (final segment in segments) {
      if (remaining <= segment.length || segment == segments.last) {
        final fraction = segment.length == 0 ? 0.0 : remaining / segment.length;
        return (
          latitude:
              segment.startLat + (segment.endLat - segment.startLat) * fraction,
          longitude:
              segment.startLng + (segment.endLng - segment.startLng) * fraction,
        );
      }
      remaining -= segment.length;
    }
    return path.first;
  }
}
