import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/features/auth/widgets/login_modal.dart';
import 'package:paw_care/features/auth/widgets/signup_modal.dart';
import 'package:paw_care/features/onboarding/view/welcome_screen.dart';
import 'package:paw_care/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Başlangıç ve Karşılama Akışı Testleri', () {
    testWidgets(
      'Uygulama açılışında WelcomeScreen görüntülenir ve demo rolleri seçilebilir',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final authRepo = InMemoryAuthRepository();

        await tester.pumpWidget(
          PawCareApp(
            enableSplash: false,
            settingsRepository: SettingsRepository.inMemory(),
            authRepository: authRepo,
          ),
        );
        await tester.pump();

        // Stitch karşılama ekranı bileşenlerinin varlığını doğrular
        expect(find.text('Dostunuz için en güvenilir eller.'), findsOneWidget);
        expect(find.text('Köpek Sahibi Olarak Başla'), findsOneWidget);
        expect(find.text('Hizmet Veren Paneline Geç'), findsOneWidget);
        expect(find.text('Giriş Yap'), findsOneWidget);
        expect(find.text('Hesap Oluştur'), findsOneWidget);

        // Hizmet Veren Paneline Geçişi test eder
        final sitterCard = find.text('Hizmet Veren Paneline Geç');
        await tester.ensureVisible(sitterCard);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(sitterCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Yetkilendirilmemiş kullanıcı GoRouter koruması gereği karşılamada kalır
        expect(find.byType(WelcomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Giriş Yap butonu LoginModal açar ve başarılı girişte ana sayfaya yönlendirir',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final authRepo = InMemoryAuthRepository();

        await tester.pumpWidget(
          PawCareApp(
            enableSplash: false,
            settingsRepository: SettingsRepository.inMemory(),
            authRepository: authRepo,
          ),
        );
        await tester.pump();

        // Giriş Yap butonuna tıklar
        final loginBtn = find.widgetWithText(ElevatedButton, 'Giriş Yap');
        await tester.ensureVisible(loginBtn);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(loginBtn);
        await tester.pump(const Duration(milliseconds: 200));

        // LoginModal penceresinin açıldığını doğrular
        expect(find.byType(LoginModal), findsOneWidget);
        expect(find.text('Tekrar Hoş Geldin'), findsOneWidget);

        // Modal içindeki Giriş Yap butonuna tıklar
        final modalLoginBtn = find.descendant(
          of: find.byType(LoginModal),
          matching: find.text('Giriş Yap'),
        );
        await tester.tap(modalLoginBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Giriş sonrası modalın kapandığını ve ana sayfanın açıldığını doğrular
        expect(find.byType(LoginModal), findsNothing);
        expect(find.textContaining('Aygen'), findsWidgets);
      },
    );

    testWidgets('Hesap Oluştur butonu SignUpModal açar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        PawCareApp(
          enableSplash: false,
          settingsRepository: SettingsRepository.inMemory(),
        ),
      );
      await tester.pump();

      // Hesap Oluştur butonuna tıklar
      final signUpBtn = find.widgetWithText(OutlinedButton, 'Hesap Oluştur');
      await tester.ensureVisible(signUpBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(signUpBtn);
      await tester.pump(const Duration(milliseconds: 200));

      // SignUpModal penceresinin açıldığını doğrular
      expect(find.byType(SignUpModal), findsOneWidget);
      expect(find.text('PawCare\'e Katıl'), findsOneWidget);
    });
  });
}
