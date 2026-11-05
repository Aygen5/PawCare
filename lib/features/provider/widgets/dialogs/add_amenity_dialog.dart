import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../cubit/provider_cubit.dart';

class AddAmenityDialog extends StatefulWidget {
  const AddAmenityDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: const AddAmenityDialog(),
      ),
    );
  }

  @override
  State<AddAmenityDialog> createState() => _AddAmenityDialogState();
}

class _AddAmenityDialogState extends State<AddAmenityDialog> {
  final _amenityCtrl = TextEditingController();

  @override
  void dispose() {
    _amenityCtrl.dispose();
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
        'Yeni Tesis Olanağı Ekle',
        style: AppTypography.titleCard.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olanak Adı', style: AppTypography.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _amenityCtrl,
            style: AppTypography.bodyDefault,
            decoration: InputDecoration(
              hintText: 'Örn: Yerden Isıtmalı Zemin, Geniş Havuz',
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
            final text = _amenityCtrl.text.trim();
            if (text.isNotEmpty) {
              context.read<ProviderCubit>().addAmenity(text);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$text olanağı eklendi!'),
                  backgroundColor:
                      isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor:
                isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

