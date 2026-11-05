import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_storage_service.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../domain/entities/dog.dart';
import '../../../domain/entities/vaccination.dart';
import '../../discovery/widgets/call_modal.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';
import '../widgets/health_card_modal.dart';

/// Köpek Profili & Sağlık Ekranı — Clean Architecture ve PetsCubit ile beslenir.
class DogProfileScreen extends StatelessWidget {
  final PetsCubit? cubit;

  const DogProfileScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: const _DogProfileView());
    }
    return BlocProvider(
      create: (_) => PetsCubit()..loadPetProfile(),
      child: const _DogProfileView(),
    );
  }
}

class _DogProfileView extends StatelessWidget {
  const _DogProfileView();

  Widget _buildPetImage(String path, {double size = 140}) {
    if (ImageStorageService.isNetworkUrl(path) || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.pets, color: AppColors.primary),
        ),
      );
    }
    if (ImageStorageService.isAssetPath(path)) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.pets, color: AppColors.primary),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: AppColors.surfaceContainerLow,
        child: const Icon(Icons.pets, color: AppColors.primary),
      ),
    );
  }

  Future<void> _handlePhotoPick(BuildContext context) async {
    final cubit = context.read<PetsCubit>();

    final savedPath = await cubit.pickAndSavePetPhoto();
    if (savedPath != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil fotoğrafı başarıyla güncellendi ve kaydedildi! 🐾',
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetsCubit, PetsState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dog = state.dog ?? PetsCubit.fallbackDog;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Başlık ve Sağ İkonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Köpek Profili & Sağlık',
                          style: AppTypography.headlineScreen,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.qr_code,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${dog.name} Mikroçip Dijital Kimlik Kodu: ${dog.microchip}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkOutlineVariant.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.outlineVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
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
                  const SizedBox(height: 16),

                  // 2 veya daha fazla köpek varsa Köpek Seçici (Pati Değiştirici)
                  if (state.dogs.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.dogs.map((d) {
                          final isSelected = d.id == dog.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: CircleAvatar(
                                radius: 12,
                                backgroundImage: AssetImage(d.photoPath),
                                onBackgroundImageError: (_, _) {},
                                child: const Icon(Icons.pets, size: 12),
                              ),
                              label: Text(d.name),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.surfaceContainerLowest,
                              labelStyle: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkOnSurface
                                          : AppColors.onSurface),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                context.read<PetsCubit>().selectDog(d);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Büyük Profil Fotoğrafı ve Fotoğraf Seçim Butonu
                  Center(
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: () => _handlePhotoPick(context),
                          borderRadius: BorderRadius.circular(70),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: AppColors.cardShadow,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildPetImage(dog.photoPath, size: 140),
                                  if (state.isPhotoUpdating)
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _handlePhotoPick(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(dog.name, style: AppTypography.headlineHero),
                        const SizedBox(height: 2),
                        Text(
                          '${dog.breed} • Mikroçip: ${dog.microchip}',
                          style: AppTypography.bodyDefault,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Yaş, Ağırlık ve Cinsiyet İstatistik Kartları
                  Row(
                    children: [
                      _buildStatCard('Yaş', '${dog.ageYears} Yaş'),
                      const SizedBox(width: 10),
                      _buildStatCard('Ağırlık', '${dog.weightKg} kg'),
                      const SizedBox(width: 10),
                      _buildStatCard('Cinsiyet', dog.gender),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Profil Eylem Butonları
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showEditProfileDialog(context, dog);
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                          label: Text(
                            'Profili Düzenle',
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
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDogDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Yeni Köpek Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Kritik Sağlık & Alerji Uyarısı Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2E1A1A)
                          : const Color(0xFFFFF2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkError.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkError.withValues(alpha: 0.2)
                                : AppColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: isDark ? AppColors.darkError : AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kritik Sağlık & Alerji Uyarısı',
                                style: AppTypography.titleCard.copyWith(
                                  color: isDark
                                      ? AppColors.darkError
                                      : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dog.allergyNote,
                                style: AppTypography.bodyDefault.copyWith(
                                  color: isDark
                                      ? const Color(0xFFFFDAD6)
                                      : const Color(0xFF701A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Aşı Takvimi Başlığı ve Sağlık Özeti Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Aşı Takvimi & Kayıtlar',
                          style: AppTypography.headlineSection,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => HealthCardModal.show(context),
                        icon: Icon(
                          Icons.medical_information_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        label: Text(
                          'Özeti Gör',
                          style: AppTypography.labelTag.copyWith(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Aşı Listesi (Durum Değiştirme Destekli)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dog.vaccinations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final v = dog.vaccinations[index];
                      final isDone = v.status == VaccineStatus.completed;
                      return InkWell(
                        onTap: () {
                          context.read<PetsCubit>().toggleVaccinationStatus(
                            v.id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${v.title} durumu güncellendi: ${!isDone ? "Tamamlandı" : "Yaklaşıyor"}',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainerLowest,
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
                                isDone ? Icons.check_circle : Icons.event,
                                color: isDone
                                    ? AppColors.success
                                    : (isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary),
                                size: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.title,
                                      style: AppTypography.titleCard.copyWith(
                                        color: isDark
                                            ? AppColors.darkOnSurface
                                            : const Color(0xFF1E3023),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${v.dueDate} • ${v.vetName}',
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
                                  horizontal: 10,
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDone ? 'Tamamlandı' : 'Yaklaşıyor',
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
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Beslenme & Davranış Özellikleri (Düzenlenebilir ve temaya duyarlı)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Beslenme & Davranış Özellikleri',
                          style: AppTypography.headlineSection,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        tooltip: 'Beslenme ve Davranışı Düzenle',
                        onPressed: () => _showEditBehaviorDialog(context, dog),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.3,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Beslenme & Alerji Notu',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dog.allergyNote.isNotEmpty ? dog.allergyNote : 'Günde 2 öğün 280g kuzu etli kuru mama (sabah 08:30 / akşam 19:00). Bol taze su.',
                          style: AppTypography.bodyDefault,
                        ),
                        const Divider(
                          height: 20,
                          color: AppColors.outlineVariant,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sosyal Davranış & Karakter',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dog.behaviorNote.isNotEmpty ? dog.behaviorNote : 'İnsanlara ve diğer köpeklere karşı son derece dost canlısı ve oyuncu.',
                          style: AppTypography.bodyDefault,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sorumlu Veteriner Kliniği Kartı
                  Text(
                    'Sorumlu Veteriner Kliniği',
                    style: AppTypography.headlineSection,
                  ),
                  const SizedBox(height: 10),
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
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.3,
                              )
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
                            Icons.local_hospital,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.clinicName,
                                style: AppTypography.titleCard,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dr. Selin Bulut • Başhekim',
                                style: AppTypography.caption,
                              ),
                              Text(
                                dog.clinicPhone,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => CallModal.show(
                            context,
                            contactName: '${dog.clinicName} (Dr. Selin Bulut)',
                            roleSubtitle:
                                'Veteriner Kliniği Acil & Randevu Hattı',
                            phoneNumber: dog.clinicPhone,
                          ),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Hemen Ara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, Dog dog) {
    final nameController = TextEditingController(text: dog.name);
    final breedController = TextEditingController(text: dog.breed);
    final ageController = TextEditingController(text: dog.ageYears.toString());
    final weightController = TextEditingController(
      text: dog.weightKg.toString(),
    );
    final allergyController = TextEditingController(text: dog.allergyNote);
    String selectedGender = dog.gender;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            '${dog.name} Profilini Düzenle',
            style: AppTypography.titleCard.copyWith(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(labelText: 'Köpek Adı'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(labelText: 'Türü / Irkı'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        decoration: const InputDecoration(
                          labelText: 'Yaş (yıl)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        decoration: const InputDecoration(
                          labelText: 'Ağırlık (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Cinsiyet',
                  style: AppTypography.labelTag.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ['Erkek', 'Dişi'].map((g) {
                    final isSel = selectedGender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: isSel
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) =>
                            setDialogState(() => selectedGender = g),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergyController,
                  maxLines: 2,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Alerji / Özel Not',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newAge = int.tryParse(ageController.text) ?? dog.ageYears;
                final newWeight =
                    double.tryParse(weightController.text) ?? dog.weightKg;
                final updated = dog.copyWith(
                  name: nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : dog.name,
                  breed: breedController.text.trim().isNotEmpty
                      ? breedController.text.trim()
                      : dog.breed,
                  ageYears: newAge,
                  weightKg: newWeight,
                  gender: selectedGender,
                  allergyNote: allergyController.text.trim(),
                );
                context.read<PetsCubit>().updateDogProfile(updated);
                Navigator.of(ctx).pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDogDialog(BuildContext context) {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController(text: '1');
    final weightController = TextEditingController(text: '12.0');
    final microchipController = TextEditingController(
      text:
          '9002150029${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    final allergyController = TextEditingController();
    final clinicController = TextEditingController(
      text: 'Kadıköy Veteriner Polikliniği',
    );
    String selectedGender = 'Dişi';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.pets, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Yeni Köpek Ekle',
                style: AppTypography.titleCard.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Köpek Adı *',
                    hintText: 'Örn. Luna, Karabaş, Max',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Irk / Tür *',
                    hintText: 'Örn. Labrador, Pug, Golden Retriever',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        decoration: const InputDecoration(
                          labelText: 'Yaş (yıl)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        decoration: const InputDecoration(
                          labelText: 'Ağırlık (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Cinsiyet',
                  style: AppTypography.labelTag.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ['Dişi', 'Erkek'].map((g) {
                    final isSel = selectedGender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: isSel
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) =>
                            setDialogState(() => selectedGender = g),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: microchipController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Mikroçip Numarası',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allergyController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Alerji / Özel Not',
                    hintText: 'Örn. Tavuk alerjisi, hassas mide...',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: clinicController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  decoration: const InputDecoration(
                    labelText: 'Veteriner Kliniği',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen köpeğin adını giriniz.'),
                    ),
                  );
                  return;
                }
                final breed = breedController.text.trim().isNotEmpty
                    ? breedController.text.trim()
                    : 'Melez';
                final age = int.tryParse(ageController.text) ?? 1;
                final weight = double.tryParse(weightController.text) ?? 12.0;
                final microchip = microchipController.text.trim().isNotEmpty
                    ? microchipController.text.trim()
                    : '9002150029${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                final allergy = allergyController.text.trim().isNotEmpty
                    ? allergyController.text.trim()
                    : 'Bilinen bir alerjisi bulunmuyor.';
                final clinic = clinicController.text.trim().isNotEmpty
                    ? clinicController.text.trim()
                    : 'Kadıköy Veteriner Polikliniği';

                final newDog = Dog(
                  id: 'dog_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  breed: breed,
                  ageYears: age,
                  weightKg: weight,
                  gender: selectedGender,
                  microchip: microchip,
                  photoPath: 'assets/images/barley.jpg',
                  allergyNote: allergy,
                  behaviorNote: 'İnsanlara ve diğer köpeklere karşı son derece dost canlısı.',
                  clinicName: clinic,
                  clinicPhone: '+90 216 345 67 89',
                  vaccinations: [
                    Vaccination(
                      id: 'v_${DateTime.now().millisecondsSinceEpoch}_1',
                      title: 'Karma Aşı (DHPPi+L)',
                      dueDate: '15 Kasım 2026',
                      status: VaccineStatus.upcoming,
                      vetName: 'Dr. Selin Bulut',
                    ),
                    Vaccination(
                      id: 'v_${DateTime.now().millisecondsSinceEpoch}_2',
                      title: 'Kuduz Aşısı (Rabies)',
                      dueDate: '20 Aralık 2026',
                      status: VaccineStatus.upcoming,
                      vetName: 'Dr. Selin Bulut',
                    ),
                  ],
                );

                context.read<PetsCubit>().saveNewDog(newDog);

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${newDog.name} başarıyla eklendi ve seçildi! 🎉',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Köpeği Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBehaviorDialog(BuildContext context, Dog dog) {
    final allergyController = TextEditingController(text: dog.allergyNote);
    final behaviorController = TextEditingController(text: dog.behaviorNote);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Beslenme & Davranışı Düzenle',
              style: AppTypography.titleCard.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Günlük Beslenme & Alerji Notu',
                style: AppTypography.labelTag.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: allergyController,
                maxLines: 3,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                decoration: const InputDecoration(
                  hintText: 'Mama türü, gramaj, öğün saatleri veya alerji uyarıları...',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sosyal Davranış & Karakter',
                style: AppTypography.labelTag.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: behaviorController,
                maxLines: 3,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                decoration: const InputDecoration(
                  hintText: 'Diğer köpeklerle uyum, enerji seviyesi, korkular, sevdiği oyunlar...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = dog.copyWith(
                allergyNote: allergyController.text.trim(),
                behaviorNote: behaviorController.text.trim(),
              );
              context.read<PetsCubit>().updateDogProfile(updated);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Beslenme ve davranış özellikleri güncellendi! 🐾',
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.titleCard.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
