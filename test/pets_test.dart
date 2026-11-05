import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/app_state.dart';
import 'package:paw_care/core/widgets/paw_header_actions.dart';
import 'package:paw_care/data/models/models.dart';
import 'package:paw_care/domain/repositories/dog_repository_interface.dart';
import 'package:paw_care/domain/usecases/pet/add_vaccination_use_case.dart';
import 'package:paw_care/domain/usecases/pet/get_dog_profile_use_case.dart';
import 'package:paw_care/features/pets/cubit/pets_cubit.dart';
import 'package:paw_care/features/pets/cubit/pets_state.dart';
import 'package:paw_care/features/pets/view/dog_profile_screen.dart';
import 'package:paw_care/features/pets/widgets/health_card_modal.dart';

// Test amaçlı sahte DogRepository
class FakeDogRepository implements DogRepositoryInterface {
  Dog? dog;

  FakeDogRepository(this.dog);

  @override
  Future<Dog?> getCurrentDog() async => dog;

  @override
  Future<List<Dog>> getDogs() async => dog != null ? [dog!] : [];

  @override
  Future<void> saveDog(covariant Dog dog) async {
    this.dog = dog;
  }

  @override
  Future<void> addVaccination(
    String dogId,
    covariant Vaccination vaccination,
  ) async {
    if (dog != null) {
      final updatedVaccinations = List<Vaccination>.from(dog!.vaccinations)
        ..add(vaccination);
      dog = dog!.copyWith(vaccinations: updatedVaccinations);
    }
  }

  @override
  Future<void> updateVaccinationStatus(
    String dogId,
    String vaccinationId,
    VaccineStatus newStatus, {
    String? completionDate,
  }) async {
    if (dog != null) {
      final updatedVaccinations = dog!.vaccinations.map((v) {
        if (v.id == vaccinationId) {
          return v.copyWith(status: newStatus, completionDate: completionDate);
        }
        return v;
      }).toList();
      dog = dog!.copyWith(vaccinations: updatedVaccinations);
    }
  }
}

