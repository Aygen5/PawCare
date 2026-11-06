import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/domain/entities/booking.dart';
import 'package:paw_care/domain/services/booking_conflict_service.dart';

void main() {
  group('Faz 6.1: Rezervasyon Motoru ve Takvim Doluluk / Çakışma Testleri', () {
    test('isSameDay aynı günleri doğru tespit etmelidir', () {
      final d1 = DateTime(2026, 11, 6, 10, 30);
      final d2 = DateTime(2026, 11, 6, 22, 15);
      final d3 = DateTime(2026, 11, 7, 10, 30);

      expect(BookingConflictService.isSameDay(d1, d2), isTrue);
      expect(BookingConflictService.isSameDay(d1, d3), isFalse);
    });

    test('checkRangeOverlap çakışan ve çakışmayan aralıkları doğru ayırt etmelidir', () {
      // 10-15 Kasım ile 12-18 Kasım (çakışır)
      expect(
        BookingConflictService.checkRangeOverlap(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 15),
          DateTime(2026, 11, 12),
          DateTime(2026, 11, 18),
        ),
        isTrue,
      );

      // 10-15 Kasım ile 16-20 Kasım (çakışmaz)
      expect(
        BookingConflictService.checkRangeOverlap(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 15),
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 20),
        ),
        isFalse,
      );
    });

    test('hasConflict sadece onaylanmış (confirmed) rezervasyonları çakışma saymalıdır', () {
      final confirmedBooking = BookingRequest(
        id: 'b1',
        sitterId: 'sitter_1',
        sitterName: 'Mert Demir',
        sitterPhoto: 'assets/images/mert.jpg',
        petName: 'Barley',
        petBreed: 'Golden Retriever',
        serviceTitle: 'Köpek Oteli',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 14),
        totalPrice: 1200,
        careNotes: '',
        status: BookingStatus.confirmed,
      );

      final pendingBooking = BookingRequest(
        id: 'b2',
        sitterId: 'sitter_1',
        sitterName: 'Mert Demir',
        sitterPhoto: 'assets/images/mert.jpg',
        petName: 'Luna',
        petBreed: 'Poodle',
        serviceTitle: 'Yürüyüş',
        startDate: DateTime(2026, 11, 20),
        endDate: DateTime(2026, 11, 22),
        totalPrice: 400,
        careNotes: '',
        status: BookingStatus.pending,
      );

      final List<BookingRequest> existing = [confirmedBooking, pendingBooking];

      // Onaylı rezervasyon ile çakışan aralık (12-16 Kasım) -> ÇAKIŞMA VAR
      final conflict1 = BookingConflictService.hasConflict(
        requestedStart: DateTime(2026, 11, 12),
        requestedEnd: DateTime(2026, 11, 16),
        existingBookings: existing,
        sitterId: 'sitter_1',
      );
      expect(conflict1, isTrue);

      // Sadece bekleyen (pending) rezervasyon ile çakışan aralık (20-22 Kasım) -> ÇAKIŞMA YOK (henüz onaylanmadı)
      final conflict2 = BookingConflictService.hasConflict(
        requestedStart: DateTime(2026, 11, 20),
        requestedEnd: DateTime(2026, 11, 22),
        existingBookings: existing,
        sitterId: 'sitter_1',
      );
      expect(conflict2, isFalse);

      // Farklı bir bakıcı için sorgulandığında -> ÇAKIŞMA YOK
      final conflict3 = BookingConflictService.hasConflict(
        requestedStart: DateTime(2026, 11, 12),
        requestedEnd: DateTime(2026, 11, 16),
        existingBookings: existing,
        sitterId: 'sitter_2',
      );
      expect(conflict3, isFalse);
    });

    test('isDayOccupied ve getOccupiedDaysSet dolu günleri doğru listelemelidir', () {
      final booking = BookingRequest(
        id: 'b1',
        sitterId: 'sitter_1',
        sitterName: 'Mert Demir',
        sitterPhoto: 'assets/images/mert.jpg',
        petName: 'Barley',
        petBreed: 'Golden Retriever',
        serviceTitle: 'Köpek Oteli',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 12),
        totalPrice: 800,
        careNotes: '',
        status: BookingStatus.confirmed,
      );

      expect(
        BookingConflictService.isDayOccupied(
          DateTime(2026, 11, 11),
          [booking],
          sitterId: 'sitter_1',
        ),
        isTrue,
      );

      expect(
        BookingConflictService.isDayOccupied(
          DateTime(2026, 11, 13),
          [booking],
          sitterId: 'sitter_1',
        ),
        isFalse,
      );

      final set = BookingConflictService.getOccupiedDaysSet([booking]);
      expect(set.length, 3); // 10, 11, 12 Kasım
    });
  });
}
