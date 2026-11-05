import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/sitter.dart';
import '../../../domain/repositories/booking_repository_interface.dart';
import '../../../domain/usecases/booking/get_bookings_use_case.dart';
import '../../../domain/usecases/booking/manage_booking_status_use_case.dart';
import 'provider_state.dart';

/// Hizmet veren (sitter) panelinin rezervasyon ve kazanç durumunu yöneten Clean Architecture Cubit'i.
class ProviderCubit extends Cubit<ProviderState> {
  final GetBookingsUseCase _getBookingsUseCase;
  final ManageBookingStatusUseCase _manageBookingStatusUseCase;

  ProviderCubit({
    GetBookingsUseCase? getBookingsUseCase,
    ManageBookingStatusUseCase? manageBookingStatusUseCase,
    BookingRepositoryInterface? bookingRepository,
    List<BookingRequest>? initialBookings,
  }) : _getBookingsUseCase =
           getBookingsUseCase ??
           GetBookingsUseCase(bookingRepository ?? FirebaseBookingRepository()),
       _manageBookingStatusUseCase =
           manageBookingStatusUseCase ??
           ManageBookingStatusUseCase(bookingRepository ?? FirebaseBookingRepository()),
       super(const ProviderState()) {
    if (initialBookings != null && initialBookings.isNotEmpty) {
      _emitBookings(initialBookings);
    } else {
      loadDashboard();
    }
  }

  /// Tüm rezervasyonları veritabanından asenkron çeker ve bekleyen/onaylı listeleri günceller.
  Future<void> loadDashboard({List<BookingRequest>? fallbackBookings}) async {
    try {
      emit(state.copyWith(status: ProviderStatus.loading));
      var allBookings = await _getBookingsUseCase.call();
      if (allBookings.isEmpty &&
          fallbackBookings != null &&
          fallbackBookings.isNotEmpty) {
        allBookings = fallbackBookings;
      }
      _emitBookings(allBookings);
    } catch (e) {
      if (fallbackBookings != null && fallbackBookings.isNotEmpty) {
        _emitBookings(fallbackBookings);
      } else {
        emit(
          state.copyWith(
            status: ProviderStatus.error,
            errorMessage: 'Talepler yüklenirken bir hata oluştu: $e',
          ),
        );
      }
    }
  }

  /// Rezervasyon listesini filtreleyerek durumları ve kazancı hesaplar.
  void _emitBookings(List<BookingRequest> allBookings) {
    final pending = allBookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();
    final confirmed = allBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();

    // Onaylı rezervasyonların toplam tutarı veya demo baz kazanç
    final earnings = confirmed.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    emit(
      state.copyWith(
        status: ProviderStatus.loaded,
        bookings: allBookings,
        pendingBookings: pending,
        confirmedBookings: confirmed,
        totalEarnings: earnings > 0 ? earnings : 4250.0,
        errorMessage: null,
        updatingBookingId: null,
      ),
    );
  }

  /// Bekleyen bir rezervasyonu onaylar ve durumu günceller.
  Future<bool> confirmBooking(String bookingId) async {
    try {
      emit(state.copyWith(updatingBookingId: bookingId));
      await _manageBookingStatusUseCase.updateStatus(
        bookingId,
        BookingStatus.confirmed,
      );
      await loadDashboard();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          updatingBookingId: null,
          errorMessage: 'Rezervasyon onaylanırken hata oluştu: $e',
        ),
      );
      return false;
    }
  }

  /// Bekleyen bir rezervasyonu reddeder ve durumu günceller.
  Future<bool> rejectBooking(String bookingId) async {
    try {
      emit(state.copyWith(updatingBookingId: bookingId));
      await _manageBookingStatusUseCase.updateStatus(
        bookingId,
        BookingStatus.rejected,
      );
      await loadDashboard();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          updatingBookingId: null,
          errorMessage: 'Rezervasyon reddedilirken hata oluştu: $e',
        ),
      );
      return false;
    }
  }

  /// Tesis başlık, biyografi ve konum bilgilerini günceller.
  void updateFacilityInfo({
    required String title,
    required String bio,
    required String location,
  }) {
    emit(
      state.copyWith(
        facilityTitle: title,
        facilityBio: bio,
        facilityLocation: location,
      ),
    );
  }

  /// Mevcut bir hizmet kalemini günceller.
  void updateService(SitterServiceItem updatedService) {
    final list = state.services.map((s) {
      return s.id == updatedService.id ? updatedService : s;
    }).toList();
    emit(state.copyWith(services: list));
  }

  /// Yeni bir hizmet kalemi ekler.
  void addService(SitterServiceItem newService) {
    emit(state.copyWith(services: [...state.services, newService]));
  }

  /// Bir hizmet kalemini siler.
  void removeService(String serviceId) {
    final list = state.services.where((s) => s.id != serviceId).toList();
    emit(state.copyWith(services: list));
  }

  /// Yeni bir tesis olanak/özelliği ekler.
  void addAmenity(String amenity) {
    if (amenity.trim().isEmpty || state.amenities.contains(amenity.trim())) {
      return;
    }
    emit(state.copyWith(amenities: [...state.amenities, amenity.trim()]));
  }

  /// Bir tesis özelliğini siler.
  void removeAmenity(String amenity) {
    final list = state.amenities.where((a) => a != amenity).toList();
    emit(state.copyWith(amenities: list));
  }

  /// Toplam ve dolu süit kapasitesini günceller.
  void updateCapacity({required int total, required int occupied}) {
    emit(
      state.copyWith(
        totalSuites: total,
        occupiedSuites: occupied.clamp(0, total),
      ),
    );
  }

  /// Belirli bir takvim gününün durumunu günceller.
  void updateCalendarDay(SitterCalendarDay updatedDay) {
    final list = state.calendarDays.map((d) {
      return d.id == updatedDay.id ? updatedDay : d;
    }).toList();
    emit(state.copyWith(calendarDays: list));
  }

  /// Takvime yeni bir gün ekler.
  void addCalendarDay(SitterCalendarDay newDay) {
    emit(state.copyWith(calendarDays: [...state.calendarDays, newDay]));
  }
}
