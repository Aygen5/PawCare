import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart' as model;
import 'booking_repository.dart';

/// Cloud Firestore ve Hive L1 Önbellek (Offline-First) destekli Rezervasyon Deposu.
class FirebaseBookingRepository implements BookingRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseAuth? _firebaseAuthInstance;
  final BookingRepository _localRepo;

  FirebaseBookingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    BookingRepository? localRepo,
  }) : _firestoreInstance = firestore,
       _firebaseAuthInstance = firebaseAuth,
       _localRepo = localRepo ?? BookingRepository();

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  FirebaseAuth? get _firebaseAuth {
    if (_firebaseAuthInstance != null) return _firebaseAuthInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  @override
  Future<List<BookingRequest>> getAllBookings() async {
    // 1. Önce L1 Cache (Hive) hemen döndürülür (0 ms gecikme)
    final cached = await _localRepo.getAllBookings();

    // 2. Arka planda Firestore verisi çekilir ve senkronize edilir
    try {
      final fs = _firestore;
      if (fs != null) {
        final query = fs.collection('bookings');
        final snapshot = await query.get();

        if (snapshot.docs.isNotEmpty) {
          final remoteBookings = snapshot.docs.map((doc) {
            return BookingRequest.fromMap(doc.data(), docId: doc.id);
          }).toList();

          await _syncToHive(remoteBookings);
          return remoteBookings;
        }
      }
    } catch (_) {
      // Çevrimdışı durumunda önbellekteki veriler kullanılır
    }

    return cached;
  }

  @override
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status) async {
    final all = await getAllBookings();
    return all.where((b) => b.status == status).toList();
  }

  @override
  Stream<List<BookingRequest>> watchBookings() {
    try {
      final fs = _firestore;
      if (fs != null) {
        final query = fs.collection('bookings');
        return query.snapshots().map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BookingRequest.fromMap(doc.data(), docId: doc.id);
          }).toList();

          // L1 Cache'i güncelle
          _syncToHive(list);
          return list;
        });
      }
    } catch (_) {}

    // Fallback: Yerel Hive akışı
    return _localRepo.watchBookings();
  }

  @override
  Future<void> addBooking(BookingRequest booking) async {
    final currentUid = _getCurrentUserId();
    final enriched = booking.copyWith(
      ownerId: booking.ownerId ?? currentUid,
      createdAt: booking.createdAt ?? DateTime.now(),
    );

    // 1. Önce L1 Cache'e yaz
    await _localRepo.addBooking(enriched);

    // 2. Buluta (Firestore) yaz
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs
            .collection('bookings')
            .doc(enriched.id)
            .set(enriched.toMap());
      }
    } catch (_) {
      // Çevrimdışı yazma — Hive'da saklandı
    }
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    // 1. Önce L1 Cache'i güncelle
    await _localRepo.updateBookingStatus(bookingId, newStatus);

    // 2. Firestore'u güncelle
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('bookings').doc(bookingId).update({
          'status': newStatus.name,
        });
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    await _localRepo.deleteBooking(bookingId);
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('bookings').doc(bookingId).delete();
      }
    } catch (_) {}
  }

  String? _getCurrentUserId() {
    try {
      return _firebaseAuth?.currentUser?.uid;
    } catch (_) {}
    return null;
  }

  Future<void> _syncToHive(List<BookingRequest> bookings) async {
    try {
      if (Hive.isBoxOpen(HiveBoxes.bookingsBox)) {
        for (final b in bookings) {
          final modelItem = model.BookingRequest.fromEntity(b);
          await HiveBoxes.bookings.put(modelItem.id, modelItem);
        }
      }
    } catch (_) {}
  }
}
