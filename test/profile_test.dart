import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paw_care/core/theme/theme_cubit.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/data/repositories/settings_repository.dart';
import 'package:paw_care/domain/entities/dog.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/domain/entities/vaccination.dart';
import 'package:paw_care/domain/repositories/dog_repository_interface.dart';
import 'package:paw_care/domain/repositories/settings_repository_interface.dart';
import 'package:paw_care/domain/usecases/pet/get_dog_profile_use_case.dart';
import 'package:paw_care/domain/usecases/settings/get_app_settings_use_case.dart';
import 'package:paw_care/domain/usecases/settings/update_app_settings_use_case.dart';
import 'package:paw_care/features/auth/cubit/role_cubit.dart';
import 'package:paw_care/features/profile/cubit/profile_cubit.dart';
import 'package:paw_care/features/profile/cubit/profile_state.dart';
import 'package:paw_care/features/profile/view/profile_screen.dart';
import 'package:paw_care/features/profile/widgets/theme_selector_card.dart';

// Test amaçlı FakeDogRepository
class FakeDogRepository implements DogRepositoryInterface {
  Dog? currentDog = const Dog(
    id: 'dog_1',
    name: 'Barley',
    breed: 'Golden Retriever',
    ageYears: 3,
    weightKg: 28.0,
    gender: 'Erkek',
    microchip: 'TR-98217349182',
    photoPath: 'assets/images/barley.jpg',
    allergyNote: 'Tavuk alerjisi var.',
    behaviorNote: 'Uysal ve enerjik.',
    clinicName: 'Pati Veteriner Kliniği',
    clinicPhone: '+90 212 555 44 33',
    vaccinations: [],
  );

  @override
  Future<Dog?> getCurrentDog() async => currentDog;

  @override
  Future<List<Dog>> getDogs() async =>
      currentDog != null ? [currentDog!] : [];

  @override
  Future<void> saveDog(Dog dog) async {
    currentDog = dog;
  }

  @override
  Future<void> addVaccination(String dogId, Vaccination vaccination) async {}

  @override
  Future<void> updateVaccinationStatus(
    String dogId,
    String vaccinationId,
    VaccineStatus newStatus, {
    String? completionDate,
  }) async {}
}

