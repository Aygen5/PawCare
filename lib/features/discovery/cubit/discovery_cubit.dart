import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../data/repositories/firebase_sitter_repository.dart';
import '../../../domain/repositories/booking_repository_interface.dart';
import '../../../domain/repositories/sitter_repository_interface.dart';
import '../../../domain/usecases/booking/create_booking_use_case.dart';
import '../../../domain/usecases/sitter/get_sitters_use_case.dart';
import '../../../domain/usecases/sitter/search_sitters_use_case.dart';
import 'discovery_state.dart';

/// Keşfet ve Hizmet Detayı akışını yöneten Clean Architecture Cubit'i.
class DiscoveryCubit extends Cubit<DiscoveryState> {
  final SearchSittersUseCase _searchSittersUseCase;
  final GetSittersUseCase _getSittersUseCase;
  final CreateBookingUseCase _createBookingUseCase;

  DiscoveryCubit({
    SearchSittersUseCase? searchSittersUseCase,
    GetSittersUseCase? getSittersUseCase,
    CreateBookingUseCase? createBookingUseCase,
    SitterRepositoryInterface? sitterRepository,
    BookingRepositoryInterface? bookingRepository,
  }) : _searchSittersUseCase =
           searchSittersUseCase ??
           SearchSittersUseCase(sitterRepository ?? FirebaseSitterRepository()),
       _getSittersUseCase =
           getSittersUseCase ??
           GetSittersUseCase(sitterRepository ?? FirebaseSitterRepository()),
       _createBookingUseCase =
           createBookingUseCase ??
           CreateBookingUseCase(bookingRepository ?? FirebaseBookingRepository()),
       super(const DiscoveryState());

  /// Bakıcıları mevcut kategori ve arama filtresine göre yükler.
  Future<void> loadSitters({
    String? initialCategory,
    String? initialQuery,
    bool forceRefresh = false,
  }) async {
    final category = initialCategory ?? state.selectedCategory;
    final query = initialQuery ?? state.searchQuery;

    emit(
      state.copyWith(
        status: DiscoveryStatus.loading,
        selectedCategory: category,
        searchQuery: query,
      ),
    );

    try {
      if (forceRefresh) {
        await _getSittersUseCase.call(forceRefresh: true);
      }

      final rawSitters = await _searchSittersUseCase.call(
        category: category,
        query: query,
      );
      final sitters = rawSitters.whereType<SitterListing>().toList();

      emit(state.copyWith(status: DiscoveryStatus.loaded, sitters: sitters));
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.error,
          errorMessage: 'Hizmetler aranırken bir hata oluştu: $e',
        ),
      );
    }
  }

  /// Kategori filtresini günceller ve listeyi filtreler.
  Future<void> setCategory(String category) async {
    emit(
      state.copyWith(
        selectedCategory: category,
        status: DiscoveryStatus.loading,
      ),
    );

    try {
      final rawSitters = await _searchSittersUseCase.call(
        category: category,
        query: state.searchQuery,
      );
      final sitters = rawSitters.whereType<SitterListing>().toList();

      emit(state.copyWith(status: DiscoveryStatus.loaded, sitters: sitters));
    } catch (e) {
      emit(state.copyWith(status: DiscoveryStatus.error, errorMessage: '$e'));
    }
  }

  /// Arama metnini günceller ve sonuçları filtreler.
  Future<void> setSearchQuery(String query) async {
    emit(state.copyWith(searchQuery: query, status: DiscoveryStatus.loading));

    try {
      final rawSitters = await _searchSittersUseCase.call(
        category: state.selectedCategory,
        query: query,
      );
      final sitters = rawSitters.whereType<SitterListing>().toList();

      emit(state.copyWith(status: DiscoveryStatus.loaded, sitters: sitters));
    } catch (e) {
      emit(state.copyWith(status: DiscoveryStatus.error, errorMessage: '$e'));
    }
  }

  /// Gelişmiş filtreleme ve sıralama parametrelerini uygular.
  Future<void> applyFilters({
    String? category,
    double? minRating,
    double? maxPrice,
    String? sortBy,
  }) async {
    final activeCategory = category ?? state.selectedCategory;
    emit(
      state.copyWith(
        status: DiscoveryStatus.loading,
        selectedCategory: activeCategory,
      ),
    );

    try {
      final rawSitters = await _searchSittersUseCase.call(
        category: activeCategory,
        query: state.searchQuery,
      );
      var list = rawSitters.whereType<SitterListing>().toList();

      if (minRating != null && minRating > 0) {
        list = list.where((s) => s.rating >= minRating).toList();
      }

      if (maxPrice != null && maxPrice > 0) {
        list = list.where((s) => s.pricePerUnit <= maxPrice).toList();
      }

      if (sortBy == 'Puan (En Yüksek)') {
        list.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (sortBy == 'Fiyat (Artan)') {
        list.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
      } else if (sortBy == 'Mesafe (En Yakın)') {
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      emit(state.copyWith(status: DiscoveryStatus.loaded, sitters: list));
    } catch (e) {
      emit(state.copyWith(status: DiscoveryStatus.error, errorMessage: '$e'));
    }
  }

  /// Yeni rezervasyon talebi oluşturur ve BookingRepository'ye (Hive) kaydeder.
  Future<bool> createBooking(BookingRequest booking) async {
    try {
      await _createBookingUseCase.call(booking);
      emit(state.copyWith(isBookingSuccess: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.error,
          errorMessage: 'Rezervasyon kaydedilemedi: $e',
        ),
      );
      return false;
    }
  }

  /// Listeyi zorla tazelemek için tetikleyici.
  Future<void> refresh() async {
    await loadSitters(forceRefresh: true);
  }
}
