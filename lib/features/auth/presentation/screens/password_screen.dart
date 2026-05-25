import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_passCtrl.text.isEmpty) return;

    final success =
        await ref.read(authProvider.notifier).verifyPassword(_passCtrl.text);

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.drive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // 1. Shared Background
            _buildBackground(isDark),

            // 2. Main Content
            SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 220),

                          Text(
                            AppText.twoStepVerification,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppText.enterTwoStepPassword,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 56),

                          // 3. New Pill-Shaped Password Field
                          _PasswordField(
                            controller: _passCtrl,
                            obscure: _obscure,
                            onToggle: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),

                  // 4. Floating Submit Button
                  Positioned(
                    right: 32,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom > 0 ? 24 : 48,
                    child: FloatingActionButton(
                      heroTag: 'password_next',
                      onPressed: isLoading ? null : _verify,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              size: 32,
                            ),
                    ),
                  ),

                  // 5. Custom Back Button
                  Positioned(
                    top: 8,
                    left: 4,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color:
                            isDark ? Colors.white : AppColors.defaultBlackText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: isDark
          ? SvgPicture.asset(
              'assets/images/bg_dark.svg',
              fit: BoxFit.cover,
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: AppColors.washedBlueBackground,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Password Field
// (Matches the 500-radius pill design from your other screens)
// ---------------------------------------------------------------------------
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autofocus: true,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        hintText: AppText.passwordHint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.primary,
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
            onPressed: onToggle,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