void main() {
  group('Adım 5.2: ProfileCubit Unit Testleri', () {
    late DogRepositoryInterface mockDogRepo;
    late SettingsRepositoryInterface mockSettingsRepo;
    late GetDogProfileUseCase getDogProfileUseCase;
    late GetAppSettingsUseCase getAppSettingsUseCase;
    late UpdateAppSettingsUseCase updateAppSettingsUseCase;
    late ProfileCubit cubit;

    setUp(() {
      mockDogRepo = FakeDogRepository();
      mockSettingsRepo = SettingsRepository.inMemory();
      getDogProfileUseCase = GetDogProfileUseCase(mockDogRepo);
      getAppSettingsUseCase = GetAppSettingsUseCase(mockSettingsRepo);
      updateAppSettingsUseCase = UpdateAppSettingsUseCase(mockSettingsRepo);

      cubit = ProfileCubit(
        getDogProfileUseCase: getDogProfileUseCase,
        getAppSettingsUseCase: getAppSettingsUseCase,
        updateAppSettingsUseCase: updateAppSettingsUseCase,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Başlangıç durumunda varsayılan değerler atanır', () {
      expect(cubit.state.status, equals(ProfileStatus.initial));
      expect(cubit.state.userName, equals('Aygen Yıldırım'));
      expect(cubit.state.role, equals(UserRole.owner));
      expect(cubit.state.notificationsEnabled, isTrue);
    });

    test(
      'loadProfile domain usecase üzerinden köpeği ve ayarları getirir',
      () async {
        await cubit.loadProfile();

        expect(cubit.state.status, equals(ProfileStatus.loaded));
        expect(cubit.state.dog, isNotNull);
        expect(cubit.state.dog?.name, equals('Barley'));
      },
    );

    test('updateUserInfo isim, e-posta ve telefonu günceller', () {
      cubit.updateUserInfo(
        name: 'Deniz A.',
        email: 'deniz@pawcare.com',
        phone: '+90 555 987 65 43',
      );

      expect(cubit.state.userName, equals('Deniz A.'));
      expect(cubit.state.userEmail, equals('deniz@pawcare.com'));
      expect(cubit.state.userPhone, equals('+90 555 987 65 43'));
    });

    test('setThemeMode tema modunu günceller ve kaydeder', () async {
      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, equals(ThemeMode.dark));
      expect(mockSettingsRepo.getThemeMode(), equals('dark'));

      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      expect(mockSettingsRepo.getThemeMode(), equals('light'));
    });

    test(
      'toggleRole rolü köpek sahibi ve hizmet veren arasında değiştirir',
      () async {
        expect(cubit.state.role, equals(UserRole.owner));

        await cubit.toggleRole();
        expect(cubit.state.role, equals(UserRole.sitter));
        expect(mockSettingsRepo.getUserRole(), equals('sitter'));

        await cubit.toggleRole();
        expect(cubit.state.role, equals(UserRole.owner));
        expect(mockSettingsRepo.getUserRole(), equals('owner'));
      },
    );

    test('toggleNotifications bildirim ayarını değiştirir', () {
      expect(cubit.state.notificationsEnabled, isTrue);
      cubit.toggleNotifications(false);
      expect(cubit.state.notificationsEnabled, isFalse);
    });
  });

  group('Adım 5.2: ProfileScreen & ThemeSelectorCard Widget Testleri', () {
    late SettingsRepositoryInterface settingsRepo;
    late ThemeCubit themeCubit;
    late RoleCubit roleCubit;
    late ProfileCubit profileCubit;
    late AppState appState;

    setUp(() {
      settingsRepo = SettingsRepository.inMemory();
      themeCubit = ThemeCubit(settingsRepo);
      roleCubit = RoleCubit(settingsRepository: settingsRepo);
      appState = AppState();

      profileCubit = ProfileCubit(
        dogRepository: FakeDogRepository(),
        settingsRepository: settingsRepo,
      );
    });

    tearDown(() {
      themeCubit.close();
      roleCubit.close();
      profileCubit.close();
    });

    Widget createTestWidget({required Widget child}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: themeCubit),
          BlocProvider.value(value: roleCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: AppStateScope(
          notifier: appState,
          child: MaterialApp(home: child),
        ),
      );
    }

    testWidgets(
      'ProfileScreen temel bileşenleri ve kullanıcı bilgilerini gösterir',
      (tester) async {
        await profileCubit.loadProfile();

        await tester.pumpWidget(
          createTestWidget(child: ProfileScreen(cubit: profileCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hesap & Profil'), findsOneWidget);
        expect(find.text('Aygen Yıldırım'), findsOneWidget);
        expect(find.text('aygen@pawcare.com'), findsOneWidget);
        expect(find.text('Köpek Sahibi'), findsOneWidget);
        expect(find.text('Görünüm ve Tema'), findsOneWidget);
        expect(find.text('Ayarlar & Tercihler'), findsOneWidget);
        expect(find.text('Bildirim Tercihleri'), findsOneWidget);
        expect(find.text('Çıkış Yap'), findsOneWidget);
      },
    );

    testWidgets(
      'ThemeSelectorCard üzerinde Koyu Haki seçildiğinde ThemeCubit dark mod olur',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(child: const Scaffold(body: ThemeSelectorCard())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Koyu Haki'), findsOneWidget);
        expect(find.text('Açık'), findsOneWidget);

        // "Koyu Haki" seçeneğine tıkla
        await tester.tap(find.text('Koyu Haki'));
        await tester.pumpAndSettle();

        expect(themeCubit.state, equals(ThemeMode.dark));

        // "Açık" seçeneğine tıkla
        await tester.tap(find.text('Açık'));
        await tester.pumpAndSettle();

        expect(themeCubit.state, equals(ThemeMode.light));
      },
    );

    testWidgets(
      'Rolü Değiştir butonuna basıldığında rol hizmet veren moduna geçer',
      (tester) async {
        await profileCubit.loadProfile();

        await tester.pumpWidget(
          createTestWidget(child: ProfileScreen(cubit: profileCubit)),
        );
        await tester.pumpAndSettle();

        // "Hizmet Veren Moduna Geç" butonuna tıkla
        final switchBtn = find.text('Hizmet Veren Moduna Geç');
        expect(switchBtn, findsOneWidget);
        await tester.ensureVisible(switchBtn);
        await tester.tap(switchBtn);
        await tester.pumpAndSettle();

        expect(profileCubit.state.role, equals(UserRole.sitter));
        expect(roleCubit.state, equals(UserRole.sitter));
      },
    );

    testWidgets('Çıkış Yap butonuna basıldığında onay diyaloğu açılır', (
      tester,
    ) async {
      await profileCubit.loadProfile();
      bool loggedOut = false;

      await tester.pumpWidget(
        createTestWidget(
          child: ProfileScreen(
            cubit: profileCubit,
            onLogout: () => loggedOut = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Çıkış yap butonuna bas (ekranda görünür yap)
      final logoutBtn = find.text('Çıkış Yap');
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Çıkış Yapılsın mı?'), findsOneWidget);

      // Diyalogdaki Çıkış Yap'a bas
      final dialogLogoutBtn = find.widgetWithText(FilledButton, 'Çıkış Yap');
      await tester.tap(dialogLogoutBtn);
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });
  });
}
