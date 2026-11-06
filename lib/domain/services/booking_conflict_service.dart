import '../entities/booking.dart';

/// Rezervasyon tarih aralıkları ve takvim doluluk çakışmalarını denetleyen iş motoru.
class BookingConflictService {
  /// İki tarihin aynı takvim gününe (yıl, ay, gün) denk gelip gelmediğini denetler.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Verilen tarih aralığının başlangıç ve bitişini günün başına (00:00:00) ve sonuna (23:59:59) normalize eder.
  static (DateTime, DateTime) normalizeDateRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return s.isBefore(e) ? (s, e) : (e, s);
  }

  /// İki tarih aralığının kesişip kesişmediğini denetler.
  static bool checkRangeOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    final (s1, e1) = normalizeDateRange(start1, end1);
    final (s2, e2) = normalizeDateRange(start2, end2);

    // Kesişme kuralı: [s1, e1] ve [s2, e2] aralıkları
    return !s1.isAfter(e2) && !s2.isAfter(e1);
  }

  /// Belirli bir günün onaylanmış (confirmed) rezervasyonlar nedeniyle dolu olup olmadığını kontrol eder.
  static bool isDayOccupied(
    DateTime day,
    List<BookingRequest> existingBookings, {
    String? sitterId,
  }) {
    final target = DateTime(day.year, day.month, day.day);

    for (final b in existingBookings) {
      if (sitterId != null && b.sitterId != sitterId) continue;
      if (b.status != BookingStatus.confirmed) continue;

      final start = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
      final end = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);

      if (!target.isBefore(start) && !target.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  /// Talep edilen yeni rezervasyon tarih aralığının mevcut onaylı rezervasyonlarla çakışıp çakışmadığını denetler.
  static bool hasConflict({
    required DateTime requestedStart,
    required DateTime requestedEnd,
    required List<BookingRequest> existingBookings,
    String? sitterId,
  }) {
    for (final b in existingBookings) {
      if (sitterId != null && b.sitterId != sitterId) continue;
      if (b.status != BookingStatus.confirmed) continue;

      final overlaps = checkRangeOverlap(
        requestedStart,
        requestedEnd,
        b.startDate,
        b.endDate,
      );

      if (overlaps) {
        return true;
      }
    }
    return false;
  }

  /// Bakıcının tüm onaylı rezervasyon tarihlerini set halinde döner.
  static Set<DateTime> getOccupiedDaysSet(
    List<BookingRequest> existingBookings, {
    String? sitterId,
  }) {
    final occupied = <DateTime>{};

    for (final b in existingBookings) {
      if (sitterId != null && b.sitterId != sitterId) continue;
      if (b.status != BookingStatus.confirmed) continue;

      var current = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
      final end = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);

      while (!current.isAfter(end)) {
        occupied.add(current);
        current = current.add(const Duration(days: 1));
      }
    }

    return occupied;
  }
}
