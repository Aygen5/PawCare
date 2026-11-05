import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../data/repositories/firebase_dog_repository.dart';
import '../../../data/repositories/firebase_sitter_repository.dart';
import '../../../domain/repositories/booking_repository_interface.dart';
import '../../../domain/repositories/dog_repository_interface.dart';
import '../../../domain/repositories/sitter_repository_interface.dart';
import '../../../domain/usecases/booking/get_bookings_use_case.dart';
import '../../../domain/usecases/pet/get_dog_profile_use_case.dart';
import '../../../domain/usecases/sitter/get_sitters_use_case.dart';
import 'home_state.dart';

/// Köpek Sahibi Ana Sayfası için veri yönetimini üstlenen Clean Architecture Cubit.
class HomeCubit extends Cubit<HomeState> {
  final GetDogProfileUseCase _getDogProfileUseCase;
  final GetBookingsUseCase _getBookingsUseCase;
  final GetSittersUseCase _getSittersUseCase;

  HomeCubit({
    GetDogProfileUseCase? getDogProfileUseCase,
    GetBookingsUseCase? getBookingsUseCase,
    GetSittersUseCase? getSittersUseCase,
    DogRepositoryInterface? dogRepository,
    BookingRepositoryInterface? bookingRepository,
    SitterRepositoryInterface? sitterRepository,
  }) : _getDogProfileUseCase =
           getDogProfileUseCase ??
           GetDogProfileUseCase(dogRepository ?? FirebaseDogRepository()),
       _getBookingsUseCase =
           getBookingsUseCase ??
           GetBookingsUseCase(bookingRepository ?? FirebaseBookingRepository()),
       _getSittersUseCase =
           getSittersUseCase ??
           GetSittersUseCase(sitterRepository ?? FirebaseSitterRepository()),
       super(const HomeState());

  /// Varsayılan yedek köpek profili (Hive kutusu boşsa arayüzün boş kalmaması için).
  static final Dog fallbackDog = Dog(
    id: 'dog_1',
    name: 'Barley',
    breed: 'Golden Retriever',
    ageYears: 2,
    weightKg: 28.5,
    gender: 'Erkek',
    microchip: '900215002941842',
    photoPath: 'assets/images/barley.jpg',
    allergyNote: 'Tavuk proteini alerjisi — Yalnızca kuzu etli mama veriniz.',
    behaviorNote:
        'İnsanlara ve diğer köpeklere karşı uysal ve son derece enerjik.',
    clinicName: 'Kadıköy Veteriner Polikliniği',
    clinicPhone: '+90 216 345 67 89',
    vaccinations: [
      Vaccination(
        id: 'v_1',
        title: 'Karma Aşı (DHPPi+L)',
        dueDate: '26 Ekim 2026',
        status: VaccineStatus.upcoming,
        vetName: 'Dr. Selin Bulut',
      ),
    ],
  );

  /// Ana sayfa verilerini (köpek profili, rezervasyonlar, öne çıkan bakıcılar) asenkron yükler.
  Future<void> loadHomeData({bool forceRefresh = false}) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // 1. Köpek profilini UseCase üzerinden getir
      final rawDog = await _getDogProfileUseCase.call();
      final loadedDog = rawDog is Dog ? rawDog : fallbackDog;

      // 2. Rezervasyonları UseCase üzerinden getir
      final rawBookings = await _getBookingsUseCase.call();
      final allBookings = rawBookings.whereType<BookingRequest>().toList();

      // Günün rezervasyonunu belirle (önce onaylı olan, yoksa ilk rezervasyon)
      BookingRequest? activeBooking;
      for (final b in allBookings) {
        if (b.status == BookingStatus.confirmed) {
          activeBooking = b;
          break;
        }
      }
      activeBooking ??= allBookings.isNotEmpty ? allBookings.first : null;

      // 3. Yaklaşan aşıyı köpeğin aşı kayıtlarından bul
      Vaccination? upcomingVaccine;
      for (final v in loadedDog.vaccinations) {
        if (v.status == VaccineStatus.upcoming) {
          upcomingVaccine = v;
          break;
        }
      }
      upcomingVaccine ??= loadedDog.vaccinations.isNotEmpty
          ? loadedDog.vaccinations.first
          : null;

      // 4. Öne çıkan bakıcıları UseCase üzerinden getir
      final rawSitters = await _getSittersUseCase.call(
        forceRefresh: forceRefresh,
      );
      final sitters = rawSitters.whereType<SitterListing>().toList();

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          dog: loadedDog,
          activeBooking: activeBooking,
          upcomingBookings: allBookings,
          featuredSitters: sitters,
          upcomingVaccine: upcomingVaccine,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: 'Ana sayfa verileri yüklenirken bir sorun oluştu: $e',
        ),
      );
    }
  }

  /// Verileri yeniden yüklemek için tetikleyici.
  Future<void> refresh() async {
    await loadHomeData(forceRefresh: true);
  }
}
