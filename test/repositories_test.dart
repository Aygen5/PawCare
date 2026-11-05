import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/data/local/hive_boxes.dart';
import 'package:paw_care/data/repositories/dog_repository.dart';
import 'package:paw_care/data/repositories/booking_repository.dart';
import 'package:paw_care/data/repositories/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hive & Repository Integration Tests', () {
    setUpAll(() async {
      // Test için geçici Hive ortamı kurulumu
      Hive.init('./test_hive');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VaccineStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VaccinationAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(DogAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SitterListingAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(BookingStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(BookingRequestAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ChatMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(NotificationItemAdapter());
      }

      await Hive.openBox<Dog>(HiveBoxes.dogsBox);
      await Hive.openBox<BookingRequest>(HiveBoxes.bookingsBox);
      await Hive.openBox<NotificationItem>(HiveBoxes.notificationsBox);
      await Hive.openBox<dynamic>(HiveBoxes.settingsBox);
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    test(
      'DogRepository saves, retrieves and updates dog vaccinations',
      () async {
        final repo = DogRepository();
        final testDog = Dog(
          id: 'dog_1',
          name: 'Barley',
          breed: 'Golden Retriever',
          ageYears: 2,
          weightKg: 28.5,
          gender: 'Erkek',
          microchip: '900215002941842',
          photoPath: 'assets/images/barley.jpg',
          allergyNote: 'Tavuk alerjisi',
          behaviorNote: 'Uysal',
          clinicName: 'Kadıköy Vet',
          clinicPhone: '+90 216 345 67 89',
          vaccinations: [
            Vaccination(
              id: 'v_1',
              title: 'Karma Aşı',
              dueDate: '26 Ekim 2026',
              status: VaccineStatus.upcoming,
              vetName: 'Dr. Selin Bulut',
            ),
          ],
        );

        await repo.saveDog(testDog);

        final retrieved = await repo.getCurrentDog();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'Barley');
        expect(retrieved.vaccinations.length, 1);

        // Yeni aşı ekleme işlemi
        final newVac = Vaccination(
          id: 'v_2',
          title: 'Kuduz',
          dueDate: '10 Kasım 2026',
          status: VaccineStatus.upcoming,
          vetName: 'Dr. Selin Bulut',
        );
        await repo.addVaccination('dog_1', newVac);

        final updatedDog = await repo.getCurrentDog();
        expect(updatedDog!.vaccinations.length, 2);

        // Aşı tamamlama durumu güncellemesi
        await repo.updateVaccinationStatus(
          'dog_1',
          'v_2',
          VaccineStatus.completed,
          completionDate: '10 Kasım 2026',
        );
        final finalDog = await repo.getCurrentDog();
        final kuduz = finalDog!.vaccinations.firstWhere((v) => v.id == 'v_2');
        expect(kuduz.status, VaccineStatus.completed);
        expect(kuduz.completionDate, '10 Kasım 2026');
      },
    );

    test('BookingRepository manages bookings lifecycle', () async {
      final repo = BookingRepository();
      final newBooking = BookingRequest(
        id: 'book_test_1',
        sitterId: 'sitter_1',
        sitterName: 'Ayşe Yılmaz',
        sitterPhoto: 'assets/images/ayse.jpg',
        petName: 'Barley',
        petBreed: 'Golden Retriever',
        serviceTitle: 'Köpek Oteli',
        startDate: DateTime(2026, 10, 24),
        endDate: DateTime(2026, 10, 26),
        totalPrice: 950.0,
        careNotes: 'Özel mama çantası',
        status: BookingStatus.pending,
      );

      await repo.addBooking(newBooking);
      final allBookings = await repo.getAllBookings();
      expect(allBookings.any((b) => b.id == 'book_test_1'), isTrue);

      await repo.updateBookingStatus('book_test_1', BookingStatus.confirmed);
      final confirmedList = await repo.getBookingsByStatus(BookingStatus.confirmed);
      expect(confirmedList.any((b) => b.id == 'book_test_1'), isTrue);
    });

    test(
      'NotificationRepository handles unread count and marking as read',
      () async {
        final repo = NotificationRepository();
        final notif = NotificationItem(
          id: 'notif_test',
          title: 'Test Bildirimi',
          body: 'Bu bir testtir.',
          timestamp: DateTime.now(),
          isRead: false,
        );

        await repo.addNotification(notif);
        final unread = await repo.getUnreadCount();
        expect(unread, greaterThan(0));

        await repo.markAsRead('notif_test');
        final notifObj = HiveBoxes.notifications.get('notif_test');
        expect(notifObj!.isRead, isTrue);
      },
    );

    test('SettingsRepository persists preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      expect(repo.getThemeMode(), 'system');
      await repo.setThemeMode('dark');
      expect(repo.getThemeMode(), 'dark');

      expect(repo.getUserRole(), 'owner');
      await repo.setUserRole('sitter');
      expect(repo.getUserRole(), 'sitter');
    });
  });
}
