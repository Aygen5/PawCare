import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_role.dart';
import '../../../features/auth/cubit/role_cubit.dart';
import '../../../features/chat/cubit/chat_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Bakıcı ve köpek sahibi arasındaki canlı sohbet penceresi modalı.
class ChatModal extends StatefulWidget {
  final String sitterName;
  final String avatarPath;

  const ChatModal({
    super.key,
    this.sitterName = 'Mert Demir',
    this.avatarPath = 'assets/images/mert.jpg',
  });

  static Future<void> show(
    BuildContext context, {
    String sitterName = 'Mert Demir',
    String avatarPath = 'assets/images/mert.jpg',
  }) {
    ChatCubit? existingCubit;
    try {
      existingCubit = context.read<ChatCubit?>();
    } catch (_) {}

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final content =
            ChatModal(sitterName: sitterName, avatarPath: avatarPath);
        if (existingCubit != null) {
          return BlocProvider.value(value: existingCubit, child: content);
        }
        return BlocProvider(create: (_) => ChatCubit(), child: content);
      },
    );
  }

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final role = context.read<RoleCubit?>()?.state ?? UserRole.owner;
    context.read<ChatCubit>().sendMessage(
      text,
      participantName: widget.sitterName,
      currentRole: role,
    );
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = context.watch<RoleCubit?>()?.state ?? UserRole.owner;
    final chatCubit = context.watch<ChatCubit>();
    final messages = chatCubit.state.getMessagesFor(widget.sitterName, role);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
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
          child: Column(
            children: [
              // Sohbet başlığı
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(widget.avatarPath),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sitterName,
                            style: AppTypography.titleCard,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Çevrim içi • Yanıt süresi ~5 dk',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
              ),
              const Divider(height: 1, color: AppColors.outlineVariant),
              // Mesaj listesi
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderRole != null
                        ? (msg.senderRole == role)
                        : msg.isMe;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        constraints: const BoxConstraints(maxWidth: 290),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primaryContainer
                              : (isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceContainerLow),
                          borderRadius: BorderRadius.circular(18).copyWith(
                            bottomRight: isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(18),
                            bottomLeft: !isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                msg.senderName,
                                style: AppTypography.labelTag.copyWith(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              msg.text,
                              style: AppTypography.bodyDefault.copyWith(
                                color: isMe
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkOnSurface
                                          : const Color(0xFF1E3023)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                msg.time,
                                style: AppTypography.labelTag.copyWith(
                                  color: isMe
                                      ? AppColors.onPrimaryContainer
                                      : (isDark
                                            ? AppColors.darkOnSurfaceVariant
                                            : AppColors.secondary),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineVariant),
              // Mesaj giriş alanı
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Mesajınızı yazın...',
                          hintStyle: AppTypography.bodyDefault.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.secondary.withValues(alpha: 0.7),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
