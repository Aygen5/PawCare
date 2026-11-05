import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/dog.dart';
import '../../domain/entities/vaccination.dart';
import '../../domain/repositories/dog_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart' as model;
import 'dog_repository.dart';

/// Cloud Firestore ve Hive L1 Önbellek (Offline-First) destekli Köpek Deposu.
class FirebaseDogRepository implements DogRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseAuth? _firebaseAuthInstance;
  final DogRepository _localRepo;

  FirebaseDogRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    DogRepository? localRepo,
  }) : _firestoreInstance = firestore,
       _firebaseAuthInstance = firebaseAuth,
       _localRepo = localRepo ?? DogRepository();

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  FirebaseAuth? get _firebaseAuth {
    if (_firebaseAuthInstance != null) return _firebaseAuthInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  @override
  Future<Dog?> getCurrentDog() async {
    // 1. Önce L1 Cache (Hive)
    final cached = await _localRepo.getCurrentDog();

    // 2. Firestore senkronizasyonu
    try {
      final fs = _firestore;
      if (fs != null) {
        final currentUid = _getCurrentUserId();
        Query query = fs.collection('dogs');
        if (currentUid != null && currentUid.isNotEmpty) {
          query = query.where('ownerId', isEqualTo: currentUid);
        }

        final snapshot = await query.limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final remoteDog = Dog.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          );
          await _saveToHive(remoteDog);
          return remoteDog;
        }
      }
    } catch (_) {}

    return cached;
  }

  @override
  Future<List<Dog>> getDogs() async {
    final cached = await _localRepo.getDogs();

    try {
      final fs = _firestore;
      if (fs != null) {
        final currentUid = _getCurrentUserId();
        Query query = fs.collection('dogs');
        if (currentUid != null && currentUid.isNotEmpty) {
          query = query.where('ownerId', isEqualTo: currentUid);
        }

        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          final remoteList = snapshot.docs.map((doc) {
            return Dog.fromMap(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            );
          }).toList();

          for (final d in remoteList) {
            await _saveToHive(d);
          }
          return remoteList;
        }
      }
    } catch (_) {}

    return cached;
  }

  @override
  Future<void> saveDog(Dog dog) async {
    final currentUid = _getCurrentUserId();
    final enriched = dog.copyWith(
      ownerId: dog.ownerId ?? currentUid,
    );

    // 1. L1 Cache'e kaydet
    await _localRepo.saveDog(enriched);

    // 2. Firestore'a kaydet
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs
            .collection('dogs')
            .doc(enriched.id)
            .set(enriched.toMap());
      }
    } catch (_) {}
  }

  @override
  Future<void> addVaccination(String dogId, Vaccination vaccination) async {
    await _localRepo.addVaccination(dogId, vaccination);

    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('dogs').doc(dogId).update({
          'vaccinations': FieldValue.arrayUnion([vaccination.toMap()]),
        });
      }
    } catch (_) {}
  }

  @override
  Future<void> updateVaccinationStatus(
    String dogId,
    String vaccinationId,
    VaccineStatus newStatus, {
    String? completionDate,
  }) async {
    await _localRepo.updateVaccinationStatus(
      dogId,
      vaccinationId,
      newStatus,
      completionDate: completionDate,
    );

    try {
      final fs = _firestore;
      if (fs != null) {
        final doc = await fs.collection('dogs').doc(dogId).get();
        if (doc.exists && doc.data() != null) {
          final dog = Dog.fromMap(doc.data()!, docId: doc.id);
          final updatedVac = dog.vaccinations.map((v) {
            if (v.id == vaccinationId) {
              return v.copyWith(
                status: newStatus,
                completionDate: completionDate ?? v.completionDate,
              );
            }
            return v;
          }).toList();

          await fs.collection('dogs').doc(dogId).update({
            'vaccinations': updatedVac.map((v) => v.toMap()).toList(),
          });
        }
      }
    } catch (_) {}
  }

  String? _getCurrentUserId() {
    try {
      return _firebaseAuth?.currentUser?.uid;
    } catch (_) {}
    return null;
  }

  Future<void> _saveToHive(Dog dog) async {
    try {
      if (Hive.isBoxOpen(HiveBoxes.dogsBox)) {
        final hiveDog = model.Dog.fromEntity(dog);
        await HiveBoxes.dogs.put(hiveDog.id, hiveDog);
      }
    } catch (_) {}
  }
}

