import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paw_care/app/app.dart';
import 'package:paw_care/app/router/app_router.dart';
import 'package:paw_care/app/router/route_names.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/domain/entities/user_entity.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/features/discovery/view/explore_screen.dart';
import 'package:paw_care/features/home/view/owner_home_screen.dart';
import 'package:paw_care/features/onboarding/view/welcome_screen.dart';
import 'package:paw_care/features/pets/view/dog_profile_screen.dart';
import 'package:paw_care/features/provider/view/sitter_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Adım 3.1: GoRouter Rota Yapılandırması Testleri', () {
    test('Rota sabitleri RouteNames ve RoutePaths doğru tanımlanmıştır', () {
      expect(RoutePaths.splash, '/splash');
      expect(RoutePaths.welcome, '/welcome');
      expect(RoutePaths.home, '/home');
      expect(RoutePaths.explore, '/explore');
      expect(RoutePaths.pets, '/pets');
      expect(RoutePaths.bookings, '/bookings');
      expect(RoutePaths.profile, '/profile');
      expect(RoutePaths.sitterDashboard, '/sitter-dashboard');
      expect(RoutePaths.sitterDetail, '/sitter-detail');

      expect(RouteNames.splash, 'splash');
      expect(RouteNames.home, 'home');
      expect(RouteNames.welcome, 'welcome');
    });

    testWidgets('/welcome rotası WelcomeScreen bileşenini render eder', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        PawCareApp(
          initialLocation: RoutePaths.welcome,
          settingsRepository: SettingsRepository.inMemory(),
        ),
      );
      await tester.pump();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Dostunuz için en güvenilir eller.'), findsOneWidget);
    });

    testWidgets('/home rotası OwnerHomeScreen bileşenini render eder', (
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

      expect(find.byType(OwnerHomeScreen), findsOneWidget);
      expect(find.textContaining('Aygen'), findsWidgets);
    });

    testWidgets('/explore rotası ExploreScreen bileşenini render eder', (
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
          initialLocation: RoutePaths.explore,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('/pets rotası DogProfileScreen bileşenini render eder', (
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
          initialLocation: RoutePaths.pets,
          settingsRepository: SettingsRepository.inMemory(),
          authRepository: authRepo,
        ),
      );
      await tester.pump();

      expect(find.byType(DogProfileScreen), findsOneWidget);
    });

    testWidgets(
      '/sitter-dashboard rotası SitterDashboardScreen bileşenini render eder',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final authRepo = InMemoryAuthRepository(
          initialUser: const UserEntity(
            uid: 's1',
            email: 'sitter@pawcare.com',
            displayName: 'Ayşe Yılmaz',
            role: UserRole.sitter,
          ),
        );

        await tester.pumpWidget(
          PawCareApp(
            initialLocation: RoutePaths.sitterDashboard,
            settingsRepository: SettingsRepository.inMemory(),
            authRepository: authRepo,
          ),
        );
        await tester.pump();

        expect(find.byType(SitterDashboardScreen), findsOneWidget);
      },
    );

    testWidgets('Tanımlanmamış rotada hata sayfası görüntülenir', (
      tester,
    ) async {
      final router = AppRouter.createRouter(initialLocation: '/tanimsiz-sayfa');

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(find.textContaining('Sayfa bulunamadı'), findsOneWidget);
    });
  });
}
