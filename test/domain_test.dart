import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/domain/domain.dart';

// Test amaçlı fake Sitter repository sözleşmesi implementasyonu
class FakeSitterRepository implements SitterRepositoryInterface {
  final List<SitterListing> sitters;

  FakeSitterRepository(this.sitters);

  @override
  Future<List<SitterListing>> getSitters({bool forceRefresh = false}) async {
    return sitters;
  }

  @override
  Future<List<SitterListing>> searchSitters({
    String category = 'Tümü',
    String query = '',
  }) async {
    return sitters.where((s) {
      final matchesCat = category == 'Tümü' || s.category == category;
      final matchesQ = query.isEmpty || s.name.contains(query);
      return matchesCat && matchesQ;
    }).toList();
  }

  @override
  Future<SitterListing?> getSitterById(String id) async {
    try {
      return sitters.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Test amaçlı fake Booking repository sözleşmesi implementasyonu
class FakeBookingRepository implements BookingRepositoryInterface {
  final List<BookingRequest> bookings = [];

  @override
  Future<List<BookingRequest>> getAllBookings() async =>
      List.unmodifiable(bookings);

  @override
  Future<List<BookingRequest>> getBookingsByStatus(
    BookingStatus status,
  ) async {
    return bookings.where((b) => b.status == status).toList();
  }

  @override
  Stream<List<BookingRequest>> watchBookings() => Stream.value(bookings);

  @override
  Future<void> addBooking(BookingRequest booking) async {
    bookings.add(booking);
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      bookings[idx] = bookings[idx].copyWith(status: newStatus);
    }
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    bookings.removeWhere((b) => b.id == bookingId);
  }
}

void main() {
  group('Clean Architecture: Domain Katmanı Varlık (Entity) Testleri', () {
    test('UserRole saf Dart enum değerleri doğrulanır', () {
      expect(UserRole.values, contains(UserRole.owner));
      expect(UserRole.values, contains(UserRole.sitter));
    });

    test('BookingStatus saf Dart enum değerleri doğrulanır', () {
      expect(BookingStatus.values.length, 4);
      expect(BookingStatus.pending.name, 'pending');
      expect(BookingStatus.confirmed.name, 'confirmed');
    });

    test('VaccineStatus saf Dart enum değerleri doğrulanır', () {
      expect(VaccineStatus.values.length, 3);
      expect(VaccineStatus.upcoming.name, 'upcoming');
    });

    test(
      'Dog Entity saf Dart nesnesi olarak oluşturulabilir ve kopyalanabilir',
      () {
        const dog = Dog(
          id: 'dog_test',
          name: 'Pamuk',
          breed: 'Poodle',
          ageYears: 3,
          weightKg: 6.2,
          gender: 'Dişi',
          microchip: 'TR123456',
          photoPath: 'assets/images/barley.jpg',
          allergyNote: 'Yok',
          behaviorNote: 'Uysal',
          clinicName: 'Pati Kliniği',
          clinicPhone: '05551234567',
          vaccinations: [],
        );

        expect(dog.name, 'Pamuk');
        final updated = dog.copyWith(ageYears: 4);
        expect(updated.ageYears, 4);
        expect(updated.name, 'Pamuk');
      },
    );
  });

  group('Clean Architecture: Domain Katmanı Use Case Testleri', () {
    test('GetSittersUseCase ve SearchSittersUseCase repository sözleşmesi üzerinden çalışır', () async {
      const sampleSitter = SitterListing(
        id: 's_1',
        name: 'Mert Demir',
        facilityTitle: 'Kadıköy Butik Otel',
        category: 'Köpek Oteli',
        rating: 4.9,
        reviewsCount: 38,
        pricePerUnit: 650,
        unitLabel: 'gece',
        location: 'Kadıköy',
        distanceKm: 1.2,
        imagePath: 'assets/images/mert.jpg',
        galleryPaths: [],
        bio: 'Deneyimli bakıcı',
        amenities: ['Geniş Bahçe'],
      );

      final fakeRepo = FakeSitterRepository([sampleSitter]);
      final getSittersUseCase = GetSittersUseCase(fakeRepo);
      final searchSittersUseCase = SearchSittersUseCase(fakeRepo);

      final list = await getSittersUseCase();
      expect(list.length, 1);
      expect(list.first.name, 'Mert Demir');

      final searchResult = await searchSittersUseCase(category: 'Köpek Oteli');
      expect(searchResult.length, 1);

      final emptyResult = await searchSittersUseCase(category: 'Gündüz Bakımı');
      expect(emptyResult.isEmpty, true);
    });

    test(
      'CreateBookingUseCase ve GetBookingsUseCase rezervasyon akışını yönetir',
      () async {
        final fakeRepo = FakeBookingRepository();
        final createBooking = CreateBookingUseCase(fakeRepo);
        final getBookings = GetBookingsUseCase(fakeRepo);
        final manageBooking = ManageBookingStatusUseCase(fakeRepo);

        final booking = BookingRequest(
          id: 'b_1',
          sitterId: 's_1',
          sitterName: 'Mert Demir',
          sitterPhoto: 'assets/images/mert.jpg',
          petName: 'Barley',
          petBreed: 'Golden Retriever',
          serviceTitle: 'Köpek Oteli',
          startDate: DateTime(2026, 10, 25),
          endDate: DateTime(2026, 10, 27),
          totalPrice: 1300,
          careNotes: 'Alerjisi var',
          status: BookingStatus.pending,
        );

        await createBooking(booking);
        expect((await getBookings()).length, 1);
        expect((await getBookings(filterStatus: BookingStatus.pending)).length, 1);

        await manageBooking.updateStatus('b_1', BookingStatus.confirmed);
        expect((await getBookings(filterStatus: BookingStatus.confirmed)).length, 1);
        expect((await getBookings(filterStatus: BookingStatus.pending)).length, 0);
      },
    );

    test('GetAppSettingsUseCase ve UpdateAppSettingsUseCase sözleşme üzerinden ayarları yönetir', () async {
      final settingsRepo = SettingsRepository.inMemory();
      final getSettings = GetAppSettingsUseCase(settingsRepo);
      final updateSettings = UpdateAppSettingsUseCase(settingsRepo);

      expect(getSettings.getThemeMode(), 'system');
      expect(getSettings.getUserRole(), 'owner');
      expect(getSettings.hasSeenOnboarding(), false);

      await updateSettings.setThemeMode('dark');
      await updateSettings.setUserRole('sitter');
      await updateSettings.setHasSeenOnboarding(true);

      expect(getSettings.getThemeMode(), 'dark');
      expect(getSettings.getUserRole(), 'sitter');
      expect(getSettings.hasSeenOnboarding(), true);
    });
  });
}
