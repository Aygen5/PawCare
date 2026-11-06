import '../entities/user_entity.dart';
import '../entities/user_role.dart';

/// Firebase veya mock kimlik doğrulama işlemlerini soyutlayan arayüz.
abstract class AuthRepositoryInterface {
  /// Oturum durumu değişikliklerini anlık yayan akış.
  Stream<UserEntity?> get authStateChanges;

  /// Mevcut oturum açmış kullanıcı (varsa).
  UserEntity? get currentUser;

  /// E-posta ve şifre ile giriş yapar.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Yeni kullanıcı kaydı oluşturur, kullanıcı adını atar ve Firestore üzerinde profil başlatır.
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  /// Şifre sıfırlama bağlantısı gönderir.
  Future<void> sendPasswordResetEmail(String email);

  /// Oturumu sonlandırır.
  Future<void> signOut();

  /// Apple Guideline 5.1.1 uyumluluğu için kullanıcı hesabını ve tüm verilerini siler.
  Future<void> deleteAccount();
}

