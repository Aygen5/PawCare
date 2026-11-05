import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository_interface.dart';

/// Firebase Authentication ve Cloud Firestore kullanıcı verilerini bağlayan somut repository.
class FirebaseAuthRepository implements AuthRepositoryInterface {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToEntity(firebaseUser);
    });
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
    );
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Kullanıcı bilgisi alınamadı.');
      }

      return await _mapFirebaseUserToEntity(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Giriş yapılırken beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Kayıt oluşturulamadı.');
      }

      // Kullanıcının profil adını güncelle
      await user.updateDisplayName(fullName.trim());

      final userEntity = UserEntity(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      // Firestore üzerinde kullanıcı profil dokümanı oluştur
      try {
        await _firestore.collection('users').doc(user.uid).set(userEntity.toMap());
      } catch (_) {
        // Firestore erişimi engelli olsa dahi Auth başarısını engelleme
      }

      return userEntity;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Kayıt olunurken beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Şifre sıfırlama talebi gönderilemedi: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Firebase User nesnesini Firestore'dan rol ve ek bilgileri çekerek UserEntity'ye dönüştürür.
  Future<UserEntity> _mapFirebaseUserToEntity(User firebaseUser) async {
    UserRole role = UserRole.owner;
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final roleStr = doc.data()!['role'] as String?;
        if (roleStr == 'sitter') {
          role = UserRole.sitter;
        }
      }
    } catch (_) {
      // Hata veya offline durumunda varsayılan owner
    }

    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      role: role,
    );
  }

  /// Firebase Auth hata kodlarını kullanıcı dostu Türkçe mesajlara dönüştürür.
  String _mapAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı bir hesap bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Girdiğiniz şifre veya e-posta hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      case 'invalid-email':
        return 'Lütfen geçerli bir e-posta adresi giriniz.';
      case 'weak-password':
        return 'Şifreniz çok zayıf. Lütfen en az 6 karakter giriniz.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmıştır.';
      case 'operation-not-allowed':
        return 'Firebase Console üzerinde E-posta/Şifre ile giriş sağlayıcısı etkinleştirilmemiş.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol ediniz.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yapıldı. Lütfen biraz bekleyiniz.';
      default:
        return 'Kimlik doğrulama hatası ($code). Lütfen tekrar deneyiniz.';
    }
  }
}

