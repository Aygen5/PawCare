import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/repositories/firebase_walk_repository.dart';
import '../../../features/tracking/cubit/tracking_cubit.dart';
import '../../../features/tracking/cubit/tracking_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../paw_map_view.dart';

/// Gerçek zamanlı GPS yürüyüş takibi ve otel konumu modalı.
/// OpenStreetMap ve Firebase Firestore `live_walks` akışını kullanır.
class LiveTrackingModal extends StatelessWidget {
  final bool isHotel;
  final String hotelName;
  final String locationName;
  final String bookingId;
  final String sitterName;
  final String dogName;
  final bool isSitterMode;
  final TrackingCubit? cubit;

  const LiveTrackingModal({
    super.key,
    this.isHotel = false,
    this.hotelName = 'Mutlu Patiler Köpek Oteli',
    this.locationName = 'Caddebostan, Kadıköy',
    this.bookingId = 'demo_booking_caddebostan',
    this.sitterName = 'Mert Yılmaz',
    this.dogName = 'Barley',
    this.isSitterMode = false,
    this.cubit,
  });

  static Future<void> show(
    BuildContext context, {
    bool isHotel = false,
    String hotelName = 'Mutlu Patiler Köpek Oteli',
    String locationName = 'Caddebostan, Kadıköy',
    String bookingId = 'demo_booking_caddebostan',
    String sitterName = 'Mert Yılmaz',
    String dogName = 'Barley',
    bool isSitterMode = false,
    TrackingCubit? cubit,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => LiveTrackingModal(
        isHotel: isHotel,
        hotelName: hotelName,
        locationName: locationName,
        bookingId: bookingId,
        sitterName: sitterName,
        dogName: dogName,
        isSitterMode: isSitterMode,
        cubit: cubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LiveTrackingContent(
          isHotel: isHotel,
          hotelName: hotelName,
          locationName: locationName,
          bookingId: bookingId,
          sitterName: sitterName,
          dogName: dogName,
          isSitterMode: isSitterMode,
        ),
      );
    }

    return BlocProvider(
      create: (context) {
        final trackingCubit = TrackingCubit(
          walkRepository: FirebaseWalkRepository(),
        );

        if (isSitterMode) {
          // Bakıcı modunda varsayılan olarak yürüyüşü başlat (cihazda GPS veya simülasyon)
          trackingCubit.startSitterWalk(
            bookingId: bookingId,
            sitterId: 'sitter_current',
            sitterName: sitterName,
            dogId: 'dog_current',
            dogName: dogName,
            simulate: false,
          );
        } else if (!isHotel) {
          // Köpek sahibi modunda canlı Firestore akışını dinle
          trackingCubit.initOwnerTracking(
            bookingId: bookingId,
            sitterName: sitterName,
            dogName: dogName,
          );
        }

        return trackingCubit;
      },
      child: _LiveTrackingContent(
        isHotel: isHotel,
        hotelName: hotelName,
        locationName: locationName,
        bookingId: bookingId,
        sitterName: sitterName,
        dogName: dogName,
        isSitterMode: isSitterMode,
      ),
    );
  }
}

class _LiveTrackingContent extends StatelessWidget {
  final bool isHotel;
  final String hotelName;
  final String locationName;
  final String bookingId;
  final String sitterName;
  final String dogName;
  final bool isSitterMode;

