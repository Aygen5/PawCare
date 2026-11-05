import '../entities/booking.dart';

/// Rezervasyon işlemlerini ve kurallarını tanımlayan soyut Domain sözleşmesi.
abstract class BookingRepositoryInterface {
  /// Başlangıç tarihine göre sıralanmış tüm rezervasyonları asenkron getirir.
  Future<List<BookingRequest>> getAllBookings();

  /// Belirli bir duruma (onaylandı/bekliyor/reddedildi vb.) göre filtrelenmiş rezervasyonları asenkron getirir.
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status);

  /// Rezervasyon akışını gerçek zamanlı dinlemek için Stream sağlar.
  Stream<List<BookingRequest>> watchBookings();

  /// Yeni bir rezervasyon talebi kaydeder.
  Future<void> addBooking(BookingRequest booking);

  /// Rezervasyonun durumunu günceller.
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus);

  /// Rezervasyonu siler.
  Future<void> deleteBooking(String bookingId);
}
