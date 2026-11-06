import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paw_care/app/app.dart';
import 'package:paw_care/app/router/route_names.dart';
import 'package:paw_care/core/widgets/paw_bottom_nav.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/domain/entities/user_entity.dart';
import 'package:paw_care/features/auth/cubit/role_cubit.dart';
import 'package:paw_care/features/provider/view/sitter_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Adım 3.4: RoleCubit Birim Testleri', () {
    test('Varsayılan başlangıç rolü UserRole.owner olmalıdır', () {
      final cubit = RoleCubit();
      expect(cubit.state, UserRole.owner);
      cubit.close();
    });

    test('SettingsRepository kayıtlı rolü UserRole.sitter ise başlangıç rolü sitter olmalıdır', () {
      final repo = SettingsRepository.inMemory();
      repo.setUserRole('sitter');
      final cubit = RoleCubit(settingsRepository: repo);
      expect(cubit.state, UserRole.sitter);
      cubit.close();
    });

    test(
      'switchToSitter ve switchToOwner durumları ve depoyu günceller',
      () async {
        final repo = SettingsRepository.inMemory();
        final cubit = RoleCubit(settingsRepository: repo);

        await cubit.switchToSitter();
        expect(cubit.state, UserRole.sitter);
        expect(repo.getUserRole(), 'sitter');

        await cubit.switchToOwner();
        expect(cubit.state, UserRole.owner);
        expect(repo.getUserRole(), 'owner');

        await cubit.toggleRole();
        expect(cubit.state, UserRole.sitter);

        cubit.close();
      },
    );
  });

  group(
    'Adım 3.4: Dinamik Rol Değişimi ve Alt Navigasyon Senkronizasyonu Testleri',
    () {
      testWidgets(
        'Köpek Sahibi rolünden Hizmet Veren rolüne geçişte alt bar sekmeleri anında güncellenir',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final settingsRepo = SettingsRepository.inMemory();
          final authRepo = InMemoryAuthRepository(
            initialUser: const UserEntity(
              uid: 'test_u1',
              email: 'test@pawcare.com',
              displayName: 'Aygen Y.',
              role: UserRole.owner,
            ),
          );

          await tester.pumpWidget(
            PawCareApp(
              initialLocation: RoutePaths.home,
              settingsRepository: settingsRepo,
              authRepository: authRepo,
            ),
          );
          await tester.pump();

          // Köpek Sahibi alt bar sekmelerini doğrular
          expect(find.byType(PawBottomNav), findsOneWidget);
          expect(find.text('Ana Sayfa'), findsOneWidget);
          expect(find.text('Keşfet'), findsOneWidget);
          expect(find.text('Köpeklerim'), findsOneWidget);
          expect(find.text('Taleplerim'), findsOneWidget);

          // Başlıktaki "Hizmet Veren" hap butonuna tıklar
          final sitterSwitchButton = find.text('Hizmet Veren');
          await tester.tap(sitterSwitchButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Hizmet Veren Paneli ve yeni sekmelerin geldiğini doğrular
          expect(find.byType(SitterDashboardScreen), findsOneWidget);
          expect(find.text('Talepler'), findsOneWidget);
          expect(find.text('İlanım'), findsOneWidget);
          expect(find.text('Takvim'), findsOneWidget);
          expect(find.text('Yorumlar'), findsOneWidget);

          // Sitter panelinden "Sahip Modu" butonuna tıklayarak geri döner
          final ownerSwitchButton = find.text('Sahip Modu');
          await tester.tap(ownerSwitchButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Tekrar Köpek Sahibi sekmelerinin geldiğini doğrular
          expect(find.text('Ana Sayfa'), findsOneWidget);
          expect(find.text('Keşfet'), findsOneWidget);
        },
      );
    },
  );
}
