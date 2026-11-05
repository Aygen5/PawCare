import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../domain/entities/sitter.dart';
import '../cubit/provider_cubit.dart';
import '../cubit/provider_state.dart';
import '../widgets/dialogs/add_amenity_dialog.dart';
import '../widgets/dialogs/add_service_dialog.dart';
import '../widgets/dialogs/edit_facility_dialog.dart';
import '../widgets/dialogs/edit_service_dialog.dart';

/// Bakıcı — İlanım & Fiyatlarım Sekmesi
class SitterListingTab extends StatelessWidget {
  const SitterListingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProviderCubit, ProviderState>(
      builder: (context, state) {
        final cubit = context.read<ProviderCubit>();

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Başlık ve Rozetler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İlanım & Fiyatlarım',
                              style: AppTypography.headlineScreen,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.facilityTitle} • ${state.facilityLocation}',
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PawHeaderActions(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Yayın Durumu Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'İlanınız Aktif • Rezervasyon Talepleri Açık',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkOnPrimaryContainer
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tesis Tanıtım Kartı & Düzenleme
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundImage:
                                  AssetImage('assets/images/ayse.jpg'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ayşe Yılmaz',
                                    style: AppTypography.titleCard,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Doğrulanmış Profesyonel Bakıcı 🐾',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9A825)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Color(0xFFF9A825),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.9',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tesis Bilgileri',
                              style: AppTypography.titleCard.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                EditFacilityDialog.show(
                                  context,
                                  initialTitle: state.facilityTitle,
                                  initialBio: state.facilityBio,
                                  initialLocation: state.facilityLocation,
                                );
                              },
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Düzenle'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.facilityBio,
                          style: AppTypography.bodyDefault,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.facilityLocation,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hizmetler & Fiyat Tarifesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hizmet & Fiyat Listesi',
                        style: AppTypography.headlineSection,
                      ),
                      TextButton.icon(
                        onPressed: () => AddServiceDialog.show(context),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Hizmet Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...state.services.map(
                    (srv) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPriceCard(
                        service: srv,
                        isDark: isDark,
                        canDelete: state.services.length > 1,
                        onEdit: () => EditServiceDialog.show(context, srv),
                        onDelete: () => cubit.removeService(srv.id),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tesis Olanakları & Özellikler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tesis Özellikleri & Olanaklar',
                        style: AppTypography.headlineSection,
                      ),
                      TextButton.icon(
                        onPressed: () => AddAmenityDialog.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.amenities
                        .map(
                          (amenity) => _buildAmenityChip(
                            amenity,
                            isDark,
                            onRemove: () => cubit.removeAmenity(amenity),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceCard({
    required SitterServiceItem service,
    required bool isDark,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool canDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.title, style: AppTypography.titleCard),
                const SizedBox(height: 2),
                Text(service.description, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${service.price}',
                style: AppTypography.titleCard.copyWith(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                service.unit,
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.surfaceContainerLowest,
            onSelected: (val) {
              if (val == 'edit') {
                onEdit();
              } else if (val == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Fiyatı / Hizmeti Düzenle'),
                  ],
                ),
              ),
              if (canDelete)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hizmeti Kaldır',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(
    String label,
    bool isDark, {
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
