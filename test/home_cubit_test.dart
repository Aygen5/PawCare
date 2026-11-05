import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/domain/repositories/booking_repository_interface.dart';
import 'package:paw_care/domain/repositories/dog_repository_interface.dart';
import 'package:paw_care/domain/repositories/sitter_repository_interface.dart';
import 'package:paw_care/domain/usecases/booking/get_bookings_use_case.dart';
import 'package:paw_care/domain/usecases/pet/get_dog_profile_use_case.dart';
import 'package:paw_care/domain/usecases/sitter/get_sitters_use_case.dart';
import 'package:paw_care/features/home/cubit/home_cubit.dart';
import 'package:paw_care/features/home/cubit/home_state.dart';
import 'package:paw_care/features/home/view/owner_home_screen.dart';

// Test amaçlı sahte DogRepository
class FakeDogRepository implements DogRepositoryInterface {
  Dog? dogToReturn;

  FakeDogRepository({this.dogToReturn});

  @override
  Future<Dog?> getCurrentDog() async => dogToReturn;

  @override
  Future<List<Dog>> getDogs() async =>
      dogToReturn != null ? [dogToReturn!] : [];

  @override
  Future<void> saveDog(covariant Dog dog) async {
    dogToReturn = dog;
  }

  @override
  Future<void> addVaccination(
    String dogId,
    covariant Vaccination vaccination,
  ) async {}

  @override
  Future<void> updateVaccinationStatus(
    String dogId,
    String vaccinationId,
    VaccineStatus newStatus, {
    String? completionDate,
  }) async {}
}

// Test amaçlı sahte BookingRepository
class FakeBookingRepository implements BookingRepositoryInterface {
  List<BookingRequest> bookingsToReturn;

  FakeBookingRepository({this.bookingsToReturn = const []});

  @override
  Future<List<BookingRequest>> getAllBookings() async => bookingsToReturn;

  @override
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status) async =>
      bookingsToReturn.where((b) => b.status == status).toList();

  @override
  Stream<List<BookingRequest>> watchBookings() => Stream.value(bookingsToReturn);

  @override
  Future<void> addBooking(covariant BookingRequest booking) async {
    bookingsToReturn.add(booking);
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {}

  @override
  Future<void> deleteBooking(String bookingId) async {}
}

// Test amaçlı sahte SitterRepository
class FakeSitterRepository implements SitterRepositoryInterface {
  List<SitterListing> sittersToReturn;

  FakeSitterRepository({this.sittersToReturn = const []});

  @override
  Future<List<SitterListing>> getSitters({bool forceRefresh = false}) async =>
      sittersToReturn;

  @override
  Future<List<SitterListing>> searchSitters({
    String category = 'Tümü',
    String query = '',
  }) async => sittersToReturn;

  @override
  Future<SitterListing?> getSitterById(String id) async =>
      sittersToReturn.firstWhere((s) => s.id == id);
}

