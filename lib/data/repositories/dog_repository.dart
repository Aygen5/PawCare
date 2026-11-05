import 'package:hive/hive.dart';

import '../../domain/entities/dog.dart' as entity;
import '../../domain/entities/vaccination.dart' as entity;
import '../../domain/repositories/dog_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart';

class DogRepository implements DogRepositoryInterface {
  /// Birincil köpek profilini asenkron getirir (varsayılan 'dog_1' veya ilk kayıt).
  @override
  Future<entity.Dog?> getCurrentDog() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.dogsBox) || HiveBoxes.dogs.isEmpty) {
        return null;
      }
      return HiveBoxes.dogs.get('dog_1') ?? HiveBoxes.dogs.values.first;
    } catch (_) {
      return null;
    }
  }

  /// Tüm kayıtlı köpek profillerini getirir.
  @override
  Future<List<entity.Dog>> getDogs() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.dogsBox) || HiveBoxes.dogs.isEmpty) {
        return [];
      }
      return HiveBoxes.dogs.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// Köpek profilini Hive veritabanına kaydeder veya günceller.
  @override
  Future<void> saveDog(entity.Dog dog) async {
    final modelDog = Dog.fromEntity(dog);
    await HiveBoxes.dogs.put(modelDog.id, modelDog);
  }

  /// Belirli bir köpeğe yeni aşı kaydı ekler.
  @override
  Future<void> addVaccination(
    String dogId,
    entity.Vaccination vaccination,
  ) async {
    final dog = HiveBoxes.dogs.get(dogId);
    if (dog != null) {
      final vacModel = Vaccination.fromEntity(vaccination);
      final updatedVaccinations = List<Vaccination>.from(dog.vaccinations)
        ..add(vacModel);
      final updatedDog = dog.copyWith(vaccinations: updatedVaccinations);
      await saveDog(updatedDog);
    }
  }

  /// Aşının durumunu günceller.
  @override
  Future<void> updateVaccinationStatus(
    String dogId,
    String vaccinationId,
    entity.VaccineStatus newStatus, {
    String? completionDate,
  }) async {
    final dog = HiveBoxes.dogs.get(dogId);
    if (dog != null) {
      final updatedVaccinations = dog.vaccinations.map((v) {
        if (v.id == vaccinationId) {
          return v.copyWith(
            status: newStatus,
            completionDate: completionDate ?? v.completionDate,
          );
        }
        return v;
      }).toList();

      final updatedDog = dog.copyWith(vaccinations: updatedVaccinations);
      await saveDog(updatedDog);
    }
  }
}
