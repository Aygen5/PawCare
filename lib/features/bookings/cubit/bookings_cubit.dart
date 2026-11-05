import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/repositories/booking_repository_interface.dart';
import '../../../domain/usecases/booking/get_bookings_use_case.dart';
import '../../../domain/usecases/booking/manage_booking_status_use_case.dart';
import 'bookings_state.dart';

/// Köpek sahibinin gönderdiği rezervasyon taleplerini yöneten Clean Architecture Cubit'i.
class BookingsCubit extends Cubit<BookingsState> {
  final GetBookingsUseCase _getBookingsUseCase;
  final ManageBookingStatusUseCase _manageBookingStatusUseCase;

  BookingsCubit({
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
       super(const BookingsState()) {
    if (initialBookings != null && initialBookings.isNotEmpty) {
      _applyBookings(initialBookings, state.activeFilter);
    } else {
      loadBookings();
    }
  }

  /// Rezervasyonları veri katmanından asenkron çeker ve aktif filtreye göre listeyi hazırlar.
  Future<void> loadBookings({List<BookingRequest>? fallbackBookings}) async {
    try {
      emit(state.copyWith(status: BookingsStatus.loading));
      var allBookings = await _getBookingsUseCase.call();
      if (allBookings.isEmpty &&
          fallbackBookings != null &&
          fallbackBookings.isNotEmpty) {
        allBookings = fallbackBookings;
      }
      _applyBookings(allBookings, state.activeFilter);
    } catch (e) {
      if (fallbackBookings != null && fallbackBookings.isNotEmpty) {
        _applyBookings(fallbackBookings, state.activeFilter);
      } else {
        emit(
          state.copyWith(
            status: BookingsStatus.error,
            errorMessage: 'Rezervasyonlar yüklenirken hata oluştu: $e',
          ),
        );
      }
    }
  }

  /// Aktif filtre türünü (Tümü, Bekleyen, Onaylı, Geçmiş) değiştirir.
  void setFilter(BookingFilter filter) {
    _applyBookings(state.allBookings, filter);
  }

  /// Filtre mantığını uygulayarak durumu günceller.
  void _applyBookings(List<BookingRequest> allBookings, BookingFilter filter) {
    List<BookingRequest> filtered;
    switch (filter) {
      case BookingFilter.all:
        filtered = allBookings;
        break;
      case BookingFilter.pending:
        filtered = allBookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
        break;
      case BookingFilter.confirmed:
        filtered = allBookings
            .where((b) => b.status == BookingStatus.confirmed)
            .toList();
        break;
      case BookingFilter.past:
        filtered = allBookings
            .where(
              (b) =>
                  b.status == BookingStatus.completed ||
                  b.status == BookingStatus.rejected,
            )
            .toList();
        break;
    }

    emit(
      state.copyWith(
        status: BookingsStatus.loaded,
        allBookings: allBookings,
        filteredBookings: filtered,
        activeFilter: filter,
        errorMessage: null,
        cancellingBookingId: null,
      ),
    );
  }

  /// Bekleyen bir rezervasyon talebini iptal eder (reddedildi durumuna çeker).
  Future<bool> cancelBooking(String bookingId) async {
    try {
      emit(state.copyWith(cancellingBookingId: bookingId));
      await _manageBookingStatusUseCase.updateStatus(
        bookingId,
        BookingStatus.rejected,
      );
      await loadBookings();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          cancellingBookingId: null,
          errorMessage: 'Rezervasyon iptal edilirken hata oluştu: $e',
        ),
      );
      return false;
    }
  }
}
