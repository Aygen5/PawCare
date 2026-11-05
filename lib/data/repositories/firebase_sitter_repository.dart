import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/sitter.dart';
import '../../domain/repositories/sitter_repository_interface.dart';
import 'sitter_repository.dart';

/// Cloud Firestore ve yerel JSON yedekli Bakıcı Deposu.
class FirebaseSitterRepository implements SitterRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final SitterRepository _fallbackRepo;
  List<SitterListing>? _cachedSitters;

  FirebaseSitterRepository({
    FirebaseFirestore? firestore,
    SitterRepository? fallbackRepo,
  }) : _firestoreInstance = firestore,
       _fallbackRepo = fallbackRepo ?? SitterRepository();

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  @override
  Future<List<SitterListing>> getSitters({bool forceRefresh = false}) async {
    if (_cachedSitters != null && !forceRefresh) {
      return _cachedSitters!;
    }

    try {
      final fs = _firestore;
      if (fs != null) {
        final snapshot = await fs.collection('sitters').get();
        if (snapshot.docs.isNotEmpty) {
          _cachedSitters = snapshot.docs.map((doc) {
            return SitterListing.fromMap(doc.data(), docId: doc.id);
          }).toList();
          return _cachedSitters!;
        }
      }
    } catch (_) {}

    // Firestore boşsa veya çevrimdışıysa yerel JSON deposu kullanılır
    _cachedSitters = await _fallbackRepo.getSitters(forceRefresh: forceRefresh);
    return _cachedSitters!;
  }

  @override
  Future<List<SitterListing>> searchSitters({
    String category = 'Tümü',
    String query = '',
  }) async {
    final all = await getSitters();
    return all.where((s) {
      final matchesCategory = category == 'Tümü' || s.category == category;
      final cleanQuery = query.trim().toLowerCase();
      final matchesSearch = cleanQuery.isEmpty ||
          s.name.toLowerCase().contains(cleanQuery) ||
          s.facilityTitle.toLowerCase().contains(cleanQuery) ||
          s.location.toLowerCase().contains(cleanQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Future<SitterListing?> getSitterById(String id) async {
    try {
      final fs = _firestore;
      if (fs != null) {
        final doc = await fs.collection('sitters').doc(id).get();
        if (doc.exists && doc.data() != null) {
          return SitterListing.fromMap(doc.data()!, docId: doc.id);
        }
      }
    } catch (_) {}

    final all = await getSitters();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Yeni bakıcı ilanı ekler veya günceller.
  Future<void> saveSitter(SitterListing sitter) async {
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('sitters').doc(sitter.id).set(sitter.toMap());
      }
    } catch (_) {}

    if (_cachedSitters != null) {
      final idx = _cachedSitters!.indexWhere((s) => s.id == sitter.id);
      if (idx >= 0) {
        _cachedSitters![idx] = sitter;
      } else {
        _cachedSitters!.add(sitter);
      }
    }
  }
}

