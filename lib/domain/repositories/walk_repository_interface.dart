import '../entities/walk_point.dart';
import '../entities/walk_session.dart';

/// Yürüyüş oturumları ve anlık GPS akışlarının repository sözleşmesi.
abstract class WalkRepositoryInterface {
  /// Yeni bir yürüyüş başlatır ve ilk konumu kaydeder.
  Future<WalkSession> startWalk({
    required String bookingId,
    required String sitterId,
    required String sitterName,
    required String dogId,
    required String dogName,
    required double initialLat,
    required double initialLng,
  });

  /// Belirtilen yürüyüş oturumunu gerçek zamanlı (Stream) olarak dinler.
  Stream<WalkSession?> watchWalk(String bookingOrWalkId);

  /// Tek seferlik yürüyüş verisini çeker.
  Future<WalkSession?> getWalk(String bookingOrWalkId);

  /// Yürüyüşe yeni bir GPS koordinatı ekler ve toplam mesafeyi günceller.
  Future<void> updateWalkLocation({
    required String walkId,
    required WalkPoint point,
    required double addedDistanceMeters,
  });

  /// Yürüyüşü tamamlar (`isActive = false`, `endedAt = now`).
  Future<WalkSession> endWalk(String walkId);
}

