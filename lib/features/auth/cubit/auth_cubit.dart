import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/repositories/in_memory_auth_repository.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/repositories/auth_repository_interface.dart';
import '../../../domain/repositories/settings_repository_interface.dart';

/// Kimlik doğrulama durumunu temsil eden model.
class AuthState {
  final bool isAuthenticated;
  final String? userEmail;
  final String? userName;
  final UserRole role;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.userEmail,
    this.userName,
    this.role = UserRole.owner,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? userName,
    UserRole? role,
    UserEntity? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Giriş, kayıt ve oturum durumunu yöneten Cubit.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryInterface _authRepository;
  final SettingsRepositoryInterface? settingsRepository;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthCubit({
    AuthRepositoryInterface? authRepository,
    this.settingsRepository,
  }) : _authRepository = authRepository ?? createDefaultRepository(),
       super(const AuthState()) {
    _initAuthListener();
  }

  /// Ortamda Firebase initialize edilmişse FirebaseAuthRepository, yoksa InMemory fallback döner.
  static AuthRepositoryInterface createDefaultRepository() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuthRepository();
      }
    } catch (_) {}
    return InMemoryAuthRepository();
  }

  void _initAuthListener() {
    try {
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(
          state.copyWith(
            isAuthenticated: true,
            userEmail: current.email,
            userName: current.displayName,
            role: current.role,
            user: current,
          ),
        );
      }

      _authSubscription = _authRepository.authStateChanges.listen((user) {
        if (user != null) {
          emit(
            state.copyWith(
              isAuthenticated: true,
              userEmail: user.email,
              userName: user.displayName,
              role: user.role,
              user: user,
            ),
          );
        } else {
          emit(const AuthState(isAuthenticated: false));
        }
      });
    } catch (_) {}
  }

  /// E-posta ve şifre ile giriş yapar.
  Future<bool> login({required String email, required String password}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.trim().isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lütfen tüm alanları doldurunuz.',
        ),
      );
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lütfen geçerli bir e-posta adresi giriniz.',
        ),
      );
      return false;
    }

    if (password.length < 6) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Şifre en az 6 karakter olmalıdır.',
        ),
      );
      return false;
    }

    try {
      final user = await _authRepository.signInWithEmail(
        email: trimmedEmail,
        password: password,
      );

      await settingsRepository?.setUserRole(
        user.role == UserRole.sitter ? 'sitter' : 'owner',
      );

      emit(
        AuthState(
          isAuthenticated: true,
          userEmail: user.email,
          userName: user.displayName,
          role: user.role,
          user: user,
          isLoading: false,
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isLoading: false, errorMessage: msg));
      return false;
    }
  }

  /// Yeni kullanıcı hesabı kaydeder.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty || password.trim().isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lütfen tüm alanları doldurunuz.',
        ),
      );
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Lütfen geçerli bir e-posta adresi giriniz.',
        ),
      );
      return false;
    }

    if (password.length < 6) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Şifre en az 6 karakter olmalıdır.',
        ),
      );
      return false;
    }

    try {
      final user = await _authRepository.signUpWithEmail(
        email: trimmedEmail,
        password: password,
        fullName: trimmedName,
        role: role,
      );

      await settingsRepository?.setUserRole(
        role == UserRole.sitter ? 'sitter' : 'owner',
      );

      emit(
        AuthState(
          isAuthenticated: true,
          userEmail: user.email,
          userName: user.displayName,
          role: user.role,
          user: user,
          isLoading: false,
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isLoading: false, errorMessage: msg));
      return false;
    }
  }

  /// Şifre sıfırlama e-postası gönderir.
  Future<bool> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(state.copyWith(errorMessage: 'Lütfen e-posta adresinizi giriniz.'));
      return false;
    }

    try {
      await _authRepository.sendPasswordResetEmail(trimmedEmail);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(errorMessage: msg));
      return false;
    }
  }

  /// Oturumu sonlandırır.
  Future<void> logout() async {
    try {
      await _authRepository.signOut();
    } catch (_) {}
    emit(const AuthState(isAuthenticated: false));
  }

  /// Apple Guideline 5.1.1: Kullanıcı hesabını ve tüm ilişkili verilerini kalıcı olarak siler.
  Future<bool> deleteAccount() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _authRepository.deleteAccount();
      emit(const AuthState(isAuthenticated: false));
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isLoading: false, errorMessage: msg));
      return false;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
