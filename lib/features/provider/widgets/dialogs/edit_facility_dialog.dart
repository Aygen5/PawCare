import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../cubit/provider_cubit.dart';

class EditFacilityDialog extends StatefulWidget {
  final String initialTitle;
  final String initialBio;
  final String initialLocation;

  const EditFacilityDialog({
    super.key,
    required this.initialTitle,
    required this.initialBio,
    required this.initialLocation,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialTitle,
    required String initialBio,
    required String initialLocation,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: EditFacilityDialog(
          initialTitle: initialTitle,
          initialBio: initialBio,
          initialLocation: initialLocation,
        ),
      ),
    );
  }

  @override
  State<EditFacilityDialog> createState() => _EditFacilityDialogState();
}

class _EditFacilityDialogState extends State<EditFacilityDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _bioCtrl = TextEditingController(text: widget.initialBio);
    _locCtrl = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Tesis Bilgisini Düzenle',
        style: AppTypography.titleCard.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tesis Adı', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                hintText: 'Tesis adını girin',
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Konum', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _locCtrl,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                hintText: 'Örn: Kadıköy, İstanbul',
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Tesis Tanıtımı & Bio', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                hintText: 'Tesis olanakları ve vizyonunuzu anlatın',
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'İptal',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ProviderCubit>().updateFacilityInfo(
              title: _titleCtrl.text.trim(),
              bio: _bioCtrl.text.trim(),
              location: _locCtrl.text.trim(),
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Tesis bilgileri başarıyla güncellendi!'),
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor:
                isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

