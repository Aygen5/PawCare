import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/core/widgets/paw_header_actions.dart';
import 'package:paw_care/domain/entities/notification.dart';
import 'package:paw_care/domain/repositories/notification_repository_interface.dart';
import 'package:paw_care/domain/usecases/notification/get_notifications_use_case.dart';
import 'package:paw_care/domain/usecases/notification/mark_notification_read_use_case.dart';
import 'package:paw_care/features/notifications/cubit/notifications_cubit.dart';
import 'package:paw_care/features/notifications/cubit/notifications_state.dart';
import 'package:paw_care/features/notifications/view/notifications_sheet.dart';

// Test amaçlı sahte NotificationRepository
class FakeNotificationRepository implements NotificationRepositoryInterface {
  List<NotificationItem> notifications;

  FakeNotificationRepository({List<NotificationItem>? initial})
    : notifications = initial != null ? List.from(initial) : [];

  @override
  Future<List<NotificationItem>> getNotifications() async =>
      List.unmodifiable(notifications);

  @override
  Future<int> getUnreadCount() async =>
      notifications.where((n) => !n.isRead).length;

  @override
  Stream<List<NotificationItem>> watchNotifications() =>
      Stream.value(notifications);

  @override
  Future<void> addNotification(NotificationItem notification) async {
    notifications.insert(0, notification);
  }

  @override
  Future<void> markAsRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  Future<void> clearAll() async {
    notifications.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUnreadNotification = NotificationItem(
    id: 'n_1',
    title: 'Aşı Hatırlatması 💉',
    body: 'Barley için Karma Aşı randevusu yaklaşıyor.',
    timestamp: DateTime(2026, 10, 24, 10, 0),
    isRead: false,
    type: 'vaccine',
  );

  final testReadNotification = NotificationItem(
    id: 'n_2',
    title: 'Rezervasyon Onaylandı! 🐾',
    body: 'Mert Demir ile yürüyüş seansı onaylandı.',
    timestamp: DateTime(2026, 10, 23, 14, 0),
    isRead: true,
    type: 'booking',
  );

  Widget createTestWidget({
    required NotificationsCubit cubit,
    AppState? appState,
  }) {
    return AppStateScope(
      notifier: appState ?? AppState(),
      child: BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [PawHeaderActions()]),
            body: Center(
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => NotificationsSheet.show(ctx),
                  child: const Text('Bildirimleri Aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Adım 5.1: NotificationsCubit Unit Testleri', () {
    late FakeNotificationRepository fakeRepo;
    late GetNotificationsUseCase getNotificationsUseCase;
    late MarkNotificationReadUseCase markNotificationReadUseCase;

    setUp(() {
      fakeRepo = FakeNotificationRepository(
        initial: [testUnreadNotification, testReadNotification],
      );
      getNotificationsUseCase = GetNotificationsUseCase(fakeRepo);
      markNotificationReadUseCase = MarkNotificationReadUseCase(fakeRepo);
    });

    test('Başlangıçta tüm bildirimleri ve okunmamış adedini hesaplar', () async {
      final cubit = NotificationsCubit(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationReadUseCase: markNotificationReadUseCase,
      );
      await cubit.loadNotifications();

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.allNotifications.length, 2);
      expect(cubit.state.unreadCount, 1);
      expect(cubit.state.hasUnread, isTrue);
    });

    test('Filtreleme değiştirildiğinde doğru listeyi filtreler', () async {
      final cubit = NotificationsCubit(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationReadUseCase: markNotificationReadUseCase,
      );
      await cubit.loadNotifications();

      // Okunmamış filtresi
      cubit.setFilter(NotificationFilter.unread);
      expect(cubit.state.activeFilter, NotificationFilter.unread);
      expect(cubit.state.filteredNotifications.length, 1);
      expect(cubit.state.filteredNotifications.first.id, 'n_1');

      // Aşı filtresi
      cubit.setFilter(NotificationFilter.vaccine);
      expect(cubit.state.activeFilter, NotificationFilter.vaccine);
      expect(cubit.state.filteredNotifications.length, 1);
      expect(cubit.state.filteredNotifications.first.type, 'vaccine');

      // Rezervasyon filtresi
      cubit.setFilter(NotificationFilter.booking);
      expect(cubit.state.activeFilter, NotificationFilter.booking);
      expect(cubit.state.filteredNotifications.length, 1);
      expect(cubit.state.filteredNotifications.first.type, 'booking');
    });

    test('markAsRead bildirimi okundu yapar ve unreadCount düşer', () async {
      final cubit = NotificationsCubit(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationReadUseCase: markNotificationReadUseCase,
      );

      await cubit.markAsRead('n_1');

      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.hasUnread, isFalse);
      expect(
        fakeRepo.notifications.firstWhere((n) => n.id == 'n_1').isRead,
        isTrue,
      );
    });

    test('markAllAsRead tüm bildirimleri okundu yapar', () async {
      final cubit = NotificationsCubit(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationReadUseCase: markNotificationReadUseCase,
      );

      await cubit.markAllAsRead();

      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.allNotifications.every((n) => n.isRead), isTrue);
    });

    test('triggerLocalEventNotification yerel olay bildirimi ekler', () async {
      final cubit = NotificationsCubit(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationReadUseCase: markNotificationReadUseCase,
        notificationRepository: fakeRepo,
      );
      await cubit.loadNotifications();

      await cubit.triggerLocalEventNotification(
        title: 'Demo Yürüyüş Durumu 🦮',
        body: 'Mert Demir yürüyüş seansını başlattı.',
        type: 'walk',
      );

      expect(cubit.state.allNotifications.length, 3);
      expect(cubit.state.unreadCount, 2);
      expect(
        cubit.state.allNotifications.first.title,
        'Demo Yürüyüş Durumu 🦮',
      );
    });
  });

