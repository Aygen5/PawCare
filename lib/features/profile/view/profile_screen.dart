import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/user_role.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/role_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_setting_tile.dart';
import '../widgets/theme_selector_card.dart';
import '../widgets/user_profile_card.dart';

/// Faz 5 Adım 5.2 — Profil, Ayarlar ve Tema Değiştirici Ekranı.
class ProfileScreen extends StatelessWidget {
  final ProfileCubit? cubit;
  final VoidCallback? onLogout;
  final VoidCallback? onDogProfileTap;

  const ProfileScreen({
    super.key,
    this.cubit,
    this.onLogout,
    this.onDogProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _ProfileView(
          onLogout: onLogout,
          onDogProfileTap: onDogProfileTap,
        ),
      );
    }

    return BlocProvider(
      create: (ctx) {
        final auth = ctx.read<AuthCubit?>()?.state;
        final role = ctx.read<RoleCubit?>()?.state;
        return ProfileCubit()..loadProfile(
          initialName: auth?.userName,
          initialEmail: auth?.userEmail,
          currentRole: role,
        );
      },
      child: _ProfileView(onLogout: onLogout, onDogProfileTap: onDogProfileTap),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onDogProfileTap;

  const _ProfileView({this.onLogout, this.onDogProfileTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final isOwner = state.role == UserRole.owner;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sayfa Başlığı
                  Text(
                    'Hesap & Profil',
                    style: AppTypography.headlineScreen.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kişisel bilgileriniz, evcil hayvanınız ve uygulama tercihleri',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Kullanıcı ve Evcil Hayvan Kartı
                  UserProfileCard(
                    onDogProfileTap: () {
                      if (onDogProfileTap != null) {
                        onDogProfileTap!();
                      } else {
                        context.go(RoutePaths.pets);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // 2. Tema Değiştirici Kartı (Segmented Control: Açık / Koyu Haki / Sistem)
                  const ThemeSelectorCard(),

                  const SizedBox(height: 24),

                  // 3. Ayarlar ve Tercihler Başlığı
                  Text(
                    'Ayarlar & Tercihler',
                    style: AppTypography.headlineSection.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bildirimler
                  ProfileSettingTile(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirim Tercihleri',
                    subtitle: isOwner
                        ? 'Aşı takvimi, yürüyüş ve rezervasyon uyarıları'
                        : 'Gelen rezervasyon talepleri ve misafir patiler',
                    onTap: () => _showNotificationPreferences(context, isOwner),
                    trailing: Switch(
                      value: state.notificationsEnabled,
                      activeThumbColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      onChanged: (val) {
                        context.read<ProfileCubit>().toggleNotifications(val);
                      },
                    ),
                  ),

                  // Ödeme Yöntemleri
                  ProfileSettingTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Ödeme Yöntemleri',
                    subtitle: 'Mastercard •••• 4821',
                    onTap: () => _showPaymentInfo(context),
                  ),

                  // Gizlilik & Güvenlik
                  ProfileSettingTile(
                    icon: Icons.security_outlined,
                    title: 'Gizlilik & Güvenlik',
                    subtitle: 'Şifre, biyometri ve hesap koruması',
                    onTap: () => _showPrivacyInfo(context),
                  ),

                  // Yardım & Destek
                  ProfileSettingTile(
                    icon: Icons.help_outline,
                    title: 'Yardım & Destek',
                    subtitle: '7/24 PawCare canlı destek ve SSS',
                    onTap: () => _showHelpInfo(context),
                  ),

                  // Uygulama Hakkında
                  ProfileSettingTile(
                    icon: Icons.info_outline,
                    title: 'PawCare Hakkında',
                    subtitle: 'Sürüm 1.0.0',
                    onTap: () => _showAboutInfo(context),
                  ),

                  const SizedBox(height: 24),

                  // 4. Rol Değiştirme Butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final roleCubit = context.read<RoleCubit?>();
                        final nextRole = state.role == UserRole.owner
                            ? UserRole.sitter
                            : UserRole.owner;

                        roleCubit?.setRole(nextRole);
                        context.read<ProfileCubit>().toggleRole();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nextRole == UserRole.sitter
                                  ? 'Hizmet Veren moduna geçildi.'
                                  : 'Köpek Sahibi moduna geçildi.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        Icons.swap_horiz,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                      label: Text(
                        state.role == UserRole.owner
                            ? 'Hizmet Veren Moduna Geç'
                            : 'Köpek Sahibi Moduna Geç',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Çıkış Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _handleLogout(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Çıkış Yap',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Apple Guideline 5.1.1: Hesabımı ve Verilerimi Kalıcı Olarak Sil
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _handleDeleteAccount(context),
                      icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 20),
                      label: Text(
                        'Hesabımı ve Verilerimi Kalıcı Olarak Sil',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Çıkış Yapılsın mı?'),
          content: const Text(
            'Mevcut oturumunuz sonlandırılacak ve karşılama ekranına yönlendirileceksiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthCubit?>()?.logout();
                if (onLogout != null) {
                  onLogout!();
                } else {
                  context.go(RoutePaths.welcome);
                }
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kayıtlı Ödeme Yöntemleri'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.credit_card, color: AppColors.primary),
              title: Text('Mastercard •••• 4821'),
              subtitle: Text('Varsayılan kart • SKT: 08/28'),
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: AppColors.secondary),
              title: Text('Visa •••• 1905'),
              subtitle: Text('Yedek kart • SKT: 11/27'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 8),
              Text(
                'Hesabı Kalıcı Olarak Sil',
                style: AppTypography.headlineSection.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Bu işlem geri alınamaz!\n\nHesabınız, tüm evcil hayvan kayıtlarınız, geçmiş ve aktif rezervasyonlarınız, mesajlarınız ve profil verileriniz veritabanımızdan kalıcı olarak silinecektir.\n\nDevam etmek istediğinize emin misiniz?',
            style: AppTypography.bodyDefault.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Vazgeç',
                style: TextStyle(
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final cubit = context.read<AuthCubit?>();
                if (cubit != null) {
                  final success = await cubit.deleteAccount();
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hesabınız ve tüm verileriniz başarıyla silindi.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      context.go(RoutePaths.welcome);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            cubit.state.errorMessage ??
                                'Hesap silinirken bir hata oluştu.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Evet, Hesabımı Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gizlilik ve Güvenlik İlkeleri',
          style: AppTypography.headlineSection.copyWith(
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PawCare Gizlilik & KVKK / GDPR Taahhüdü',
                style: AppTypography.titleCard.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Konum Verileri (GPS): Sadece aktif yürüyüş seansı esnasında evcil hayvanınızın güvenliği ve canlı harita takibi için kullanılır. Yürüyüş bittiğinde konum yayını durdurulur.\n\n'
                '• Fotoğraf & Galeri: Evcil hayvanınızın sağlık karnesi, aşı belgeleri ve profil resimlerini yükleyebilmeniz için kullanılır.\n\n'
                '• Veri Saklama ve Güvenlik: Tüm kullanıcı ve rezervasyon verileri Google Cloud Firestore üzerinde güvenli şifreleme ile barındırılır.\n\n'
                '• Hesap & Veri Silme: Apple ve Google ilkelerine uygun olarak dilediğiniz zaman "Hesabımı Sil" butonuyla tüm kişisel kayıtlarınızı kalıcı olarak silebilirsiniz.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Anladım',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yardım & Destek'),
        content: const Text(
          'Sorularınız veya rezervasyon destek talepleriniz için destek@pawcare.com adresinden veya 0850 123 45 67 numaralı hattan bize ulaşabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAboutInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'PawCare Hakkında',
          style: AppTypography.headlineSection.copyWith(
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        content: Text(
          'PawCare, evcil hayvan sahipleri ile güvenilir, profesyonel bakıcıları bir araya getiren yeni nesil pati bakım platformudur. Can dostlarımızın aşı ve sağlık takvimlerini kolayca yönetmenizi, dilediğiniz an uzman bakıcı veya köpek oteli bulmanızı ve rezervasyon sürecini canlı bildirimlerle güvenle takip etmenizi sağlar. Sevgiyle büyüyen pati dostu bir topluluk için buradayız.\n\nSürüm: 1.0.0',
          style: AppTypography.bodyDefault.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Harika',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationPreferences(BuildContext context, bool isOwner) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isOwner ? 'Köpek Sahibi Bildirimleri' : 'Hizmet Veren Bildirimleri',
          style: AppTypography.headlineSection.copyWith(
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isOwner
              ? [
                  _buildPrefRow('💉 Aşı Takvimi & Hatırlatmalar', true, isDark),
                  const SizedBox(height: 12),
                  _buildPrefRow(
                    '🦮 Yürüyüş Seansı & Canlı Takip',
                    true,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPrefRow(
                    '🐾 Rezervasyon Durum Güncellemeleri',
                    true,
                    isDark,
                  ),
                ]
              : [
                  _buildPrefRow('📋 Gelen Rezervasyon Talepleri', true, isDark),
                  const SizedBox(height: 12),
                  _buildPrefRow(
                    '🐶 Misafir Pati Giriş & Çıkış Uyarıları',
                    true,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPrefRow(
                    '💬 Müşteri Mesajları & Canlı Destek',
                    true,
                    isDark,
                  ),
                ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tamam',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefRow(String label, bool initialValue, bool isDark) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),
            Switch(
              value: initialValue,
              activeThumbColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.primary,
              onChanged: (val) => setState(() => initialValue = val),
            ),
          ],
        );
      },
    );
  }
}
