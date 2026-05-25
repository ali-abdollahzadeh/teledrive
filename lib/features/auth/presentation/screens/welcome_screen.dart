import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';

// Import your newly created widget
import '../widgets/feature_row.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _contentController;
  late final AnimationController _floatingController;

  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut,
      ),
    );

    _introController.forward().then((_) {
      _floatingController.repeat(reverse: true);
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    final current = ref.read(themeModeProvider);
    final next = current == ThemeMode.dark
        ? ThemeMode.light
        : (current == ThemeMode.light ? ThemeMode.system : ThemeMode.dark);

    ref.read(themeModeProvider.notifier).state = next;
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF4F4F6);
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Animated 3D Background
          _buildFloatingBackground(),

          // 2. Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeToggle(themeMode, isDark),
                const SizedBox(height: 32),

                // Scrolling Features & Header
                Expanded(
                  child: FadeTransition(
                    opacity: _contentOpacity,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(textColor),
                            const SizedBox(height: 48),
                            _buildFeaturesList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Call to Action Button
                _buildCtaArea(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildFloatingBackground() {
    return Positioned(
      bottom: -60,
      right: -40,
      left: 40,
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          final floatingValue = sin(_floatingController.value * pi);
          return Transform.translate(
            offset: Offset(0, -8 * floatingValue),
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/folder_3d.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeToggle(ThemeMode themeMode, bool isDark) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 16),
        child: FadeTransition(
          opacity: _contentOpacity,
          child: IconButton(
            onPressed: _toggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _themeIcon(themeMode),
                key: ValueKey(themeMode),
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.lightTextSecondary,
                size: 22,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.welcomeHeadline,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.w400,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
            children: const [
              TextSpan(text: AppText.welcomeSubtitlePart1),
              TextSpan(
                text: AppText.welcomeSubtitlePart2,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: AppText.welcomeSubtitlePart3),
              TextSpan(
                text: AppText.welcomeSubtitlePart4,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: AppText.welcomeSubtitlePart5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return const Column(
      children: [
        FeatureRow(
          icon: Icons.shield_outlined,
          title: AppText.featurePrivacyTitle,
          subtitle: AppText.featurePrivacySubtitle,
        ),
        SizedBox(height: 28),
        FeatureRow(
          icon: Icons.all_inclusive_rounded,
          title: AppText.featureSpaceTitle,
          subtitle: AppText.featureSpaceSubtitle,
        ),
        SizedBox(height: 28),
        FeatureRow(
          icon: Icons.speed_rounded,
          title: AppText.featureFastTitle,
          subtitle: AppText.featureFastSubtitle,
        ),
        SizedBox(height: 28),
        FeatureRow(
          icon: Symbols.diamond_shine_sharp,
          title: AppText.featureFoldersTitle,
          subtitle: AppText.featureFoldersSubtitle,
        ),
      ],
    );
  }

  Widget _buildCtaArea(bool isDark) {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    AppText.getStarted,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppText.welcomeFooter,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textHintDark : const Color(0xFF4A4A4A),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
