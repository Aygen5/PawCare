import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_storage_service.dart';
import '../../../domain/entities/dog.dart';
import '../../../domain/entities/vaccination.dart';
import '../cubit/pets_cubit.dart';

/// Evcil hayvan sağlık ve aşı takvim kartı modalı.
class HealthCardModal extends StatelessWidget {
  const HealthCardModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => const HealthCardModal(),
    );
  }

  Widget _buildAvatar(String path) {
    if (ImageStorageService.isNetworkUrl(path) || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 44,
        height: 44,
        errorBuilder: (_, _, _) => Container(
          width: 44,
          height: 44,
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
        ),
      );
    }
    if (ImageStorageService.isAssetPath(path)) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: 44,
        height: 44,
        errorBuilder: (_, _, _) => Container(
          width: 44,
          height: 44,
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: 44,
      height: 44,
      errorBuilder: (_, _, _) => Container(
        width: 44,
        height: 44,
        color: AppColors.surfaceContainerLow,
        child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
      ),
    );
  }

  void _showAddVaccineDialog(BuildContext context, Dog dog) {
    final titleController = TextEditingController();
    final dateController = TextEditingController(text: '15 Aralık 2026');
    final vetController = TextEditingController(text: 'Dr. Selin Bulut');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni Aşı Kaydı', style: AppTypography.titleCard),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              decoration: const InputDecoration(
                labelText: 'Aşı / Tedavi Adı',
                hintText: 'Örn. Bronşin Aşısı',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateController,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              decoration: const InputDecoration(
                labelText: 'Randevu / Uygulama Tarihi',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: vetController,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              decoration: const InputDecoration(labelText: 'Veteriner Hekim'),
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
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final newVac = Vaccination(
                  id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  dueDate: dateController.text.trim(),
                  status: VaccineStatus.upcoming,
                  vetName: vetController.text.trim(),
                );

                if (context.mounted) {
                  context.read<PetsCubit?>()?.addVaccination(newVac);
                }
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dog = context.watch<PetsCubit?>()?.state.dog ?? PetsCubit.fallbackDog;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(child: _buildAvatar(dog.photoPath)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dog.name} — Sağlık Kartı',
                                  style: AppTypography.titleCard,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${dog.breed} • ${dog.ageYears} Yaş',
                                  style: AppTypography.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Yaklaşan Aşı Bildirim Kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.accentWarm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yaklaşan Aşı: Karma Aşı (DHPPi+L)',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '26 Ekim 2026 • 3 gün kaldı! Randevu saati: 11:30',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aşı ve Tedavi Kayıtları',
                  style: AppTypography.headlineSection,
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dog.vaccinations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = dog.vaccinations[index];
                    final isDone = v.status == VaccineStatus.completed;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant.withValues(
                                  alpha: 0.3,
                                )
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.schedule,
                            color: isDone
                                ? AppColors.success
                                : (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurface
                                        : const Color(0xFF1E3023),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Tarih: ${v.dueDate} • ${v.vetName}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : const Color(0xFF344638),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? (isDark
                                        ? const Color(0xFF1C3A20)
                                        : AppColors.successContainer)
                                  : (isDark
                                        ? AppColors.darkSurfaceContainerHigh
                                        : AppColors.secondaryContainer),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isDone ? 'Tamamlandı' : 'Beklemede',
                              style: AppTypography.labelTag.copyWith(
                                color: isDone
                                    ? (isDark
                                          ? const Color(0xFF85E38C)
                                          : AppColors.success)
                                    : (isDark
                                          ? AppColors.darkPrimary
                                          : const Color(0xFF1E3023)),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddVaccineDialog(context, dog),
                    icon: Icon(
                      Icons.add,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                    label: Text(
                      'Yeni Aşı / Tedavi Ekle',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
