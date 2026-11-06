import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../data/models/models.dart';
import '../../auth/cubit/role_cubit.dart';
import '../../pets/cubit/pets_cubit.dart';
import '../../pets/widgets/health_card_modal.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../core/widgets/modals/chat_modal.dart';
import '../../../core/widgets/modals/live_tracking_modal.dart';

/// Köpek Sahibi Ana Sayfası — Clean Architecture ve HomeCubit ile beslenir.
class OwnerHomeScreen extends StatelessWidget {
  final Function(SitterListing) onSitterSelected;
  final HomeCubit? cubit;

  const OwnerHomeScreen({
    super.key,
    required this.onSitterSelected,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _OwnerHomeView(onSitterSelected: onSitterSelected),
      );
    }
    return BlocProvider(
      create: (_) => HomeCubit()..loadHomeData(),
      child: _OwnerHomeView(onSitterSelected: onSitterSelected),
    );
  }
}

class _OwnerHomeView extends StatefulWidget {
  final Function(SitterListing) onSitterSelected;

  const _OwnerHomeView({required this.onSitterSelected});

  @override
  State<_OwnerHomeView> createState() => _OwnerHomeViewState();
}

class _OwnerHomeViewState extends State<_OwnerHomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Canlı yürüyüş nabız (pulse) animasyonu başlatılır
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        // Aktif veriler HomeCubit'ten alınır, henüz hazır değilse yedek kullanılır
        final dog = homeState.dog ??
            context.watch<PetsCubit?>()?.state.dog ??
            PetsCubit.fallbackDog;
        final sitters = homeState.featuredSitters;
        final activeBooking = homeState.activeBooking;
        final upcomingVaccine = homeState.upcomingVaccine;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Başlık ve Eylemler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merhaba, Aygen 👋',
                                style: AppTypography.headlineScreen,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bugün ${dog.name} için her şey yolunda!',
                                style: AppTypography.bodyDefault,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Rol Değiştirme Butonu (Hizmet Veren Moduna Geçiş)
                            InkWell(
                              onTap: () {
                                context.read<RoleCubit?>()?.switchToSitter();
                                context.go(RoutePaths.sitterDashboard);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Hizmet Veren',
                                      style: AppTypography.labelTag.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Standart Profil ve Bildirim Başlık Aksiyonları
                            const PawHeaderActions(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Köpek Hızlı Profil Kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppColors.cardShadow,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              dog.photoPath,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 72,
                                height: 72,
                                color: AppColors.surfaceContainerLow,
                                child: const Icon(
                                  Icons.pets,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dog.name,
                                      style: AppTypography.titleCard,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${dog.ageYears} Yaş',
                                        style: AppTypography.labelTag.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dog.breed} • ${dog.weightKg} kg',
                                  style: AppTypography.caption,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          HealthCardModal.show(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurfaceContainerLow
                                              : AppColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkOutlineVariant
                                                    .withValues(alpha: 0.5)
                                                : AppColors.outlineVariant
                                                    .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.medical_services_outlined,
                                              size: 14,
                                              color: isDark
                                                  ? AppColors.darkPrimary
                                                  : AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sağlık Kartı',
                                              style: AppTypography.labelTag
                                                  .copyWith(
                                                    color: isDark
                                                        ? AppColors.darkPrimary
                                                        : AppColors.primary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        context.go(RoutePaths.pets);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurfaceContainerLow
                                              : AppColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkOutlineVariant
                                                    .withValues(alpha: 0.5)
                                                : AppColors.outlineVariant
                                                    .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          'Profili Gör',
                                          style: AppTypography.labelTag
                                              .copyWith(
                                                color: isDark
                                                    ? AppColors.darkPrimary
                                                    : AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Popüler Hizmetler (Yatay kaydırılabilir, üzerine gelince renk değiştiren bilgilendirici çip listesi)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Popüler Hizmetler',
                            style: AppTypography.headlineSection,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(RoutePaths.explore);
                          },
                          child: Text(
                            'Tümünü Gör',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: const [
                          _HoverableServicePill(
                            title: 'Köpek Oteli',
                            icon: Icons.home_work_outlined,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Köpek Gezdirme',
                            icon: Icons.directions_walk,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Gündüz Bakımı',
                            icon: Icons.wb_sunny_outlined,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Evde Bakım',
                            icon: Icons.cottage_outlined,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Veteriner & Aşı',
                            icon: Icons.medical_services_outlined,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Eğitim & Davranış',
                            icon: Icons.sports_kabaddi_outlined,
                          ),
                          SizedBox(width: 8),
                          _HoverableServicePill(
                            title: 'Pati Taksi',
                            icon: Icons.local_taxi_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Yaklaşan Aşı Uyarısı Kartı
                    if (upcomingVaccine != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentWarm),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.vaccines,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${upcomingVaccine.title.split(' ').first} Aşı Zamanı!',
                                        style: AppTypography.titleCard.copyWith(
                                          color: AppColors.tertiary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '3 Gün Kaldı',
                                          style: AppTypography.labelTag
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${upcomingVaccine.dueDate} • ${upcomingVaccine.vetName} randevusu',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => HealthCardModal.show(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Aşı Kartı',
                                style: AppTypography.labelTag.copyWith(
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Günün Rezervasyonu Kartı ve Nabız (Pulse) Animasyonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Günün Rezervasyonu',
                            style: AppTypography.headlineSection,
                          ),
                        ),
                        if (activeBooking != null)
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    activeBooking.status ==
                                        BookingStatus.confirmed
                                    ? AppColors.successContainer
                                    : AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          activeBooking.status ==
                                              BookingStatus.confirmed
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeBooking.status ==
                                            BookingStatus.confirmed
                                        ? 'Yürüyüşte • Canlı'
                                        : 'Onay Bekliyor',
                                    style: AppTypography.labelTag.copyWith(
                                      color:
                                          activeBooking.status ==
                                              BookingStatus.confirmed
                                          ? AppColors.success
                                          : AppColors.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Günün Rezervasyonu Kart Detayı
                    if (activeBooking != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.cardShadow,
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: AssetImage(
                                    activeBooking.sitterPhoto,
                                  ),
                                  onBackgroundImageError: (_, _) {},
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              activeBooking.sitterName,
                                              style: AppTypography.titleCard,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Color(0xFFE5A823),
                                          ),
                                          Text(
                                            ' 5.0',
                                            style: AppTypography.labelTag,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        activeBooking.serviceTitle,
                                        style: AppTypography.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${activeBooking.startDate.hour.toString().padLeft(2, '0')}:${activeBooking.startDate.minute.toString().padLeft(2, '0')} - ${activeBooking.endDate.hour.toString().padLeft(2, '0')}:${activeBooking.endDate.minute.toString().padLeft(2, '0')}',
                                    style: AppTypography.labelTag.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final isHotel = activeBooking.serviceTitle
                                              .toLowerCase()
                                              .contains('otel') ||
                                          activeBooking.sitterName
                                              .toLowerCase()
                                              .contains('ayşe') ||
                                          activeBooking.sitterName
                                              .toLowerCase()
                                              .contains('ayse');

                                      return ElevatedButton.icon(
                                        onPressed: () => LiveTrackingModal.show(
                                          context,
                                          isHotel: isHotel,
                                          hotelName: isHotel ? activeBooking.sitterName : 'Mutlu Patiler Köpek Oteli',
                                          locationName: 'Caddebostan, Kadıköy',
                                          bookingId: activeBooking.id,
                                          sitterName: activeBooking.sitterName,
                                          dogName: activeBooking.petName,
                                        ),
                                        icon: Icon(
                                          isHotel
                                              ? Icons.hotel_outlined
                                              : Icons.navigation_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isHotel
                                              ? 'Otelin Konumu'
                                              : 'Canlı Takip',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.onPrimary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => ChatModal.show(
                                      context,
                                      sitterName: activeBooking.sitterName,
                                      avatarPath: activeBooking.sitterPhoto,
                                    ),
                                    icon: Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                    ),
                                    label: Text(
                                      'Sohbet',
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
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Aktif rezervasyon yoksa gösterilecek zarif bilgilendirme kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_available,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bugün için planlanmış bir rezervasyonunuz yok.',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Öne Çıkan Hizmetler Listesi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Öne Çıkan Hizmetler',
                            style: AppTypography.headlineSection,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(RoutePaths.explore);
                          },
                          child: Text(
                            'Hepsi',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sitters.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final s = sitters[index];
                        return InkWell(
                          onTap: () {
                            widget.onSitterSelected(s);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.cardShadow,
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    s.imagePath,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80,
                                      height: 80,
                                      color: AppColors.surfaceContainerLow,
                                      child: const Icon(
                                        Icons.storefront,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.facilityTitle,
                                              style: AppTypography.titleCard,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s.name} • ${s.location}',
                                        style: AppTypography.caption,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Color(0xFFE5A823),
                                              ),
                                              Text(
                                                ' ${s.rating} (${s.reviewsCount})',
                                                style: AppTypography.labelTag,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₺${s.pricePerUnit.toInt()}/${s.unitLabel}',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color: isDark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Popüler hizmetler için fare üzerine gelindiğinde rengi değişen,
/// ancak tıklanamayan (filtreleme keşfet ekranında yapıldığı için) bilgilendirici çip bileşeni.
class _HoverableServicePill extends StatefulWidget {
  final String title;
  final IconData icon;

  const _HoverableServicePill({required this.title, required this.icon});

  @override
  State<_HoverableServicePill> createState() => _HoverableServicePillState();
}

class _HoverableServicePillState extends State<_HoverableServicePill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final hoverBg = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.primaryFixed;
    final defaultBorder = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.4)
        : AppColors.outlineVariant.withValues(alpha: 0.4);
    final hoverBorder = isDark ? AppColors.darkPrimary : AppColors.primary;
    final iconColor = _isHovered
        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
        : (isDark ? AppColors.darkSecondary : AppColors.secondary);
    final textColor = _isHovered
        ? (isDark ? AppColors.darkOnSurface : AppColors.primary)
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurface);

    return MouseRegion(
      cursor: SystemMouseCursors.basic, // Tıklanamaz normal imleç
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? hoverBg : defaultBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? hoverBorder : defaultBorder,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.primary)
                        .withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              widget.title,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
