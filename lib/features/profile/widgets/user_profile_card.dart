import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/dog.dart';
import '../../../domain/entities/user_role.dart';
import '../../auth/cubit/role_cubit.dart';
import '../../pets/cubit/pets_cubit.dart';
import '../cubit/profile_cubit.dart';

/// Kullanıcı profil bilgilerini, aktif rolünü ve kayıtlı evcil hayvanını gösteren kart.
class UserProfileCard extends StatelessWidget {
  final VoidCallback? onDogProfileTap;

  const UserProfileCard({super.key, this.onDogProfileTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileCubit = context.watch<ProfileCubit?>();
    final roleCubit = context.watch<RoleCubit?>();

    final activeRole =
        roleCubit?.state ?? profileCubit?.state.role ?? UserRole.owner;
    final isOwner = activeRole == UserRole.owner;
    final isSitter = activeRole == UserRole.sitter;

    final userName = isSitter
        ? 'Ayşe Yılmaz'
        : (profileCubit?.state.userName == 'Ayşe Yılmaz'
              ? 'Aygen Yıldırım'
              : (profileCubit?.state.userName ?? 'Aygen Yıldırım'));
    final userEmail = isSitter
        ? 'ayse@pawcare.com'
        : (profileCubit?.state.userEmail == 'ayse@pawcare.com'
              ? 'aygen@pawcare.com'
              : (profileCubit?.state.userEmail ?? 'aygen@pawcare.com'));
    final userPhone = isSitter
        ? '+90 533 987 65 43'
        : (profileCubit?.state.userPhone ?? '+90 532 123 45 67');

    final Dog dog = profileCubit?.state.dog ?? PetsCubit.fallbackDog;

    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? AppColors.darkCardShadow : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: Profil Fotoğrafı + İsim/E-posta + Düzenle İkonu
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSecondaryContainer
                      : AppColors.secondaryContainer,
                  border: Border.all(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: AppTypography.headlineScreen.copyWith(
                      color: isDark
                          ? AppColors.darkOnSecondaryContainer
                          : AppColors.primary,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: AppTypography.headlineSection.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              _showEditDialog(context, userName, userPhone),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Aktif Rol Rozeti ve Hızlı Rol Değiştirme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? (isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.primary.withValues(alpha: 0.1))
                          : (isDark
                                ? AppColors.darkSecondaryContainer
                                : AppColors.secondaryContainer),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOwner ? Icons.pets : Icons.badge_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOwner ? 'Köpek Sahibi' : 'Hizmet Veren (Bakıcı)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // Rolü tersine çevir
                  final newRole = isOwner ? UserRole.sitter : UserRole.owner;
                  roleCubit?.setRole(newRole);
                  profileCubit?.toggleRole();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rolü Değiştir',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Köpek Sahibi İse Kayıtlı Evcil Hayvan Özeti
          if (isOwner) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.secondaryContainer,
                      child: dog.photoPath.isNotEmpty
                          ? Image.asset(
                              dog.photoPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.pets,
                                    color: AppColors.primary,
                                  ),
                            )
                          : const Icon(Icons.pets, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dog.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${dog.breed} • ${dog.ageYears} Yaşında (${dog.weightKg.toInt()} kg)',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDogProfileTap != null)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant,
                      ),
                      onPressed: onDogProfileTap,
                      tooltip: 'Köpek Profiline Git',
                    ),
                ],
              ),
            ),
          ] else ...[
            // Hizmet Veren İse İşletme / Tesis Özeti
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.secondaryContainer,
                      child: Image.asset(
                        'assets/images/ayse.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.storefront,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mutlu Patiler Butik Köpek Oteli',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Caddebostan, Kadıköy • 4.9 ⭐ (128 Yorum)',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String currentName,
    String currentPhone,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Profil Bilgilerini Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                context.read<ProfileCubit?>()?.updateUserInfo(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
