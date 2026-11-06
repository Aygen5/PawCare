import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/core/widgets/paw_header_actions.dart';
import 'package:paw_care/data/models/models.dart' as model;
import 'package:paw_care/domain/entities/booking.dart';
import 'package:paw_care/domain/repositories/booking_repository_interface.dart';
import 'package:paw_care/domain/usecases/booking/get_bookings_use_case.dart';
import 'package:paw_care/domain/usecases/booking/manage_booking_status_use_case.dart';
import 'package:paw_care/features/auth/cubit/role_cubit.dart';
import 'package:paw_care/features/provider/cubit/provider_cubit.dart';
import 'package:paw_care/features/provider/cubit/provider_state.dart';
import 'package:paw_care/features/provider/view/sitter_dashboard_screen.dart';
import 'package:paw_care/features/provider/widgets/booking_request_card.dart';

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
    id: 'req_1',
    sitterId: 'sitter_1',
    sitterName: 'Ayşe Yılmaz',
    sitterPhoto: 'assets/images/ayse.jpg',
    petName: 'Barley',
    petBreed: 'Golden Retriever',
    serviceTitle: 'Köpek Oteli — 2 Gece Konaklama',
    startDate: DateTime(2026, 10, 24),
    endDate: DateTime(2026, 10, 26),
    totalPrice: 900.0,
    careNotes: 'Tavuk alerjisi var.',
    status: BookingStatus.pending,
  );

  final testConfirmedBooking = BookingRequest(
    id: 'req_2',
    sitterId: 'sitter_1',
    sitterName: 'Ayşe Yılmaz',
    sitterPhoto: 'assets/images/ayse.jpg',
    petName: 'Bella',
    petBreed: 'Poodle',
    serviceTitle: 'Gündüz Bakımı',
    startDate: DateTime(2026, 10, 23),
    endDate: DateTime(2026, 10, 23),
    totalPrice: 350.0,
    careNotes: 'Oldukça oyuncudur.',
    status: BookingStatus.confirmed,
  );

  Widget createTestWidget({
    required ProviderCubit cubit,
    RoleCubit? roleCubit,
    AppState? appState,
  }) {
    return AppStateScope(
      notifier: appState ?? AppState(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProviderCubit>.value(value: cubit),
          BlocProvider<RoleCubit>.value(value: roleCubit ?? RoleCubit()),
        ],
        child: const MaterialApp(home: SitterDashboardScreen()),
      ),
    );
  }

  group('Adım 4.5: ProviderCubit Unit Testleri', () {
    late FakeBookingRepository fakeRepo;
    late GetBookingsUseCase getBookingsUseCase;
    late ManageBookingStatusUseCase manageBookingStatusUseCase;

    setUp(() {
      fakeRepo = FakeBookingRepository(
        initial: [testPendingBooking, testConfirmedBooking],
      );
      getBookingsUseCase = GetBookingsUseCase(fakeRepo);
      manageBookingStatusUseCase = ManageBookingStatusUseCase(fakeRepo);
    });

    test('Başlangıçta bekleyen ve onaylı rezervasyonları doğru ayırır', () async {
      final cubit = ProviderCubit(
        getBookingsUseCase: getBookingsUseCase,
        manageBookingStatusUseCase: manageBookingStatusUseCase,
      );
      await cubit.loadDashboard();

      expect(cubit.state.status, ProviderStatus.loaded);
      expect(cubit.state.bookings.length, 2);
      expect(cubit.state.pendingBookings.length, 1);
      expect(cubit.state.pendingBookings.first.id, 'req_1');
      expect(cubit.state.confirmedBookings.length, 1);
      expect(cubit.state.confirmedBookings.first.id, 'req_2');
      expect(cubit.state.totalEarnings, 350.0);
    });

    test(
      'confirmBooking talebi onaylar, listeleri ve kazancı günceller',
      () async {
        final cubit = ProviderCubit(
          getBookingsUseCase: getBookingsUseCase,
          manageBookingStatusUseCase: manageBookingStatusUseCase,
        );

        final success = await cubit.confirmBooking('req_1');
        expect(success, isTrue);

        expect(cubit.state.pendingBookings.length, 0);
        expect(cubit.state.confirmedBookings.length, 2);
        expect(cubit.state.totalEarnings, 1250.0);

        // Repository seviyesinde doğrula
        final inRepo = fakeRepo.bookings.firstWhere((b) => b.id == 'req_1');
        expect(inRepo.status, BookingStatus.confirmed);
      },
    );

    test(
      'rejectBooking talebi reddeder ve bekleyen listesinden kaldırır',
      () async {
        final cubit = ProviderCubit(
          getBookingsUseCase: getBookingsUseCase,
          manageBookingStatusUseCase: manageBookingStatusUseCase,
        );

        final success = await cubit.rejectBooking('req_1');
        expect(success, isTrue);

        expect(cubit.state.pendingBookings.length, 0);
        final inRepo = fakeRepo.bookings.firstWhere((b) => b.id == 'req_1');
        expect(inRepo.status, BookingStatus.rejected);
      },
    );
  });

  group('Adım 4.5: SitterDashboardScreen Widget Testleri', () {
    late FakeBookingRepository fakeRepo;
    late ProviderCubit cubit;

    setUp(() {
      fakeRepo = FakeBookingRepository(
        initial: [testPendingBooking, testConfirmedBooking],
      );
      cubit = ProviderCubit(
        getBookingsUseCase: GetBookingsUseCase(fakeRepo),
        manageBookingStatusUseCase: ManageBookingStatusUseCase(fakeRepo),
      );
    });

    testWidgets(
      'SitterDashboardScreen başlık, PawHeaderActions ve KPI kartlarını gösterir',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(450, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('Hizmet Veren Paneli'), findsOneWidget);
        expect(find.text('Ayşe Yılmaz'), findsOneWidget);
        expect(find.text('Mutlu Patiler Köpek Oteli'), findsOneWidget);
        expect(find.byType(PawHeaderActions), findsOneWidget);

        // KPI Metrik Kartları
        expect(find.text('Bekleyen'), findsOneWidget);
        expect(find.text('Onaylı'), findsOneWidget);
        expect(find.text('Kazanç'), findsOneWidget);
      },
    );

    testWidgets('Yeni gelen talep kartı (BookingRequestCard) render edilir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(BookingRequestCard), findsOneWidget);
      expect(find.text('Barley (Golden Retriever)'), findsOneWidget);
      expect(find.text('₺900'), findsOneWidget);
      expect(find.text('Onayla'), findsOneWidget);
      expect(find.text('Reddet'), findsOneWidget);
    });

    testWidgets('Onayla butonuna basıldığında onay SnackBarı görüntülenir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Onayla');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('rezervasyon başarıyla onaylandı'),
        findsOneWidget,
      );
      // Talep onaylandığında bekleyen listesi boş kalmalı
      expect(find.text('Tüm talepler yanıtlandı!'), findsOneWidget);
    });

    testWidgets('Reddet butonuna basıldığında ret SnackBarı görüntülenir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final rejectBtn = find.text('Reddet');
      expect(rejectBtn, findsOneWidget);

      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('talebi reddedildi'), findsOneWidget);
      expect(find.text('Tüm talepler yanıtlandı!'), findsOneWidget);
    });

    testWidgets('Sahip Modu butonuna basıldığında RoleCubit tetiklenir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final roleCubit = RoleCubit()..switchToSitter();
      expect(roleCubit.state, model.UserRole.sitter);

      await tester.pumpWidget(
        createTestWidget(cubit: cubit, roleCubit: roleCubit),
      );
      await tester.pumpAndSettle();

      final switchBtn = find.text('Sahip Modu');
      expect(switchBtn, findsOneWidget);

      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      expect(roleCubit.state, model.UserRole.owner);
    });
  });
}
