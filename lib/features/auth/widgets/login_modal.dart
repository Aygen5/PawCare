import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/role_cubit.dart';
import 'signup_modal.dart';

/// Kullanıcı giriş modalı; Stitch tasarımına uygun cam efekti ve form bileşenlerini barındırır.
class LoginModal extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginModal({super.key, this.onLoginSuccess});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLoginSuccess,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => LoginModal(onLoginSuccess: onLoginSuccess),
    );
  }

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _emailController = TextEditingController(text: 'aygen@pawcare.com');
  final _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen tüm alanları doldurunuz.';
      });
      return;
    }

    final authCubit = context.read<AuthCubit?>();
    if (authCubit != null) {
      final success = await authCubit.login(email: email, password: password);
      if (!success) {
        if (!mounted) return;
        setState(() {
          _errorMessage = authCubit.state.errorMessage ?? 'Giriş yapılamadı.';
        });
        return;
      }
    }

    if (!mounted) return;

    final targetRole = authCubit?.state.role ?? UserRole.owner;
    context.read<RoleCubit?>()?.setRole(targetRole);

    Navigator.of(context).pop();
    widget.onLoginSuccess?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Hoş geldiniz! Giriş başarılı.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesabınıza kayıtlı e-posta adresini giriniz. Şifre sıfırlama bağlantısı gönderilecektir.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta Adresi',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authCubit = context.read<AuthCubit?>();
              if (authCubit != null) {
                final success = await authCubit.sendPasswordResetEmail(
                  resetController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Şifre sıfırlama e-postası gönderildi.'
                            : authCubit.state.errorMessage ?? 'Hata oluştu.',
                      ),
                      backgroundColor:
                          success ? AppColors.primary : AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
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
          constraints: const BoxConstraints(maxWidth: 440),
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
                            'PawCare Demo',
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
                Text('Tekrar Hoş Geldin', style: AppTypography.headlineHero),
                const SizedBox(height: 6),
                Text(
                  'Dostunuz için en iyi bakımı yönetmeye devam edin.',
                  style: AppTypography.bodyDefault,
                ),
                const SizedBox(height: 24),
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
                  obscureText: _obscurePassword,
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.secondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordDialog(context),
                    child: Text(
                      'Şifremi Unuttum',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Giriş Yap',
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
                      SignUpModal.show(
                        context,
                        onSignUpSuccess: widget.onLoginSuccess,
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Hesabınız yok mu? ',
                        style: AppTypography.caption,
                        children: [
                          TextSpan(
                            text: 'Kayıt Olun',
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
