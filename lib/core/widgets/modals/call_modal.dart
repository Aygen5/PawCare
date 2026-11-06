import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/phone_call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Bakıcı veya müşteri ile arama başlatma onay modalı.
class CallModal extends StatelessWidget {
  final String contactName;
  final String roleSubtitle;
  final String phoneNumber;

  const CallModal({
    super.key,
    required this.contactName,
    required this.roleSubtitle,
    required this.phoneNumber,
  });

  static Future<void> show(
    BuildContext context, {
    required String contactName,
    required String roleSubtitle,
    required String phoneNumber,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => CallModal(
        contactName: contactName,
        roleSubtitle: roleSubtitle,
        phoneNumber: phoneNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final outlineColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final iconCircleBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.secondaryContainer;
    final iconColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtextColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final phoneBoxBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLow;
    final phoneTextColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.floatingShadow,
            border: Border.all(
              color: outlineColor,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Telefon Araması',
                style: AppTypography.headlineSection.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contactName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                roleSubtitle,
                style: AppTypography.caption.copyWith(
                  color: subtextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: phoneBoxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: outlineColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  phoneNumber,
                  style: AppTypography.titleCard.copyWith(
                    color: phoneTextColor,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Demo ortamında arama başlatılacaktır. Gerçek arama için mobil cihaz izinleri gereklidir.',
                style: AppTypography.caption.copyWith(
                  color: subtextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Vazgeç',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final launched =
                            await PhoneCallService.makeCall(phoneNumber);
                        if (!launched && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Arama başlatılamadı. Cihazınızda telefon uygulaması bulunamadı ($phoneNumber).',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.darkPrimary : AppColors.primary,
                        foregroundColor: isDark
                            ? AppColors.darkOnPrimary
                            : AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Ara',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnPrimary
                              : AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
