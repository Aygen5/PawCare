import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/utils/image_storage_service.dart';
import 'package:paw_care/domain/entities/booking.dart';
import 'package:paw_care/domain/entities/dog.dart';
import 'package:paw_care/domain/entities/vaccination.dart';

void main() {
  group('Faz 3: Cloud Firestore & Çift Katmanlı Depo Testleri', () {
    test('ImageStorageService URL ve Asset ayrımı doğru çalışmalıdır', () {
      expect(ImageStorageService.isNetworkUrl('https://firebasestorage.googleapis.com/v0/b/pawcare.appspot.com/pets/dog.jpg'), isTrue);
      expect(ImageStorageService.isNetworkUrl('http://example.com/photo.png'), isTrue);
      expect(ImageStorageService.isNetworkUrl('assets/images/barley.jpg'), isFalse);
      expect(ImageStorageService.isAssetPath('assets/images/barley.jpg'), isTrue);
      expect(ImageStorageService.isAssetPath('/data/user/0/pawcare/photo.jpg'), isFalse);
    });

    test('BookingRequest toMap ve fromMap Firestore serileştirmesi kayıpsız çalışmalıdır', () {
      final now = DateTime(2026, 10, 24, 14, 0);
      final booking = BookingRequest(
        id: 'b_123',
        ownerId: 'owner_456',
        dogId: 'dog_789',
        sitterId: 'sitter_1',
        sitterName: 'Ayşe Yılmaz',
        sitterPhoto: 'assets/images/ayse.jpg',
        petName: 'Barley',
        petBreed: 'Golden Retriever',
        serviceTitle: 'Köpek Oteli — 2 Gece',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        totalPrice: 1950.0,
        careNotes: 'Tavuk alerjisi var.',
        status: BookingStatus.confirmed,
        createdAt: now,
      );

      final map = booking.toMap();
      expect(map['id'], 'b_123');
      expect(map['ownerId'], 'owner_456');
      expect(map['status'], 'confirmed');
      expect(map['totalPrice'], 1950.0);

      final reconstructed = BookingRequest.fromMap(map, docId: 'b_123');
      expect(reconstructed.id, 'b_123');
      expect(reconstructed.petName, 'Barley');
      expect(reconstructed.status, BookingStatus.confirmed);
    });

    test('Dog Entity toMap ve fromMap aşı dizisi ile serileştirilebilir', () {
      const dog = Dog(
        id: 'dog_1',
        ownerId: 'owner_1',
        name: 'Barley',
        breed: 'Golden Retriever',
        ageYears: 2,
        weightKg: 28.5,
        gender: 'Erkek',
        microchip: '900215002941842',
        photoPath: 'assets/images/barley.jpg',
        allergyNote: 'Tavuk alerjisi',
        behaviorNote: 'Uysal',
        clinicName: 'Kadıköy Vet',
        clinicPhone: '+90 216 345 67 89',
        vaccinations: [
          Vaccination(
            id: 'v_1',
            title: 'Karma Aşı',
            dueDate: '26 Ekim 2026',
            status: VaccineStatus.upcoming,
            vetName: 'Dr. Selin Bulut',
          ),
        ],
      );

      final map = dog.toMap();
      expect(map['name'], 'Barley');
      expect((map['vaccinations'] as List).length, 1);

      final reconstructed = Dog.fromMap(map, docId: 'dog_1');
      expect(reconstructed.name, 'Barley');
      expect(reconstructed.vaccinations.first.title, 'Karma Aşı');
    });
  });
}
