import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paw_care/app/app.dart';
import 'package:paw_care/app/router/route_names.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/features/auth/cubit/auth_cubit.dart';
import 'package:paw_care/features/auth/widgets/login_modal.dart';
import 'package:paw_care/features/auth/widgets/signup_modal.dart';
import 'package:paw_care/features/onboarding/view/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Adım 4.1: AuthCubit Birim Testleri', () {
    test('Başlangıç durumu kimlik doğrulanmamış olmalıdır', () {
      final cubit = AuthCubit();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userEmail, isNull);
      cubit.close();
    });

    test('login geçerli bilgilerle kullanıcıyı ve rolü doğrular', () async {
      final repo = SettingsRepository.inMemory();
      final cubit = AuthCubit(settingsRepository: repo);

      final success = await cubit.login(
        email: 'aygen@pawcare.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.role, UserRole.owner);
      expect(repo.getUserRole(), 'owner');

      cubit.close();
    });

    test('sitter e-posta adresiyle girişte rol UserRole.sitter olur', () async {
      final repo = SettingsRepository.inMemory();
      final cubit = AuthCubit(settingsRepository: repo);

      final success = await cubit.login(
        email: 'ayse@pawcare.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.role, UserRole.sitter);
      expect(repo.getUserRole(), 'sitter');

      cubit.close();
    });

    test('signUp yeni hesap oluşturur ve oturumu açar', () async {
      final repo = SettingsRepository.inMemory();
      final cubit = AuthCubit(settingsRepository: repo);

      final success = await cubit.signUp(
        name: 'Yeni Kullanıcı',
        email: 'yeni@pawcare.com',
        password: 'password123',
        role: UserRole.owner,
      );

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userName, 'Yeni Kullanıcı');

      await cubit.logout();
      expect(cubit.state.isAuthenticated, isFalse);

      cubit.close();
    });
  });

  group(
    'Adım 4.1: Onboarding WelcomeScreen ve Auth Modalları Entegrasyon Testleri',
    () {
      testWidgets(
        'WelcomeScreen Stitch karşılama bileşenlerini başarıyla çizer',
        (tester) async {
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

          // WelcomeScreen ve Stitch elemanlarını doğrular
          expect(find.byType(WelcomeScreen), findsOneWidget);
          expect(find.text('PawCare'), findsOneWidget);
          expect(find.text('Şefkatli & Güvenilir Bakım'), findsOneWidget);
          expect(
            find.text('Dostunuz için en güvenilir eller.'),
            findsOneWidget,
          );
          expect(find.text('Köpek Sahibi Olarak Başla'), findsOneWidget);
          expect(find.text('Hizmet Veren Paneline Geç'), findsOneWidget);
          expect(find.text('Giriş Yap'), findsOneWidget);
          expect(find.text('Hesap Oluştur'), findsOneWidget);
        },
      );

      testWidgets(
        'Giriş Yap butonu LoginModal açar ve başarılı girişi tamamlar',
        (tester) async {
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

          final loginBtn = find.widgetWithText(ElevatedButton, 'Giriş Yap');
          await tester.ensureVisible(loginBtn);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(loginBtn);
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.byType(LoginModal), findsOneWidget);
          expect(find.text('Tekrar Hoş Geldin'), findsOneWidget);

          final modalLoginBtn = find.descendant(
            of: find.byType(LoginModal),
            matching: find.text('Giriş Yap'),
          );
          await tester.tap(modalLoginBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(LoginModal), findsNothing);
        },
      );

      testWidgets('Hesap Oluştur butonu SignUpModal açar', (tester) async {
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

        final signUpBtn = find.widgetWithText(OutlinedButton, 'Hesap Oluştur');
        await tester.ensureVisible(signUpBtn);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(signUpBtn);
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(SignUpModal), findsOneWidget);
        expect(find.text('PawCare\'e Katıl'), findsOneWidget);
      });
    },
  );
}
