import '../../entities/booking.dart';
import '../../repositories/booking_repository_interface.dart';

/// Tüm rezervasyonları veya duruma göre filtrelenmiş rezervasyonları getiren kullanım senaryosu.
class GetBookingsUseCase {
  final BookingRepositoryInterface repository;

  const GetBookingsUseCase(this.repository);

  Future<List<BookingRequest>> call({BookingStatus? filterStatus}) async {
    if (filterStatus != null) {
      return repository.getBookingsByStatus(filterStatus);
    }
    return repository.getAllBookings();
  }

  Stream<List<BookingRequest>> watch() {
    return repository.watchBookings();
  }
}
