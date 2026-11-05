import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/domain/repositories/booking_repository_interface.dart';
import 'package:paw_care/domain/repositories/sitter_repository_interface.dart';
import 'package:paw_care/domain/usecases/booking/create_booking_use_case.dart';
import 'package:paw_care/domain/usecases/sitter/get_sitters_use_case.dart';
import 'package:paw_care/domain/usecases/sitter/search_sitters_use_case.dart';
import 'package:paw_care/features/discovery/cubit/discovery_cubit.dart';
import 'package:paw_care/features/discovery/cubit/discovery_state.dart';
import 'package:paw_care/features/discovery/view/explore_screen.dart';
import 'package:paw_care/features/discovery/view/sitter_detail_screen.dart';

// Test için sahte SitterRepository
class FakeSitterRepository implements SitterRepositoryInterface {
  final List<SitterListing> _sitters;

  FakeSitterRepository(this._sitters);

  @override
  Future<List<SitterListing>> getSitters({bool forceRefresh = false}) async =>
      _sitters;

  @override
  Future<List<SitterListing>> searchSitters({
    String category = 'Tümü',
    String query = '',
  }) async {
    return _sitters.where((s) {
      final matchesCategory = category == 'Tümü' || s.category == category;
      final cleanQuery = query.trim().toLowerCase();
      final matchesSearch =
          cleanQuery.isEmpty ||
          s.name.toLowerCase().contains(cleanQuery) ||
          s.facilityTitle.toLowerCase().contains(cleanQuery) ||
          s.location.toLowerCase().contains(cleanQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Future<SitterListing?> getSitterById(String id) async =>
      _sitters.firstWhere((s) => s.id == id);
}

// Test için sahte BookingRepository
class FakeBookingRepository implements BookingRepositoryInterface {
  final List<BookingRequest> bookings = [];

  @override
  Future<List<BookingRequest>> getAllBookings() async => bookings;

  @override
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status) async =>
      bookings.where((b) => b.status == status).toList();

  @override
  Stream<List<BookingRequest>> watchBookings() => Stream.value(bookings);

  @override
  Future<void> addBooking(covariant BookingRequest booking) async {
    bookings.add(booking);
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {}

  @override
  Future<void> deleteBooking(String bookingId) async {}
}

void main() {
  group('Faz 4 Adım 4.3: DiscoveryCubit ve Ekran Testleri', () {
    late FakeSitterRepository fakeSitterRepo;
    late FakeBookingRepository fakeBookingRepo;

    final sitter1 = SitterListing(
      id: 'sitter_1',
      name: 'Ayşe Yılmaz',
      facilityTitle: 'Pati Dostları Butik Otel',
      category: 'Köpek Oteli',
      rating: 4.9,
      reviewsCount: 38,
      pricePerUnit: 450.0,
      unitLabel: 'gece',
      location: 'Moda, Kadıköy',
      distanceKm: 1.2,
      imagePath: 'assets/images/ayse.jpg',
      galleryPaths: ['assets/images/ayse.jpg'],
      bio: 'Geniş bahçeli evimde köpek konaklama hizmeti sunuyorum.',
      amenities: ['Geniş Bahçe', 'Veteriner Yakınında'],
      isVerified: true,
    );

    final sitter2 = SitterListing(
      id: 'sitter_2',
      name: 'Mert Demir',
      facilityTitle: 'Sahil Parkı Gezdiricisi',
      category: 'Köpek Gezdirme',
      rating: 5.0,
      reviewsCount: 42,
      pricePerUnit: 250.0,
      unitLabel: 'saat',
      location: 'Caddebostan, Kadıköy',
      distanceKm: 2.5,
      imagePath: 'assets/images/mert.jpg',
      galleryPaths: ['assets/images/mert.jpg'],
      bio: 'Tempolu ve güvenli sahil yürüyüşleri.',
      amenities: ['Canlı GPS Takibi', 'Ödül Maması'],
      isVerified: true,
    );

    setUp(() {
      fakeSitterRepo = FakeSitterRepository([sitter1, sitter2]);
      fakeBookingRepo = FakeBookingRepository();
    });

    test('DiscoveryCubit başlangıç durumu doğru olmalıdır', () {
      final cubit = DiscoveryCubit(
        sitterRepository: fakeSitterRepo,
        bookingRepository: fakeBookingRepo,
      );

      expect(cubit.state.status, equals(DiscoveryStatus.initial));
      expect(cubit.state.sitters, isEmpty);
      expect(cubit.state.selectedCategory, equals('Tümü'));
      cubit.close();
    });

    test('loadSitters tüm bakıcıları UseCase üzerinden çeker', () async {
      final cubit = DiscoveryCubit(
        searchSittersUseCase: SearchSittersUseCase(fakeSitterRepo),
        getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
        createBookingUseCase: CreateBookingUseCase(fakeBookingRepo),
      );

      await cubit.loadSitters();

      expect(cubit.state.status, equals(DiscoveryStatus.loaded));
      expect(cubit.state.sitters.length, equals(2));
      cubit.close();
    });

    test('setCategory kategoriyi filtreler', () async {
      final cubit = DiscoveryCubit(
        searchSittersUseCase: SearchSittersUseCase(fakeSitterRepo),
        getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
        createBookingUseCase: CreateBookingUseCase(fakeBookingRepo),
      );

      await cubit.loadSitters();
      await cubit.setCategory('Köpek Gezdirme');

      expect(cubit.state.sitters.length, equals(1));
      expect(cubit.state.sitters.first.name, equals('Mert Demir'));
      cubit.close();
    });

    test('setSearchQuery arama metnine göre filtreler', () async {
      final cubit = DiscoveryCubit(
        searchSittersUseCase: SearchSittersUseCase(fakeSitterRepo),
        getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
        createBookingUseCase: CreateBookingUseCase(fakeBookingRepo),
      );

      await cubit.loadSitters();
      await cubit.setSearchQuery('Moda');

      expect(cubit.state.sitters.length, equals(1));
      expect(cubit.state.sitters.first.name, equals('Ayşe Yılmaz'));
      cubit.close();
    });

    test('createBooking rezervasyonu BookingRepositoryye ekler', () async {
      final cubit = DiscoveryCubit(
        searchSittersUseCase: SearchSittersUseCase(fakeSitterRepo),
        getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
        createBookingUseCase: CreateBookingUseCase(fakeBookingRepo),
      );

      final booking = BookingRequest(
        id: 'book_new',
        sitterId: 'sitter_1',
        sitterName: 'Ayşe Yılmaz',
        sitterPhoto: 'assets/images/ayse.jpg',
        petName: 'Barley',
        petBreed: 'Golden Retriever',
        serviceTitle: 'Köpek Oteli — 2 Gece',
        startDate: DateTime(2026, 10, 24),
        endDate: DateTime(2026, 10, 26),
        totalPrice: 950.0,
        careNotes: 'Özel not',
        status: BookingStatus.pending,
      );

      final result = await cubit.createBooking(booking);

      expect(result, isTrue);
      expect(cubit.state.isBookingSuccess, isTrue);
      expect(fakeBookingRepo.bookings.length, equals(1));
      expect(fakeBookingRepo.bookings.first.id, equals('book_new'));
      cubit.close();
    });

    testWidgets(
      'ExploreScreen DiscoveryCubit ile render edilir ve arama filtreleri çalışır',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final cubit = DiscoveryCubit(
          searchSittersUseCase: SearchSittersUseCase(fakeSitterRepo),
          getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
          createBookingUseCase: CreateBookingUseCase(fakeBookingRepo),
        );
        await cubit.loadSitters();

        final appState = AppState();

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              notifier: appState,
              child: ExploreScreen(cubit: cubit, onSitterSelected: (_) {}),
            ),
          ),
        );
        await tester.pump();

        // Başlık ve rol rozeti
        expect(find.text('Hizmet Keşfet'), findsOneWidget);
        expect(find.text('Köpek Sahibi'), findsOneWidget);

        // Kartlar
        expect(find.text('Pati Dostları Butik Otel'), findsOneWidget);
        expect(find.text('Sahil Parkı Gezdiricisi'), findsOneWidget);

        // Kategori çipleri ve rozetler
        expect(find.text('Tümü'), findsOneWidget);
        expect(find.text('Köpek Oteli'), findsWidgets);

        cubit.close();
      },
    );

    testWidgets(
      'SitterDetailScreen takvim ve fiyat hesaplama akışını BookingRepository ile tamamlar',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final appState = AppState();
        bool bookingCompletedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              notifier: appState,
              child: SitterDetailScreen(
                sitter: sitter1,
                bookingRepository: fakeBookingRepo,
                onBack: () {},
                onBookingCompleted: () {
                  bookingCompletedCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // Başlık ve tesis bilgisi
        expect(find.text('Pati Dostları Butik Otel'), findsOneWidget);
        expect(find.text('Tesis Hakkında'), findsOneWidget);
        expect(find.text('Tarih Aralığı Seçimi'), findsOneWidget);

        // Rezervasyon talebi gönder butonunu bul ve tıkla
        final submitButton = find.text('Rezervasyon Talebi Gönder');
        expect(submitButton, findsOneWidget);

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // İletildi dialog'u
        expect(find.text('Talebiniz İletildi!'), findsOneWidget);
        expect(fakeBookingRepo.bookings.length, equals(1));

        // Dialog üzerindeki Tamam butonuna bas
        final okButton = find.text('Tamam');
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        expect(bookingCompletedCalled, isTrue);
      },
    );
  });
}
