import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class CodeVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const CodeVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<CodeVerificationScreen> createState() =>
      _CodeVerificationScreenState();
}

class _CodeVerificationScreenState
    extends ConsumerState<CodeVerificationScreen> {
  final _codeCtrl = TextEditingController();
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canResend = true;
          _countdown = 0;
        }
      });
      return _countdown > 0;
    });
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppText.pleaseEnterFullCode)),
      );
      return;
    }

    final success =
        await ref.read(authProvider.notifier).verifyCode(_codeCtrl.text.trim());

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.drive);
    } else {
      final state = ref.read(authProvider);
      if (state.step == AuthStep.needs2FA) {
        context.push(AppRoutes.verifyPassword);
      }
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
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
            // 1. Same Background as Login
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
                            AppText.verifyCode,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${AppText.codeSentTo}\n${widget.phoneNumber}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.55),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 56),

                          // 3. New 500-radius Text Field
                          _CodeField(controller: _codeCtrl),
                          const SizedBox(height: 24),

                          // 4. Centered Resend Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _canResend
                                    ? AppText.didntReceiveCode
                                    : '${AppText.resendIn} ${_countdown}s',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                              if (_canResend) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _countdown = 60;
                                      _canResend = false;
                                    });
                                    _startCountdown();
                                  },
                                  child: Text(
                                    AppText.resend,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),

                  // 5. Floating Submit Button
                  Positioned(
                    right: 32,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom > 0 ? 24 : 48,
                    child: FloatingActionButton(
                      heroTag: 'verify_code_next',
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

                  // 6. Custom Back Button
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
// Custom Input Field with 500 border radius
// (You can also extract this into widgets/code_field.dart later)
// ---------------------------------------------------------------------------
class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center, // Center the code visually
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5), // Limits to 5 digits
      ],
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 8.0, // Adds nice spacing between the numbers
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        hintText: '• • • • •', // Visual hint
        hintStyle: TextStyle(
          letterSpacing: 8.0,
          color: theme.hintColor.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
