import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paw_care/app/app.dart';
import 'package:paw_care/app/router/app_shell.dart';
import 'package:paw_care/app/router/route_names.dart';
import 'package:paw_care/core/widgets/paw_bottom_nav.dart';
import 'package:paw_care/core/widgets/paw_header_actions.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/domain/entities/user_entity.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/features/discovery/view/explore_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Adım 3.2: AppShell ve PawBottomNav Testleri', () {
    testWidgets('AppShell içinde yeşil demo çubuğu tamamen kaldırılmıştır', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = InMemoryAuthRepository(
        initialUser: const UserEntity(
          uid: 'u1',
          email: 'test@pawcare.com',
          displayName: 'Aygen',
          role: UserRole.owner,
        ),
      );

      await tester.pumpWidget(
        PawCareApp(
          initialLocation: RoutePaths.home,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      // Eski yeşil "Ekranlar:" demo çubuğu bulunmamalıdır
      expect(find.text('Ekranlar:'), findsNothing);
      expect(find.text('1: Karşılama'), findsNothing);
      expect(find.text('2: Keşfet'), findsNothing);
    });

    testWidgets(
      'AppShell 480px mobil genişlik sınırlaması ve alt navigasyon barını içerir',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          PawCareApp(
            initialLocation: RoutePaths.home,
            settingsRepository: SettingsRepository.inMemory(),
          ),
        );
        await tester.pump();

        // AppShell ve PawBottomNav'in varlığını doğrular
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(PawBottomNav), findsOneWidget);

        // ConstrainedBox ile maxWidth 480 sınırlaması yapıldığını doğrular
        final constrainedBoxes = tester.widgetList<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        final has480Constraint = constrainedBoxes.any(
          (box) => box.constraints.maxWidth == 480,
        );
        expect(has480Constraint, isTrue);
      },
    );

    testWidgets('PawBottomNav sekmeleri rotalarla senkronize çalışır', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = InMemoryAuthRepository(
        initialUser: const UserEntity(
          uid: 'u1',
          email: 'test@pawcare.com',
          displayName: 'Aygen',
          role: UserRole.owner,
        ),
      );

      await tester.pumpWidget(
        PawCareApp(
          initialLocation: RoutePaths.home,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      // 5 sekmeli alt barın varlığını doğrular
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Keşfet'), findsOneWidget);
      expect(find.text('Köpeklerim'), findsOneWidget);
      expect(find.text('Taleplerim'), findsOneWidget);
      expect(find.text('Profilim'), findsWidgets);

      // Keşfet sekmesine tıklar
      final exploreTab = find.text('Keşfet');
      await tester.tap(exploreTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ExploreScreen'in açıldığını doğrular
      expect(find.byType(ExploreScreen), findsOneWidget);
    });
  });

  group('Adım 3.3: PawHeaderActions Testleri', () {
    testWidgets('PawHeaderActions bildirim ve profil ikonlarını render eder', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = InMemoryAuthRepository(
        initialUser: const UserEntity(
          uid: 'u1',
          email: 'test@pawcare.com',
          displayName: 'Aygen',
          role: UserRole.owner,
        ),
      );

      await tester.pumpWidget(
        PawCareApp(
          initialLocation: RoutePaths.home,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      // Başlıktaki PawHeaderActions bileşenini doğrular
      expect(find.byType(PawHeaderActions), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsWidgets);
    });

    testWidgets('Bildirim butonuna tıklandığında bildirim modalı açılır', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = InMemoryAuthRepository(
        initialUser: const UserEntity(
          uid: 'u1',
          email: 'test@pawcare.com',
          displayName: 'Aygen',
          role: UserRole.owner,
        ),
      );

      await tester.pumpWidget(
        PawCareApp(
          initialLocation: RoutePaths.home,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      final notifIconFinder = find.byIcon(Icons.notifications_outlined);
      await tester.tap(notifIconFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bildirimler modal penceresini doğrular
      expect(find.text('Bildirimler'), findsOneWidget);
    });
  });
}
