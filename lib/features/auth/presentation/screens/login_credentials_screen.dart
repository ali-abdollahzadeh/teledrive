import 'package:country_picker/country_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

// Import your newly created custom widgets
import '../widgets/country_field.dart';
import '../widgets/phone_field.dart';

class LoginCredentialsScreen extends ConsumerStatefulWidget {
  const LoginCredentialsScreen({super.key});

  @override
  ConsumerState<LoginCredentialsScreen> createState() =>
      _LoginCredentialsScreenState();
}

class _LoginCredentialsScreenState
    extends ConsumerState<LoginCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  String _countryName = 'Italy';
  String _countryFlag = '🇮🇹';
  String _dialCode = '+39';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.75,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _countryName = country.name;
          _countryFlag = country.flagEmoji;
          _dialCode = '+${country.phoneCode}';
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawPhone = _phoneCtrl.text.trim();
    final localPhone =
        rawPhone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    final fullPhone = '$_dialCode$localPhone';

    await ref.read(authProvider.notifier).sendCode(phone: fullPhone);

    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state.step == AuthStep.codeSent) {
      context.push(
          '${AppRoutes.verifyCode}?phone=${Uri.encodeComponent(fullPhone)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for Auth errors
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
            // 1. Background
            _buildBackground(isDark),

            // 2. Main Content Form
            SafeArea(
              child: Form(
                key: _formKey,
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
                              AppText.signInWithTelegram,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppText.enterYourPhone,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.55),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 56),

                            // Reusable Country Field
                            CountryField(
                              countryName: _countryName,
                              countryFlag: _countryFlag,
                              onTap: _openCountryPicker,
                            ),
                            const SizedBox(height: 18),

                            // Reusable Phone Field
                            PhoneField(
                              controller: _phoneCtrl,
                              dialCode: _dialCode,
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    // 3. Floating Action Button
                    Positioned(
                      right: 32,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 24
                          : 48,
                      child: _buildSubmitButton(isLoading),
                    ),

                    // 4. Back Button
                    Positioned(
                      top: 8,
                      left: 4,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? Colors.white
                              : AppColors.defaultBlackText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: isDark
          ? SvgPicture.asset('assets/images/bg_dark.svg', fit: BoxFit.cover)
          : Container(
              decoration: const BoxDecoration(
                gradient: AppColors.washedBlueBackground,
              ),
            ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return FloatingActionButton(
      heroTag: 'phone_login_next',
      onPressed: isLoading ? null : _submit,
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
          : const Icon(Icons.arrow_forward_rounded, size: 32),
    );
  }
}
