import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/role_cubit.dart';
import 'login_modal.dart';

/// Yeni kullanıcı kayıt modalı; rol seçimi ve Stitch cam tasarımı bileşenlerini içerir.
class SignUpModal extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;

  const SignUpModal({super.key, this.onSignUpSuccess});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSignUpSuccess,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SignUpModal(onSignUpSuccess: onSignUpSuccess),
    );
  }

  @override
  State<SignUpModal> createState() => _SignUpModalState();
}

class _SignUpModalState extends State<SignUpModal> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.owner;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen tüm alanları doldurunuz.';
      });
      return;
    }

    if (password != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Şifreler birbiriyle eşleşmiyor.';
      });
      return;
    }

    final authCubit = context.read<AuthCubit?>();
    if (authCubit != null) {
      final success = await authCubit.signUp(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
      );
      if (!success) {
        if (!mounted) return;
        setState(() {
          _errorMessage = authCubit.state.errorMessage ?? 'Kayıt yapılamadı.';
        });
        return;
      }
    }

    if (!mounted) return;

    context.read<RoleCubit?>()?.setRole(_selectedRole);

    Navigator.of(context).pop();
    widget.onSignUpSuccess?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PawCare\'e hoş geldiniz! Hesabınız oluşturuldu.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.floatingShadow,
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pets,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Yeni Hesap',
                            style: AppTypography.labelTag.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('PawCare\'e Katıl', style: AppTypography.headlineScreen),
                const SizedBox(height: 6),
                Text(
                  'Köpeğinize en iyi bakımı bulun veya hizmet vermeye başlayın.',
                  style: AppTypography.bodyDefault,
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Kullanım Amacınız', style: AppTypography.titleCard),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.owner),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.owner
                                ? AppColors.secondaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == UserRole.owner
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets,
                                color: _selectedRole == UserRole.owner
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Köpek Sahibi',
                                style: AppTypography.labelTag.copyWith(
                                  color: _selectedRole == UserRole.owner
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.sitter),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.sitter
                                ? AppColors.secondaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == UserRole.sitter
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                color: _selectedRole == UserRole.sitter
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hizmet Veren',
                                style: AppTypography.labelTag.copyWith(
                                  color: _selectedRole == UserRole.sitter
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Ad Soyad', style: AppTypography.titleCard),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Adınız Soyadınız',
                    hintStyle: AppTypography.bodyDefault.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.secondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.secondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('E-Posta Adresi', style: AppTypography.titleCard),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'ornek@pawcare.com',
                    hintStyle: AppTypography.bodyDefault.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.secondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.secondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Şifre', style: AppTypography.titleCard),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodyDefault.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.secondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.secondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Şifre Tekrar', style: AppTypography.titleCard),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodyDefault.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.secondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.secondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Hesap Oluştur',
                      style: AppTypography.titleCard.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      LoginModal.show(
                        context,
                        onLoginSuccess: widget.onSignUpSuccess,
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Zaten hesabınız var mı? ',
                        style: AppTypography.caption,
                        children: [
                          TextSpan(
                            text: 'Giriş Yapın',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
