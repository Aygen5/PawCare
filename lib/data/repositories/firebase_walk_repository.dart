import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/walk_point.dart';
import '../../domain/entities/walk_session.dart';
import '../../domain/repositories/walk_repository_interface.dart';

/// Firebase Firestore `live_walks` koleksiyonu ile çalışan yürüyüş repository'si.
/// Çevrimdışı ve test senaryoları için yerel bellek akışı (in-memory fallback) barındırır.
class FirebaseWalkRepository implements WalkRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final Map<String, WalkSession> _inMemorySessions = {};
  final Map<String, StreamController<WalkSession?>> _inMemoryControllers = {};

  FirebaseWalkRepository({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamController<WalkSession?> _getOrCreateController(String id) {
    return _inMemoryControllers.putIfAbsent(
      id,
      () => StreamController<WalkSession?>.broadcast(),
    );
  }

  @override
  Future<WalkSession> startWalk({
    required String bookingId,
    required String sitterId,
    required String sitterName,
    required String dogId,
    required String dogName,
    required double initialLat,
    required double initialLng,
  }) async {
    final now = DateTime.now();
    final firstPoint = WalkPoint(
      latitude: initialLat,
      longitude: initialLng,
      timestamp: now,
    );

    final session = WalkSession(
      id: bookingId,
      bookingId: bookingId,
      sitterId: sitterId,
      sitterName: sitterName,
      dogId: dogId,
      dogName: dogName,
      isActive: true,
      currentLatitude: initialLat,
      currentLongitude: initialLng,
      totalDistanceMeters: 0.0,
      startedAt: now,
      routePoints: [firstPoint],
    );

    _inMemorySessions[bookingId] = session;
    _getOrCreateController(bookingId).add(session);

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('live_walks').doc(bookingId).set(session.toMap());
      } catch (e) {
        debugPrint('Firestore startWalk error: $e');
      }
    }

    return session;
  }

  @override
  Stream<WalkSession?> watchWalk(String bookingOrWalkId) {
    final fs = _firestore;
    if (fs != null) {
      try {
        return fs
            .collection('live_walks')
            .doc(bookingOrWalkId)
            .snapshots()
            .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return _inMemorySessions[bookingOrWalkId];
          }
          final session = WalkSession.fromMap(
            snapshot.data()!,
            snapshot.id,
          );
          _inMemorySessions[bookingOrWalkId] = session;
          return session;
        }).handleError((error) {
          debugPrint('watchWalk firestore error, falling back to memory: $error');
          return _inMemorySessions[bookingOrWalkId];
        });
      } catch (e) {
        debugPrint('watchWalk init error: $e');
      }
    }

    // Yerel bellek akışı fallback
    final controller = _getOrCreateController(bookingOrWalkId);
    // Mevcut değer varsa ilk emit
    if (_inMemorySessions.containsKey(bookingOrWalkId)) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(_inMemorySessions[bookingOrWalkId]);
        }
      });
    }
    return controller.stream;
  }

  @override
  Future<WalkSession?> getWalk(String bookingOrWalkId) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('live_walks').doc(bookingOrWalkId).get();
        if (doc.exists && doc.data() != null) {
          final session = WalkSession.fromMap(doc.data()!, doc.id);
          _inMemorySessions[bookingOrWalkId] = session;
          return session;
        }
      } catch (e) {
        debugPrint('Firestore getWalk error: $e');
      }
    }

    return _inMemorySessions[bookingOrWalkId];
  }

  @override
  Future<void> updateWalkLocation({
    required String walkId,
    required WalkPoint point,
    required double addedDistanceMeters,
  }) async {
    // 1. Yerel durumu güncelle
    final current = _inMemorySessions[walkId];
    if (current != null) {
      final updatedPoints = List<WalkPoint>.from(current.routePoints)..add(point);
      final updated = current.copyWith(
        currentLatitude: point.latitude,
        currentLongitude: point.longitude,
        totalDistanceMeters: current.totalDistanceMeters + addedDistanceMeters,
        routePoints: updatedPoints,
      );
      _inMemorySessions[walkId] = updated;
      _getOrCreateController(walkId).add(updated);
    }

    // 2. Cloud Firestore'a yaz
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('live_walks').doc(walkId).update({
          'currentLatitude': point.latitude,
          'currentLongitude': point.longitude,
          'totalDistanceMeters': FieldValue.increment(addedDistanceMeters),
          'coordinates': FieldValue.arrayUnion([point.toMap()]),
        });
      } catch (e) {
        debugPrint('Firestore updateWalkLocation error: $e');
      }
    }
  }

  @override
  Future<WalkSession> endWalk(String walkId) async {
    final now = DateTime.now();
    final current = _inMemorySessions[walkId];
    final updated = (current != null)
        ? current.copyWith(isActive: false, endedAt: now)
        : WalkSession(
            id: walkId,
            bookingId: walkId,
            sitterId: '',
            sitterName: '',
            dogId: '',
            dogName: '',
            isActive: false,
            currentLatitude: 40.9632,
            currentLongitude: 29.0621,
            totalDistanceMeters: 0.0,
            startedAt: now,
            endedAt: now,
          );

    _inMemorySessions[walkId] = updated;
    _getOrCreateController(walkId).add(updated);

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('live_walks').doc(walkId).update({
          'isActive': false,
          'endedAt': now.millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint('Firestore endWalk error: $e');
      }
    }

    return updated;
  }
}