  group('Adım 5.1: NotificationsSheet & PawHeaderActions Widget Testleri', () {
    late FakeNotificationRepository fakeRepo;
    late NotificationsCubit cubit;

    setUp(() {
      fakeRepo = FakeNotificationRepository(
        initial: [testUnreadNotification, testReadNotification],
      );
      cubit = NotificationsCubit(
        getNotificationsUseCase: GetNotificationsUseCase(fakeRepo),
        markNotificationReadUseCase: MarkNotificationReadUseCase(fakeRepo),
      );
    });

    testWidgets(
      'PawHeaderActions bildirim ikonunda rozeti gösterir ve tıklandığında sheet açılır',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(450, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        // Bildirim ikonuna tıkla
        final notifIcon = find.byIcon(Icons.notifications_outlined);
        expect(notifIcon, findsOneWidget);

        await tester.tap(notifIcon);
        await tester.pumpAndSettle();

        // NotificationsSheet açıldı
        expect(find.byType(NotificationsSheet), findsOneWidget);
        expect(find.text('Bildirimler'), findsOneWidget);
        expect(find.text('Aşı Hatırlatması 💉'), findsOneWidget);
        expect(find.text('Rezervasyon Onaylandı! 🐾'), findsOneWidget);
      },
    );

    testWidgets('Okunmamış bildirime tıklandığında okundu olarak işaretlenir', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Sheeti aç
      await tester.tap(find.text('Bildirimleri Aç'));
      await tester.pumpAndSettle();

      expect(cubit.state.unreadCount, 1);

      // Okunmamış karta tıkla
      final unreadCard = find.text('Aşı Hatırlatması 💉');
      await tester.tap(unreadCard);
      await tester.pumpAndSettle();

      expect(cubit.state.unreadCount, 0);
    });

    testWidgets(
      'Tümünü Oku butonuna basıldığında tüm bildirimler okundu olur',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(450, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        // Sheeti aç
        await tester.tap(find.text('Bildirimleri Aç'));
        await tester.pumpAndSettle();

        final markAllBtn = find.text('Tümünü Oku').first;
        expect(find.text('Tümünü Oku'), findsWidgets);

        await tester.tap(markAllBtn);
        await tester.pumpAndSettle();

        expect(cubit.state.unreadCount, 0);
        expect(find.text('Tümünü Oku'), findsNothing);
      },
    );

    testWidgets('Filtre çipleri bildirim listesini filtreler', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Sheeti aç
      await tester.tap(find.text('Bildirimleri Aç'));
      await tester.pumpAndSettle();

      // "Aşılar" çipine tıkla
      await tester.tap(find.text('Aşılar'));
      await tester.pumpAndSettle();

      expect(find.text('Aşı Hatırlatması 💉'), findsOneWidget);
      expect(find.text('Rezervasyon Onaylandı! 🐾'), findsNothing);

      // "Rezervasyonlar" çipine tıkla (yatay scroll içinde görünür olmasını sağla)
      await tester.ensureVisible(find.text('Rezervasyonlar'));
      await tester.tap(find.text('Rezervasyonlar'));
      await tester.pumpAndSettle();

      expect(find.text('Aşı Hatırlatması 💉'), findsNothing);
      expect(find.text('Rezervasyon Onaylandı! 🐾'), findsOneWidget);
    });
  });
}
