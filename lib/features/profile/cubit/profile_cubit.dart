import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/firebase_dog_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/repositories/dog_repository_interface.dart';
import '../../../domain/repositories/settings_repository_interface.dart';
import '../../../domain/usecases/pet/get_dog_profile_use_case.dart';
import '../../../domain/usecases/settings/get_app_settings_use_case.dart';
import '../../../domain/usecases/settings/update_app_settings_use_case.dart';
import 'profile_state.dart';

/// Profil bilgilerini, kayıtlı evcil hayvanı ve tema ayarlarını yöneten Cubit.
class ProfileCubit extends Cubit<ProfileState> {
  final GetDogProfileUseCase _getDogProfileUseCase;
  final GetAppSettingsUseCase _getAppSettingsUseCase;
  final UpdateAppSettingsUseCase _updateAppSettingsUseCase;

  ProfileCubit({
    GetDogProfileUseCase? getDogProfileUseCase,
    GetAppSettingsUseCase? getAppSettingsUseCase,
    UpdateAppSettingsUseCase? updateAppSettingsUseCase,
    DogRepositoryInterface? dogRepository,
    SettingsRepositoryInterface? settingsRepository,
  }) : _getDogProfileUseCase =
           getDogProfileUseCase ??
           GetDogProfileUseCase(dogRepository ?? FirebaseDogRepository()),
       _getAppSettingsUseCase =
           getAppSettingsUseCase ??
           GetAppSettingsUseCase(
             settingsRepository ?? SettingsRepository.inMemory(),
           ),
       _updateAppSettingsUseCase =
           updateAppSettingsUseCase ??
           UpdateAppSettingsUseCase(
             settingsRepository ?? SettingsRepository.inMemory(),
           ),
       super(const ProfileState());

  /// Profil ekranı verilerini Domain usecase'leri üzerinden yükler.
  Future<void> loadProfile({
    String? initialName,
    String? initialEmail,
    UserRole? currentRole,
    ThemeMode? currentThemeMode,
  }) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      // Köpek profilini domain katmanından al
      final dog = await _getDogProfileUseCase.call();

      // Kayıtlı rolü getir
      final savedRoleStr = _getAppSettingsUseCase.getUserRole();
      final effectiveRole =
          currentRole ??
          (savedRoleStr == 'sitter' ? UserRole.sitter : UserRole.owner);

      // Kayıtlı temayı getir
      final savedThemeStr = _getAppSettingsUseCase.getThemeMode();
      final effectiveTheme = currentThemeMode ?? _parseThemeMode(savedThemeStr);

      final isSitter = effectiveRole == UserRole.sitter;
      final defaultName = isSitter ? 'Ayşe Yılmaz' : 'Aygen Yıldırım';
      final defaultEmail = isSitter ? 'ayse@pawcare.com' : 'aygen@pawcare.com';
      final defaultPhone = isSitter ? '+90 533 987 65 43' : '+90 532 123 45 67';

      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          userName: initialName ?? defaultName,
          userEmail: initialEmail ?? defaultEmail,
          userPhone: defaultPhone,
          role: effectiveRole,
          dog: dog,
          themeMode: effectiveTheme,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profil bilgileri yüklenemedi: $e',
        ),
      );
    }
  }

  /// Kullanıcı ad ve iletişim bilgilerini günceller.
  void updateUserInfo({String? name, String? email, String? phone}) {
    emit(
      state.copyWith(
        userName: name ?? state.userName,
        userEmail: email ?? state.userEmail,
        userPhone: phone ?? state.userPhone,
      ),
    );
  }

  /// Tema modunu günceller ve SettingsRepository'e kaydeder.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _updateAppSettingsUseCase.setThemeMode(_themeModeToString(mode));
    emit(state.copyWith(themeMode: mode));
  }

  /// Rolü Köpek Sahibi ve Hizmet Veren arasında değiştirir.
  Future<void> toggleRole() async {
    final newRole = state.role == UserRole.owner
        ? UserRole.sitter
        : UserRole.owner;
    await _updateAppSettingsUseCase.setUserRole(
      newRole == UserRole.sitter ? 'sitter' : 'owner',
    );
    final isSitter = newRole == UserRole.sitter;
    emit(
      state.copyWith(
        role: newRole,
        userName: isSitter ? 'Ayşe Yılmaz' : 'Aygen Yıldırım',
        userEmail: isSitter ? 'ayse@pawcare.com' : 'aygen@pawcare.com',
        userPhone: isSitter ? '+90 533 987 65 43' : '+90 532 123 45 67',
      ),
    );
  }

  /// Belirli bir role geçiş yapar.
  Future<void> setRole(UserRole newRole) async {
    await _updateAppSettingsUseCase.setUserRole(
      newRole == UserRole.sitter ? 'sitter' : 'owner',
    );
    final isSitter = newRole == UserRole.sitter;
    emit(
      state.copyWith(
        role: newRole,
        userName: isSitter ? 'Ayşe Yılmaz' : 'Aygen Yıldırım',
        userEmail: isSitter ? 'ayse@pawcare.com' : 'aygen@pawcare.com',
        userPhone: isSitter ? '+90 533 987 65 43' : '+90 532 123 45 67',
      ),
    );
  }

  /// Bildirim tercihlerini açıp kapatır.
  void toggleNotifications(bool enabled) {
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  static ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
