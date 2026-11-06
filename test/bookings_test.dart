import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/core/widgets/modals/live_tracking_modal.dart';
import 'package:paw_care/core/widgets/paw_header_actions.dart';
import 'package:paw_care/domain/entities/booking.dart';
import 'package:paw_care/domain/repositories/booking_repository_interface.dart';
import 'package:paw_care/domain/usecases/booking/get_bookings_use_case.dart';
import 'package:paw_care/domain/usecases/booking/manage_booking_status_use_case.dart';
import 'package:paw_care/features/auth/cubit/role_cubit.dart';
import 'package:paw_care/features/bookings/cubit/bookings_cubit.dart';
import 'package:paw_care/features/bookings/cubit/bookings_state.dart';
import 'package:paw_care/features/bookings/view/owner_bookings_screen.dart';
import 'package:paw_care/features/bookings/widgets/booking_card.dart';

// Test amaçlı sahte BookingRepository
class FakeBookingRepository implements BookingRepositoryInterface {
  List<BookingRequest> bookings;

  FakeBookingRepository({List<BookingRequest>? initial})
    : bookings = initial != null ? List.from(initial) : [];

  @override
  Future<List<BookingRequest>> getAllBookings() async => List.unmodifiable(bookings);

  @override
  Future<List<BookingRequest>> getBookingsByStatus(BookingStatus status) async =>
      bookings.where((b) => b.status == status).toList();

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
      final old = bookings[idx];
      bookings[idx] = old.copyWith(status: newStatus);
    }
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    bookings.removeWhere((b) => b.id == bookingId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPendingBooking = BookingRequest(
    id: 'b_pending',
    sitterId: 'sitter_1',
    sitterName: 'Ayşe Yılmaz',
    sitterPhoto: 'assets/images/ayse.jpg',
    petName: 'Barley',
    petBreed: 'Golden Retriever',
    serviceTitle: 'Köpek Oteli — 2 Gece Konaklama',
    startDate: DateTime(2026, 10, 24),
    endDate: DateTime(2026, 10, 26),
    totalPrice: 900.0,
    careNotes: 'Tavuk alerjisi bulunmaktadır.',
    status: BookingStatus.pending,
  );

  final testConfirmedBooking = BookingRequest(
    id: 'b_confirmed',
    sitterId: 'sitter_2',
    sitterName: 'Mert Demir',
    sitterPhoto: 'assets/images/mert.jpg',
    petName: 'Barley',
    petBreed: 'Golden Retriever',
    serviceTitle: 'Sahil Parkı Yürüyüşü',
    startDate: DateTime(2026, 10, 23),
    endDate: DateTime(2026, 10, 23),
    totalPrice: 250.0,
    careNotes: 'Tempolu yürüyüş.',
    status: BookingStatus.confirmed,
  );

  final testPastBooking = BookingRequest(
    id: 'b_past',
    sitterId: 'sitter_1',
    sitterName: 'Ayşe Yılmaz',
    sitterPhoto: 'assets/images/ayse.jpg',
    petName: 'Barley',
    petBreed: 'Golden Retriever',
    serviceTitle: 'Gündüz Bakımı',
    startDate: DateTime(2026, 10, 10),
    endDate: DateTime(2026, 10, 10),
    totalPrice: 350.0,
    careNotes: 'Sosyal oyun seansı.',
    status: BookingStatus.completed,
  );

  Widget createTestWidget({required BookingsCubit cubit, AppState? appState}) {
    return AppStateScope(
      notifier: appState ?? AppState(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BookingsCubit>.value(value: cubit),
          BlocProvider<RoleCubit>(create: (_) => RoleCubit()),
        ],
        child: const MaterialApp(home: OwnerBookingsScreen()),
      ),
    );
  }

  group('Adım 4.6: BookingsCubit Unit Testleri', () {
    late FakeBookingRepository fakeRepo;
    late GetBookingsUseCase getBookingsUseCase;
    late ManageBookingStatusUseCase manageBookingStatusUseCase;

    setUp(() {
      fakeRepo = FakeBookingRepository(
        initial: [testPendingBooking, testConfirmedBooking, testPastBooking],
      );
      getBookingsUseCase = GetBookingsUseCase(fakeRepo);
      manageBookingStatusUseCase = ManageBookingStatusUseCase(fakeRepo);
    });

    test('Başlangıçta tüm rezervasyonları yükler ve sayaçları hesaplar', () async {
      final cubit = BookingsCubit(
        getBookingsUseCase: getBookingsUseCase,
        manageBookingStatusUseCase: manageBookingStatusUseCase,
      );
      await cubit.loadBookings();

      expect(cubit.state.status, BookingsStatus.loaded);
      expect(cubit.state.allBookings.length, 3);
      expect(cubit.state.filteredBookings.length, 3);
      expect(cubit.state.pendingCount, 1);
      expect(cubit.state.confirmedCount, 1);
    });

    test('Filtreleme değiştirildiğinde doğru listeyi döner', () async {
      final cubit = BookingsCubit(
        getBookingsUseCase: getBookingsUseCase,
        manageBookingStatusUseCase: manageBookingStatusUseCase,
      );
      await cubit.loadBookings();

      // Bekleyen filtresi
      cubit.setFilter(BookingFilter.pending);
      expect(cubit.state.activeFilter, BookingFilter.pending);
      expect(cubit.state.filteredBookings.length, 1);
      expect(cubit.state.filteredBookings.first.id, 'b_pending');

      // Onaylı filtresi
      cubit.setFilter(BookingFilter.confirmed);
      expect(cubit.state.activeFilter, BookingFilter.confirmed);
      expect(cubit.state.filteredBookings.length, 1);
      expect(cubit.state.filteredBookings.first.id, 'b_confirmed');

      // Geçmiş / Diğer filtresi
      cubit.setFilter(BookingFilter.past);
      expect(cubit.state.activeFilter, BookingFilter.past);
      expect(cubit.state.filteredBookings.length, 1);
      expect(cubit.state.filteredBookings.first.id, 'b_past');
    });

    test(
      'cancelBooking bekleyen talebi iptal eder ve durumu günceller',
      () async {
        final cubit = BookingsCubit(
          getBookingsUseCase: getBookingsUseCase,
          manageBookingStatusUseCase: manageBookingStatusUseCase,
        );

        final success = await cubit.cancelBooking('b_pending');
        expect(success, isTrue);

        final inRepo = fakeRepo.bookings.firstWhere((b) => b.id == 'b_pending');
        expect(inRepo.status, BookingStatus.rejected);
        expect(cubit.state.pendingCount, 0);
      },
    );
  });

  group('Adım 4.6: OwnerBookingsScreen Widget Testleri', () {
    late FakeBookingRepository fakeRepo;
    late BookingsCubit cubit;

    setUp(() {
      fakeRepo = FakeBookingRepository(
        initial: [testPendingBooking, testConfirmedBooking],
      );
      cubit = BookingsCubit(
        getBookingsUseCase: GetBookingsUseCase(fakeRepo),
        manageBookingStatusUseCase: ManageBookingStatusUseCase(fakeRepo),
      );
    });

    testWidgets(
      'OwnerBookingsScreen başlık, PawHeaderActions ve filtre çiplerini gösterir',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(450, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('Rezervasyon Taleplerim'), findsOneWidget);
        expect(find.byType(PawHeaderActions), findsOneWidget);

        // Filtre çipleri
        expect(find.textContaining('Tümü (2)'), findsOneWidget);
        expect(find.textContaining('Bekleyen (1)'), findsOneWidget);
        expect(find.textContaining('Onaylı (1)'), findsOneWidget);
        expect(find.text('Geçmiş / Diğer'), findsOneWidget);

        // Kartlar
        expect(find.byType(BookingCard), findsNWidgets(2));
        expect(find.text('Ayşe Yılmaz'), findsOneWidget);
        expect(find.text('Mert Demir'), findsOneWidget);
      },
    );

    testWidgets('Onaylı rezervasyonda Canlı Takip butonu modalı açar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final liveTrackingBtn = find.text('Canlı Takip');
      expect(liveTrackingBtn, findsOneWidget);

      await tester.tap(liveTrackingBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingModal), findsOneWidget);
      expect(find.textContaining('Yürüyüş'), findsWidgets);
    });

    testWidgets('Filtre çipine tıklandığında liste filtrelenir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // "Onaylı" çipine tıkla
      await tester.tap(find.textContaining('Onaylı (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.text('Mert Demir'), findsOneWidget);
      expect(find.text('Ayşe Yılmaz'), findsNothing);

      // "Geçmiş / Diğer" çipine kaydır ve tıkla
      await tester.ensureVisible(find.text('Geçmiş / Diğer'));
      await tester.tap(find.text('Geçmiş / Diğer'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingCard), findsNothing);
      expect(find.text('Bu filtrede rezervasyon bulunmuyor'), findsOneWidget);
    });

    testWidgets('Talebi İptal Et butonu onay dialogunu açar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final cancelBtn = find.text('Talebi İptal Et');
      expect(cancelBtn, findsOneWidget);

      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Talebi İptal Et'),
        findsNWidgets(2),
      ); // başlık ve dialog
      expect(find.text('Evet, İptal Et'), findsOneWidget);

      await tester.tap(find.text('Evet, İptal Et'));
      await tester.pumpAndSettle();

      expect(find.text('Rezervasyon talebiniz iptal edildi.'), findsOneWidget);
    });
  });
}