  const _LiveTrackingContent({
    required this.isHotel,
    required this.hotelName,
    required this.locationName,
    required this.bookingId,
    required this.sitterName,
    required this.dogName,
    required this.isSitterMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final outlineColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final closeBtnBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;
    final closeBtnColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.floatingShadow,
            border: Border.all(color: outlineColor),
          ),
          child: BlocBuilder<TrackingCubit, TrackingState>(
            builder: (context, state) {
              final session = state.session;
              final isLive = !isHotel && (session?.isActive ?? false);
              final activeDuration = session != null
                  ? session.durationFormatted
                  : '00:00';
              final activeDistance = session != null
                  ? session.distanceFormatted
                  : '0 m';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Modal Başlığı ve Kapatma Butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive
                                      ? AppColors.success
                                      : (isHotel
                                          ? AppColors.primary
                                          : AppColors.tertiary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isHotel
                                      ? 'Tesis & Otel Konumu'
                                      : (isLive
                                          ? 'Canlı Yürüyüş Takibi (Aktif)'
                                          : 'Yürüyüş Özeti & Rota'),
                                  style: AppTypography.titleCard.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: closeBtnColor),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: closeBtnBg,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Canlı OpenStreetMap Harita Kutusu (PawMapView)
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            PawMapView(
                              initialCenter: isHotel
                                  ? const LatLng(40.9650, 29.0650)
                                  : state.currentPosition,
                              initialZoom: isHotel ? 16.0 : 16.5,
                              routePoints: isHotel
                                  ? const []
                                  : state.routeCoordinates,
                              currentPosition: isHotel
                                  ? const LatLng(40.9650, 29.0650)
                                  : state.currentPosition,
                              startPoint:
                                  isHotel ? null : session?.startLatLng,
                              walkerName: isHotel ? hotelName : sitterName,
                              petName: isHotel ? null : dogName,
                              avatarAsset: isHotel
                                  ? 'assets/images/ayse.jpg'
                                  : 'assets/images/mert.jpg',
                            ),

                            // Harita sol üst bilgi hapı
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHotel
                                          ? Icons.home_work_outlined
                                          : Icons.park_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isHotel
                                          ? locationName
                                          : 'Caddebostan Sahil Parkı',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Canlı GPS göstergesi
                            if (isLive)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.sensors_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CANLI GPS',
                                        style: AppTypography.labelTag.copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Canlı İstatistikler (Süre & Mesafe)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: outlineColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHotel ? 'Hizmet Türü' : 'Geçen Süre',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHotel ? 'Köpek Oteli' : activeDuration,
                                  style: AppTypography.headlineSection.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: outlineColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHotel ? 'Konum' : 'Yürüyüş Mesafesi',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHotel ? 'Caddebostan' : activeDistance,
                                  style: AppTypography.headlineSection.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Bilgilendirme / Durum Kartı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.secondaryContainer
                                .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: outlineColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLive
                                ? Icons.gps_fixed_rounded
                                : Icons.info_outline,
                            size: 18,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isHotel
                                  ? '$hotelName: Geniş çim bahçe, 7/24 kamera takibi ve veteriner anlaşmalı güvenli konaklama sunar.'
                                  : (isLive
                                      ? '$sitterName ve $dogName sahilde yürüyüşte! Konum GPS ile haritaya anlık yansıtılmaktadır.'
                                      : 'Yürüyüş tamamlandı. Kat edilen toplam mesafe ve rota haritada kaydedildi.'),
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Bakıcı Modu Aksiyon Butonları (Yürüyüşü Başlat / Tamamla)
                    if (isSitterMode) ...[
                      const SizedBox(height: 16),
                      if (isLive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final cubit = context.read<TrackingCubit>();
                              await cubit.endSitterWalk(bookingId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Yürüyüş başarıyla tamamlandı ve rota buluta kaydedildi! 🐾',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Yürüyüşü Tamamla ve Kaydet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.read<TrackingCubit>().startSitterWalk(
                                        bookingId: bookingId,
                                        sitterId: 'sitter_current',
                                        sitterName: sitterName,
                                        dogId: 'dog_current',
                                        dogName: dogName,
                                        simulate: true,
                                      );
                                },
                                icon: const Icon(Icons.play_arrow_outlined),
                                label: const Text('Simüle Başlat'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<TrackingCubit>().startSitterWalk(
                                        bookingId: bookingId,
                                        sitterId: 'sitter_current',
                                        sitterName: sitterName,
                                        dogId: 'dog_current',
                                        dogName: dogName,
                                        simulate: false,
                                      );
                                },
                                icon: const Icon(Icons.my_location),
                                label: const Text('Gerçek GPS ile Başlat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
