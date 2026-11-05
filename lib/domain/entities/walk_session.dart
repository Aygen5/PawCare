import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'walk_point.dart';

/// Canlı yürüyüş oturumu entity'si.
/// Sitter GPS verilerini Firestore'a akıtırken köpek sahibi bu oturumu izler.
class WalkSession {
  final String id;
  final String bookingId;
  final String sitterId;
  final String sitterName;
  final String dogId;
  final String dogName;
  final bool isActive;
  final double currentLatitude;
  final double currentLongitude;
  final double totalDistanceMeters;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<WalkPoint> routePoints;

  const WalkSession({
    required this.id,
    required this.bookingId,
    required this.sitterId,
    required this.sitterName,
    required this.dogId,
    required this.dogName,
    required this.isActive,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.totalDistanceMeters,
    required this.startedAt,
    this.endedAt,
    this.routePoints = const [],
  });

  /// Mesafeyi kilometre formatında verir (örn. 1.45)
  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  /// Geçen toplam yürüyüş süresi
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Süre formatı (örn: "24 dakika" veya "00:24:12")
  String get durationFormatted {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Mesafe formatı (örn: "1.4 km" veya "450 m")
  String get distanceFormatted {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${totalDistanceMeters.toInt()} m';
  }

  /// Haritada çizim için LatLng listesi
  List<LatLng> get routeCoordinates {
    if (routePoints.isEmpty) {
      return [LatLng(currentLatitude, currentLongitude)];
    }
    return routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  /// Mevcut güncel LatLng
  LatLng get currentLatLng => LatLng(currentLatitude, currentLongitude);

  /// Başlangıç LatLng
  LatLng? get startLatLng {
    if (routePoints.isEmpty) return LatLng(currentLatitude, currentLongitude);
    final first = routePoints.first;
    return LatLng(first.latitude, first.longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'sitterId': sitterId,
      'sitterName': sitterName,
      'dogId': dogId,
      'dogName': dogName,
      'isActive': isActive,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'totalDistanceMeters': totalDistanceMeters,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'coordinates': routePoints.map((p) => p.toMap()).toList(),
    };
  }

  factory WalkSession.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final rawCoordinates = map['coordinates'] as List<dynamic>? ?? [];
    final parsedRoute = rawCoordinates
        .whereType<Map<String, dynamic>>()
        .map((p) => WalkPoint.fromMap(p))
        .toList();

    return WalkSession(
      id: docId ?? map['id'] ?? map['bookingId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      sitterId: map['sitterId'] ?? '',
      sitterName: map['sitterName'] ?? 'Bakıcı',
      dogId: map['dogId'] ?? '',
      dogName: map['dogName'] ?? 'Dostumuz',
      isActive: map['isActive'] as bool? ?? false,
      currentLatitude: (map['currentLatitude'] as num?)?.toDouble() ?? 40.9632,
      currentLongitude: (map['currentLongitude'] as num?)?.toDouble() ?? 29.0621,
      totalDistanceMeters: (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      startedAt: parseTime(map['startedAt'], DateTime.now()),
      endedAt: map['endedAt'] != null ? parseTime(map['endedAt'], DateTime.now()) : null,
      routePoints: parsedRoute,
    );
  }

  WalkSession copyWith({
    String? id,
    String? bookingId,
    String? sitterId,
    String? sitterName,
    String? dogId,
    String? dogName,
    bool? isActive,
    double? currentLatitude,
    double? currentLongitude,
    double? totalDistanceMeters,
    DateTime? startedAt,
    DateTime? endedAt,
    List<WalkPoint>? routePoints,
  }) {
    return WalkSession(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      sitterId: sitterId ?? this.sitterId,
      sitterName: sitterName ?? this.sitterName,
      dogId: dogId ?? this.dogId,
      dogName: dogName ?? this.dogName,
      isActive: isActive ?? this.isActive,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}

