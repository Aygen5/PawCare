import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_storage_service.dart';
import '../../../data/repositories/firebase_dog_repository.dart';
import '../../../domain/entities/dog.dart';
import '../../../domain/entities/vaccination.dart';
import '../../../domain/repositories/dog_repository_interface.dart';
import '../../../domain/usecases/pet/add_vaccination_use_case.dart';
import '../../../domain/usecases/pet/get_dog_profile_use_case.dart';
import 'pets_state.dart';

/// Köpek Profili, Sağlık Kayıtları ve Fotoğraf Seçimini yöneten Clean Architecture Cubit'i.
class PetsCubit extends Cubit<PetsState> {
  final GetDogProfileUseCase _getDogProfileUseCase;
  final AddVaccinationUseCase _addVaccinationUseCase;
  final DogRepositoryInterface _dogRepository;

  PetsCubit({
    GetDogProfileUseCase? getDogProfileUseCase,
    AddVaccinationUseCase? addVaccinationUseCase,
    DogRepositoryInterface? dogRepository,
  }) : _dogRepository = dogRepository ?? FirebaseDogRepository(),
       _getDogProfileUseCase =
           getDogProfileUseCase ??
           GetDogProfileUseCase(dogRepository ?? FirebaseDogRepository()),
       _addVaccinationUseCase =
           addVaccinationUseCase ??
           AddVaccinationUseCase(dogRepository ?? FirebaseDogRepository()),
       super(const PetsState());

  /// Varsayılan yedek köpek profili.
  static final Dog fallbackDog = Dog(
    id: 'dog_1',
    name: 'Barley',
    breed: 'Golden Retriever',
    ageYears: 2,
    weightKg: 28.5,
    gender: 'Erkek',
    microchip: '900215002941842',
    photoPath: 'assets/images/barley.jpg',
    allergyNote: 'Tavuk proteini alerjisi — Yalnızca kuzu etli mama veriniz.',
    behaviorNote:
        'İnsanlara ve diğer köpeklere karşı uysal ve son derece enerjik.',
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
      Vaccination(
        id: 'v_3',
        title: 'İç & Dış Parazit Tedavisi',
        dueDate: '02 Eylül 2026',
        status: VaccineStatus.completed,
        vetName: 'Dr. Selin Bulut',
        completionDate: '02 Eylül 2026',
      ),
      Vaccination(
        id: 'v_4',
        title: 'Kennel Cough (Bronşin)',
        dueDate: '15 Kasım 2026',
        status: VaccineStatus.upcoming,
        vetName: 'Dr. Selin Bulut',
      ),
    ],
  );

  /// Köpek profilini ve aşı kayıtlarını yükler.
  Future<void> loadPetProfile() async {
    emit(state.copyWith(status: PetsStatus.loading));

    try {
      final rawDog = await _getDogProfileUseCase.call();
      final loadedDog = rawDog is Dog ? rawDog : fallbackDog;
      final rawDogs = await _dogRepository.getDogs();
      final dogsList = rawDogs.isNotEmpty ? rawDogs : [loadedDog];

      emit(
        state.copyWith(
          status: PetsStatus.loaded,
          dog: loadedDog,
          dogs: dogsList,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PetsStatus.error,
          errorMessage: 'Köpek profili yüklenirken hata oluştu: $e',
        ),
      );
    }
  }

  /// Aktif olarak görüntülenen köpeği seçer.
  void selectDog(Dog selected) {
    emit(state.copyWith(dog: selected));
  }

  /// image_picker ile galeriden yeni fotoğraf seçer, kalıcı klasöre kopyalar ve Hive'a kaydeder.
  Future<String?> pickAndSavePetPhoto({ImagePicker? picker}) async {
    final imagePicker = picker ?? ImagePicker();

    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      emit(state.copyWith(isPhotoUpdating: true));

      // Fotoğrafı yerel diske kaydet ve Firebase Storage'a yükle
      final current = state.dog ?? fallbackDog;
      final photoUrl = await ImageStorageService.uploadPetPhoto(
        pickedFile,
        userId: current.ownerId,
        petId: current.id,
      );

      // Mevcut profili güncelle
      await updatePhotoPath(photoUrl);

      emit(state.copyWith(isPhotoUpdating: false));
      return photoUrl;
    } catch (e) {
      emit(
        state.copyWith(
          isPhotoUpdating: false,
          errorMessage:
              'Fotoğraf seçilirken veya kaydedilirken hata oluştu: $e',
        ),
      );
      return null;
    }
  }

  /// Fotoğraf yolunu doğrudan günceller ve Hive'a kaydeder.
  Future<void> updatePhotoPath(String newPhotoPath) async {
    final current = state.dog ?? fallbackDog;
    final updatedDog = current.copyWith(photoPath: newPhotoPath);

    await _dogRepository.saveDog(updatedDog);

    emit(state.copyWith(status: PetsStatus.loaded, dog: updatedDog));
  }

  /// Köpek profil bilgilerini günceller ve Hive'a kaydeder.
  Future<void> updateDogProfile(Dog updatedDog) async {
    await _dogRepository.saveDog(updatedDog);
    final dogs = await _dogRepository.getDogs();
    emit(
      state.copyWith(
        status: PetsStatus.loaded,
        dog: updatedDog,
        dogs: dogs.isNotEmpty ? dogs : [updatedDog],
      ),
    );
  }

  /// Yeni aşı kaydı ekler ve Hive'a yansıtır.
  Future<void> addVaccination(Vaccination vaccination) async {
    final currentDog = state.dog ?? fallbackDog;
    await _addVaccinationUseCase.call(currentDog.id, vaccination);

    // Güncellenmiş köpeği depodan yeniden yükle
    final updated =
        (await _dogRepository.getCurrentDog()) ??
        currentDog.copyWith(
          vaccinations: List<Vaccination>.from(currentDog.vaccinations)
            ..add(vaccination),
        );

    emit(state.copyWith(status: PetsStatus.loaded, dog: updated));
  }

  /// Aşının durumunu (Tamamlandı / Yaklaşıyor) değiştirir ve Hive'a kaydeder.
  Future<void> toggleVaccinationStatus(String vaccinationId) async {
    final current = state.dog ?? fallbackDog;
    final updatedVaccinations = current.vaccinations.map((v) {
      if (v.id == vaccinationId) {
        final newStatus = v.status == VaccineStatus.completed
            ? VaccineStatus.upcoming
            : VaccineStatus.completed;
        return v.copyWith(
          status: newStatus,
          completionDate: newStatus == VaccineStatus.completed
              ? '24 Ekim 2026'
              : null,
        );
      }
      return v;
    }).toList();

    final updatedDog = current.copyWith(vaccinations: updatedVaccinations);
    await _dogRepository.saveDog(updatedDog);

    emit(state.copyWith(status: PetsStatus.loaded, dog: updatedDog));
  }

  /// Yeni bir köpek profilini kaydeder ve durumu günceller.
  Future<void> saveNewDog(Dog newDog) async {
    await _dogRepository.saveDog(newDog);
    final dogs = await _dogRepository.getDogs();
    emit(
      state.copyWith(
        status: PetsStatus.loaded,
        dog: newDog,
        dogs: dogs.isNotEmpty ? dogs : [newDog],
      ),
    );
  }

  /// Yeni köpek ekler.
  Future<void> addDog(Dog newDog) => saveNewDog(newDog);
}