void main() {
  group('Faz 4 Adım 4.2: HomeCubit ve OwnerHomeScreen Testleri', () {
    late FakeDogRepository fakeDogRepo;
    late FakeBookingRepository fakeBookingRepo;
    late FakeSitterRepository fakeSitterRepo;

    final testDog = Dog(
      id: 'dog_test',
      name: 'Max',
      breed: 'Labrador',
      ageYears: 3,
      weightKg: 30.0,
      gender: 'Erkek',
      microchip: '123456789',
      photoPath: 'assets/images/barley.jpg',
      allergyNote: 'Alerji yok',
      behaviorNote: 'Uysal',
      clinicName: 'Test Klinik',
      clinicPhone: '123456',
      vaccinations: [
        Vaccination(
          id: 'v_test',
          title: 'Karma Aşı (DHPPi+L)',
          dueDate: '30 Ekim 2026',
          status: VaccineStatus.upcoming,
          vetName: 'Dr. Ahmet Yılmaz',
        ),
      ],
    );

    final testBooking = BookingRequest(
      id: 'b_test',
      sitterId: 's_test',
      sitterName: 'Mert Demir',
      sitterPhoto: 'assets/images/mert.jpg',
      petName: 'Max',
      petBreed: 'Labrador',
      serviceTitle: 'Caddebostan Sahil Parkı Yürüyüşü',
      startDate: DateTime(2026, 10, 24, 14, 0),
      endDate: DateTime(2026, 10, 24, 15, 0),
      totalPrice: 250.0,
      careNotes: 'Test notu',
      status: BookingStatus.confirmed,
    );

    final testSitter = SitterListing(
      id: 's_1',
      name: 'Ayşe Yılmaz',
      facilityTitle: 'Pati Dostları Oteli',
      category: 'Köpek Oteli',
      rating: 4.9,
      reviewsCount: 38,
      pricePerUnit: 450.0,
      unitLabel: 'gece',
      location: 'Moda, Kadıköy',
      distanceKm: 1.2,
      imagePath: 'assets/images/ayse.jpg',
      galleryPaths: ['assets/images/ayse.jpg'],
      bio: 'Biyografi',
      amenities: ['Geniş Bahçe'],
      isVerified: true,
    );

    setUp(() {
      fakeDogRepo = FakeDogRepository(dogToReturn: testDog);
      fakeBookingRepo = FakeBookingRepository(bookingsToReturn: [testBooking]);
      fakeSitterRepo = FakeSitterRepository(sittersToReturn: [testSitter]);
    });

    test('HomeCubit initial state HomeStatus.initial olmalıdır', () {
      final cubit = HomeCubit(
        dogRepository: fakeDogRepo,
        bookingRepository: fakeBookingRepo,
        sitterRepository: fakeSitterRepo,
      );

      expect(cubit.state.status, equals(HomeStatus.initial));
      expect(cubit.state.dog, isNull);
      cubit.close();
    });

    test('loadHomeData çağrıldığında veriler UseCase/Repository üzerinden yüklenir', () async {
      final cubit = HomeCubit(
        getDogProfileUseCase: GetDogProfileUseCase(fakeDogRepo),
        getBookingsUseCase: GetBookingsUseCase(fakeBookingRepo),
        getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
      );

      await cubit.loadHomeData();

      expect(cubit.state.status, equals(HomeStatus.loaded));
      expect(cubit.state.dog?.name, equals('Max'));
      expect(cubit.state.activeBooking?.sitterName, equals('Mert Demir'));
      expect(cubit.state.upcomingVaccine?.title, equals('Karma Aşı (DHPPi+L)'));
      expect(cubit.state.featuredSitters.length, equals(1));
      expect(
        cubit.state.featuredSitters.first.facilityTitle,
        equals('Pati Dostları Oteli'),
      );

      cubit.close();
    });

    test(
      'Depo boşsa fallbackDog güvenli şekilde atanır ve uygulama çökmez',
      () async {
        final emptyDogRepo = FakeDogRepository(dogToReturn: null);
        final cubit = HomeCubit(
          dogRepository: emptyDogRepo,
          bookingRepository: FakeBookingRepository(),
          sitterRepository: FakeSitterRepository(),
        );

        await cubit.loadHomeData();

        expect(cubit.state.status, equals(HomeStatus.loaded));
        expect(cubit.state.dog?.name, equals('Barley'));
        cubit.close();
      },
    );

    testWidgets(
      'OwnerHomeScreen HomeCubit ile beslenir, nabız animasyonu ve aşı uyarısını gösterir',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final cubit = HomeCubit(
          getDogProfileUseCase: GetDogProfileUseCase(fakeDogRepo),
          getBookingsUseCase: GetBookingsUseCase(fakeBookingRepo),
          getSittersUseCase: GetSittersUseCase(fakeSitterRepo),
        );

        await cubit.loadHomeData();

        final appState = AppState();

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              notifier: appState,
              child: OwnerHomeScreen(cubit: cubit, onSitterSelected: (_) {}),
            ),
          ),
        );
        await tester.pump();

        // Üst başlık karşılama ve köpek adı
        expect(find.text('Merhaba, Aygen 👋'), findsOneWidget);
        expect(find.text('Bugün Max için her şey yolunda!'), findsOneWidget);

        // Köpek profil kartı
        expect(find.text('Max'), findsOneWidget);
        expect(find.text('Labrador • 30.0 kg'), findsOneWidget);

        // Aşı kartı
        expect(find.textContaining('Karma Aşı Zamanı!'), findsOneWidget);
        expect(find.textContaining('Dr. Ahmet Yılmaz'), findsOneWidget);

        // Günün rezervasyonu ve canlı nabız etiketi
        expect(find.text('Günün Rezervasyonu'), findsOneWidget);
        expect(find.text('Yürüyüşte • Canlı'), findsOneWidget);
        expect(find.text('Mert Demir'), findsOneWidget);

        // Öne çıkan hizmetler
        expect(find.text('Pati Dostları Oteli'), findsOneWidget);

        cubit.close();
      },
    );
  });
}
