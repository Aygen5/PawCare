import 'dart:async';

import 'package:hive/hive.dart';

import '../../domain/entities/booking.dart' as entity;
import '../../domain/repositories/booking_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart';

class BookingRepository implements BookingRepositoryInterface {
  final _bookingStreamController =
      StreamController<List<BookingRequest>>.broadcast();

  /// Başlangıç tarihine göre sıralı tüm rezervasyonları asenkron getirir.
  @override
  Future<List<BookingRequest>> getAllBookings() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.bookingsBox)) return [];
      final list = HiveBoxes.bookings.values.toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Belirli bir duruma göre filtrelenmiş rezervasyonları asenkron getirir.
  @override
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status) async {
    final all = await getAllBookings();
    return all.where((b) => b.status == status).toList();
  }

  /// Rezervasyon akışını yayınlar.
  @override
  Stream<List<BookingRequest>> watchBookings() {
    _notifyStream();
    return _bookingStreamController.stream;
  }

  Future<void> _notifyStream() async {
    final list = await getAllBookings();
    if (!_bookingStreamController.isClosed) {
      _bookingStreamController.add(list);
    }
  }

  /// Yeni bir rezervasyon talebi ekler.
  @override
  Future<void> addBooking(entity.BookingRequest booking) async {
    final modelItem = BookingRequest.fromEntity(booking);
    await HiveBoxes.bookings.put(modelItem.id, modelItem);
    await _notifyStream();
  }

  /// Rezervasyonun durumunu (onaylandı/reddedildi/tamamlandı) günceller.
  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    final booking = HiveBoxes.bookings.get(bookingId);
    if (booking != null) {
      final updated = booking.copyWith(status: newStatus);
      await HiveBoxes.bookings.put(bookingId, updated);
      await _notifyStream();
    }
  }

  /// Bir rezervasyon kaydını siler.
  @override
  Future<void> deleteBooking(String bookingId) async {
    await HiveBoxes.bookings.delete(bookingId);
    await _notifyStream();
  }
}
