import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS Konum Servisi.
/// Gerçek GPS donanımından konum akışı alır; izin ve servis kontrollerini yönetir.
/// Masaüstü, emülatör ve testler için gerçekçi bir simülasyon akışı da sunar.
class LocationService {
  final bool isSimulationMode;

  LocationService({this.isSimulationMode = false});

  /// Konum servislerinin (GPS) açık olup olmadığını denetler.
  Future<bool> isLocationServiceEnabled() async {
    if (isSimulationMode) return true;
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Location service check error: $e');
      return false;
    }
  }

  /// Konum izinlerini kontrol eder ve gerekirse kullanıcıdan izin talep eder.
  /// İzin verildiyse true döner.
  Future<bool> checkAndRequestPermission() async {
    if (isSimulationMode) return true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Location permission error: $e');
      return false;
    }
  }

  /// Mevcut anlık konumu döndürür.
  Future<Position?> getCurrentPosition() async {
    if (isSimulationMode) {
      return Position(
        latitude: 40.9632,
        longitude: 29.0621,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 90.0,
        headingAccuracy: 1.0,
        speed: 1.2,
        speedAccuracy: 0.2,
      );
    }

    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Get current position error: $e');
      return null;
    }
  }

  /// Gerçek zamanlı GPS akışı. distanceFilter metrede bir yeni nokta tetiklenir.
  Stream<Position> getPositionStream({int distanceFilter = 3}) {
    if (isSimulationMode) {
      return getSimulatedPositionStream();
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// İki koordinat noktası arasındaki mesafeyi metre cinsinden hesaplar.
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Caddebostan Sahil hattı boyunca simüle edilmiş gerçekçi yürüyüş koordinat akışı.
  Stream<Position> getSimulatedPositionStream({
    Duration interval = const Duration(seconds: 3),
  }) {
    // Caddebostan Sahil Parkı yürüyüş parkuru koordinatları
    final waypoints = [
      (40.96320, 29.06210),
      (40.96345, 29.06255),
      (40.96380, 29.06310),
      (40.96415, 29.06370),
      (40.96450, 29.06430),
      (40.96485, 29.06495),
      (40.96520, 29.06560),
      (40.96555, 29.06625),
      (40.96590, 29.06690),
      (40.96620, 29.06750),
      (40.96595, 29.06810),
      (40.96560, 29.06860),
    ];

    int index = 0;
    return Stream.periodic(interval, (count) {
      final point = waypoints[index % waypoints.length];
      index++;

      return Position(
        latitude: point.$1,
        longitude: point.$2,
        timestamp: DateTime.now(),
        accuracy: 4.5,
        altitude: 12.0,
        altitudeAccuracy: 1.0,
        heading: 45.0,
        headingAccuracy: 1.0,
        speed: 1.35, // ~4.8 km/s tipik köpek gezdirme hızı
        speedAccuracy: 0.1,
      );
    }).asBroadcastStream();
  }
}