void main() {
  group('Faz 4 Adım 4.4: PetsCubit ve Köpek Profili Testleri', () {
    late FakeDogRepository fakeDogRepo;

    final testDog = Dog(
      id: 'dog_barley',
      name: 'Barley',
      breed: 'Golden Retriever',
      ageYears: 2,
      weightKg: 28.5,
      gender: 'Erkek',
      microchip: '900215002941842',
      photoPath: 'assets/images/barley.jpg',
      allergyNote: 'Tavuk proteini alerjisi — Yalnızca kuzu etli mama veriniz.',
      behaviorNote: 'İnsanlara ve köpeklere karşı uysal.',
      clinicName: 'Kadıköy Veteriner Polikliniği',
      clinicPhone: '+90 216 345 67 89',
      vaccinations: [
        Vaccination(
          id: 'v_1',
          title: 'Karma Aşı (DHPPi+L)',
          dueDate: '26 Ekim 2026',
          status: VaccineStatus.upcoming,
          vetName: 'Dr. Selin Bulut',
        ),
        Vaccination(
          id: 'v_2',
          title: 'Kuduz Aşısı (Rabies)',
          dueDate: '14 Haziran 2026',
          status: VaccineStatus.completed,
          vetName: 'Dr. Selin Bulut',
          completionDate: '14 Haziran 2026',
        ),
      ],
    );

    setUp(() {
      fakeDogRepo = FakeDogRepository(testDog);
    });

    test('PetsCubit başlangıç durumu PetsStatus.initial olmalıdır', () {
      final cubit = PetsCubit(dogRepository: fakeDogRepo);
      expect(cubit.state.status, equals(PetsStatus.initial));
      expect(cubit.state.dog, isNull);
      cubit.close();
    });

    test('loadPetProfile köpeği depodan yükler', () async {
      final cubit = PetsCubit(
        getDogProfileUseCase: GetDogProfileUseCase(fakeDogRepo),
        addVaccinationUseCase: AddVaccinationUseCase(fakeDogRepo),
        dogRepository: fakeDogRepo,
      );

      await cubit.loadPetProfile();

      expect(cubit.state.status, equals(PetsStatus.loaded));
      expect(cubit.state.dog?.name, equals('Barley'));
      expect(cubit.state.dog?.breed, equals('Golden Retriever'));
      expect(cubit.state.dog?.vaccinations.length, equals(2));
      cubit.close();
    });

    test('updatePhotoPath profil resmini kalıcı olarak günceller ve Hive deposuna kaydeder', () async {
      final cubit = PetsCubit(dogRepository: fakeDogRepo);
      await cubit.loadPetProfile();

      const newPhoto = 'assets/images/barley_new.jpg';
      await cubit.updatePhotoPath(newPhoto);

      expect(cubit.state.dog?.photoPath, equals(newPhoto));
      expect(fakeDogRepo.dog?.photoPath, equals(newPhoto));
      cubit.close();
    });

    test('updateDogProfile köpek profil bilgilerini günceller', () async {
      final cubit = PetsCubit(dogRepository: fakeDogRepo);
      await cubit.loadPetProfile();

      final updatedDog = testDog.copyWith(weightKg: 29.5);
      await cubit.updateDogProfile(updatedDog);

      expect(cubit.state.dog?.weightKg, equals(29.5));
      expect(fakeDogRepo.dog?.weightKg, equals(29.5));
      cubit.close();
    });

    test('addVaccination yeni aşı kaydını depoya ekler', () async {
      final cubit = PetsCubit(dogRepository: fakeDogRepo);
      await cubit.loadPetProfile();

      final newVaccine = Vaccination(
        id: 'v_new',
        title: 'Bronşin Aşısı',
        dueDate: '10 Aralık 2026',
        status: VaccineStatus.upcoming,
        vetName: 'Dr. Selin Bulut',
      );

      await cubit.addVaccination(newVaccine);

      expect(cubit.state.dog?.vaccinations.length, equals(3));
      expect(fakeDogRepo.dog?.vaccinations.any((v) => v.id == 'v_new'), isTrue);
      cubit.close();
    });

    test('toggleVaccinationStatus aşı durumunu tamamlandı ve yaklaşan arasında değiştirir', () async {
      final cubit = PetsCubit(dogRepository: fakeDogRepo);
      await cubit.loadPetProfile();

      // v_1 başlangıçta upcoming -> completed olmalı
      await cubit.toggleVaccinationStatus('v_1');
      expect(
        cubit.state.dog?.vaccinations.firstWhere((v) => v.id == 'v_1').status,
        equals(VaccineStatus.completed),
      );

      // Tekrar tıklandığında completed -> upcoming olmalı
      await cubit.toggleVaccinationStatus('v_1');
      expect(
        cubit.state.dog?.vaccinations.firstWhere((v) => v.id == 'v_1').status,
        equals(VaccineStatus.upcoming),
      );

      cubit.close();
    });

    testWidgets(
      'DogProfileScreen PetsCubit ve PawHeaderActions ile doğru render edilir',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final cubit = PetsCubit(dogRepository: fakeDogRepo);
        await cubit.loadPetProfile();

        final appState = AppState();

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              notifier: appState,
              child: DogProfileScreen(cubit: cubit),
            ),
          ),
        );
        await tester.pump();

        // Başlık ve ikonlar
        expect(find.text('Köpek Profili & Sağlık'), findsOneWidget);
        expect(find.byType(PawHeaderActions), findsOneWidget);

        // Köpek adı ve mikroçip
        expect(find.text('Barley'), findsWidgets);
        expect(find.textContaining('900215002941842'), findsOneWidget);

        // İstatistik kartları
        expect(find.text('Yaş'), findsOneWidget);
        expect(find.text('Ağırlık'), findsOneWidget);
        expect(find.text('Cinsiyet'), findsOneWidget);

        // Kritik Alerji Uyarısı
        expect(find.text('Kritik Sağlık & Alerji Uyarısı'), findsOneWidget);
        expect(find.textContaining('Tavuk proteini alerjisi'), findsWidgets);

        // Aşı Takvimi Listesi
        expect(find.text('Aşı Takvimi & Kayıtlar'), findsOneWidget);
        expect(find.text('Karma Aşı (DHPPi+L)'), findsOneWidget);
        expect(find.text('Kuduz Aşısı (Rabies)'), findsOneWidget);

        // Veteriner Kliniği
        expect(find.text('Sorumlu Veteriner Kliniği'), findsOneWidget);
        expect(find.text('Kadıköy Veteriner Polikliniği'), findsOneWidget);

        cubit.close();
      },
    );

    testWidgets('HealthCardModal açılır ve aşı takvim özetini gösterir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            notifier: appState,
            child: const Scaffold(body: HealthCardModal()),
          ),
        ),
      );
      await tester.pump();

      // Modal başlığı
      expect(find.text('Barley — Sağlık Kartı'), findsOneWidget);
      expect(find.text('Yaklaşan Aşı: Karma Aşı (DHPPi+L)'), findsOneWidget);
      expect(find.text('Aşı ve Tedavi Kayıtları'), findsOneWidget);
      expect(find.text('Yeni Aşı / Tedavi Ekle'), findsOneWidget);
    });
  });
}
