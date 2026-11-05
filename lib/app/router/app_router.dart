import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/repositories/settings_repository_interface.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/role_cubit.dart';
import '../../features/bookings/view/owner_bookings_screen.dart';
import '../../features/discovery/view/explore_screen.dart';
import '../../features/discovery/view/sitter_detail_screen.dart';
import '../../features/home/view/owner_home_screen.dart';
import '../../features/onboarding/view/welcome_screen.dart';
import '../../features/pets/view/dog_profile_screen.dart';
import '../../features/profile/view/profile_screen.dart';
import '../../features/provider/view/sitter_calendar_tab.dart';
import '../../features/provider/view/sitter_dashboard_screen.dart';
import '../../features/provider/view/sitter_listing_tab.dart';
import '../../features/provider/view/sitter_reviews_tab.dart';
import '../../features/splash/cubit/splash_cubit.dart';
import '../../features/splash/view/splash_page.dart';
import 'app_shell.dart';
import 'route_names.dart';

/// PawCare GoRouter rota yöneticisi ve sayfa geçiş yapılandırması.
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellNav');

  /// Belirtilen başlangıç konumuyla GoRouter örneği oluşturur.
  static GoRouter createRouter({
    String initialLocation = RoutePaths.splash,
    SettingsRepositoryInterface? settingsRepository,
    AuthCubit? authCubit,
  }) {
    final settings = settingsRepository ?? SettingsRepository.inMemory();

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: authCubit != null
          ? GoRouterRefreshStream(authCubit.stream)
          : null,
      redirect: (context, state) {
        if (authCubit == null) return null;
        final isAuth = authCubit.state.isAuthenticated;
        final path = state.uri.path;

        // Korumalı rotalar: Giriş yapmamış kullanıcılar welcome ekranına yönlendirilir
        final isProtected = path.startsWith('/provider') ||
            path.startsWith('/sitter') ||
            path == RoutePaths.pets ||
            path == RoutePaths.bookings;

        if (!isAuth && isProtected) {
          return RoutePaths.welcome;
        }

        return null;
      },
      routes: [
        // 1. Açılış Splash Ekranı
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (context, state) {
            return BlocProvider(
              create: (_) => SplashCubit(settingsRepository: settings),
              child: SplashPage(
                onReady: (hasSeenOnboarding) {
                  context.go(RoutePaths.welcome);
                },
              ),
            );
          },
        ),

        // 2. Karşılama ve Giriş/Kayıt Ekranı
        GoRoute(
          path: RoutePaths.welcome,
          name: RouteNames.welcome,
          builder: (context, state) {
            return WelcomeScreen(
              onContinue: () {
                final role = context.read<RoleCubit>().state;
                if (role == UserRole.sitter) {
                  context.go(RoutePaths.sitterDashboard);
                } else {
                  context.go(RoutePaths.home);
                }
              },
            );
          },
        ),

        // 3. Bakıcı Detay Ekranı (Tam Ekran)
        GoRoute(
          path: RoutePaths.sitterDetail,
          name: RouteNames.sitterDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final fallbackSitter = SitterListing(
              id: 'sitter_1',
              name: 'Ayşe Yılmaz',
              facilityTitle: 'Mutlu Patiler Köpek Oteli',
              category: 'Köpek Oteli',
              rating: 4.9,
              reviewsCount: 128,
              pricePerUnit: 950.0,
              unitLabel: 'gece',
              location: 'Caddebostan, Kadıköy',
              distanceKm: 1.2,
              imagePath: 'assets/images/ayse.jpg',
              galleryPaths: [
                'assets/images/hotel_garden.jpg',
                'assets/images/ayse.jpg',
              ],
              bio:
                  '10 dönüm çim bahçe içinde, 7/24 veteriner hekim gözetiminde ve web kameralı bireysel süitlerde 5 yıldızlı köpek konaklama ve kreş deneyimi.',
              amenities: [
                'Geniş Çim Bahçe (5000 m²)',
                '7/24 Canlı Kamera',
                'Veteriner Hekim Kontrolü',
              ],
            );
            final sitter = state.extra as SitterListing? ?? fallbackSitter;

            return SitterDetailScreen(
              sitter: sitter,
              onBack: () => context.pop(),
              onBookingCompleted: () {
                context.go(RoutePaths.bookings);
              },
            );
          },
        ),

        // 4. Alt Navigasyonlu ve Mobil Çerçeveli Ana Uygulama İskeleti (AppShell)
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            // --- Köpek Sahibi Rotaları ---
            GoRoute(
              path: RoutePaths.home,
              name: RouteNames.home,
              builder: (context, state) => OwnerHomeScreen(
                onSitterSelected: (sitter) =>
                    context.push(RoutePaths.sitterDetail, extra: sitter),
              ),
            ),
            GoRoute(
              path: RoutePaths.explore,
              name: RouteNames.explore,
              builder: (context, state) => ExploreScreen(
                onSitterSelected: (sitter) =>
                    context.push(RoutePaths.sitterDetail, extra: sitter),
              ),
            ),
            GoRoute(
              path: RoutePaths.pets,
              name: RouteNames.pets,
              builder: (context, state) => const DogProfileScreen(),
            ),
            GoRoute(
              path: RoutePaths.bookings,
              name: RouteNames.bookings,
              builder: (context, state) => const OwnerBookingsScreen(),
            ),
            GoRoute(
              path: RoutePaths.profile,
              name: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),

            // --- Hizmet Veren / Bakıcı Rotaları ---
            GoRoute(
              path: RoutePaths.sitterDashboard,
              name: RouteNames.sitterDashboard,
              builder: (context, state) => const SitterDashboardScreen(),
            ),
            GoRoute(
              path: RoutePaths.sitterListing,
              name: RouteNames.sitterListing,
              builder: (context, state) => const SitterListingTab(),
            ),
            GoRoute(
              path: RoutePaths.sitterCalendar,
              name: RouteNames.sitterCalendar,
              builder: (context, state) => const SitterCalendarTab(),
            ),
            GoRoute(
              path: RoutePaths.sitterReviews,
              name: RouteNames.sitterReviews,
              builder: (context, state) => const SitterReviewsTab(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Sayfa bulunamadı: ${state.uri.path}')),
      ),
    );
  }
}

/// GoRouter için akış değişikliklerini dinleyip yönlendirmeyi tetikleyen yardımcı sınıf.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
