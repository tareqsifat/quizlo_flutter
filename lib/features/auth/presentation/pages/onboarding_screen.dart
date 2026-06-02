import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Onboarding Screen — 3 slides
/// Purple bg with 3D characters, dot indicators
/// ─────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      title: 'Welcome to ',
      titleHighlight: 'QuizLo!',
      subtitle:
          'The smartest way to prepare for your exam. Learn, practice, and win!',
      imagePath: 'assets/images/onboarding_1.png',
    ),
    _OnboardingSlide(
      title: 'The Ultimate Trivia\n',
      titleHighlight: 'Challenge',
      subtitle:
          'Thousands of questions across all subjects. Track your progress and master each topic.',
      imagePath: 'assets/images/onboarding_2.png',
    ),
    _OnboardingSlide(
      title: 'Test Your Knowledge\nWith ',
      titleHighlight: 'QuizLo',
      subtitle:
          'Compete in leagues, earn rewards, and climb to the top of the leaderboard!',
      imagePath: 'assets/images/onboarding_3.png',
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _done();
    }
  }

  void _done() async {
    await HiveStorage.setOnboardingDone(true);
    if (mounted) context.go(AppRoutes.authLanding);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBg,
      body: Stack(
        children: [
          // ── Background gradient ─────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5B4FDC), Color(0xFF7B70E8)],
              ),
            ),
          ),

          // ── Page content ───────────────────
          Column(
            children: [
              // Header row
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      TextButton(
                        onPressed: _done,
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page view (illustration area)
              Expanded(
                flex: 55,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, i) =>
                      _OnboardingIllustration(slide: _slides[i], index: i),
                ),
              ),

              // ── White card at bottom ────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusXxl),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.xxl,
                  AppSizes.screenPadding,
                  AppSizes.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: RichText(
                        key: ValueKey(_currentPage),
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _slides[_currentPage].title,
                              style: AppTextStyles.h2,
                            ),
                            TextSpan(
                              text: _slides[_currentPage].titleHighlight,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        key: ValueKey('sub_$_currentPage'),
                        _slides[_currentPage].subtitle,
                        style: AppTextStyles.onboardingSubtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Dots + Button
                    Row(
                      children: [
                        // Dots
                        _DotIndicators(
                          count: _slides.length,
                          current: _currentPage,
                        ),
                        const Spacer(),
                        // Continue button
                        SizedBox(
                          width: 160,
                          height: AppSizes.buttonHeightLg,
                          child: AppButton(
                            label: 'Continue',
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicators({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  final _OnboardingSlide slide;
  final int index;

  const _OnboardingIllustration({required this.slide, required this.index});

  @override
  Widget build(BuildContext context) {
    // Placeholder illustrations — replace with actual 3D assets
    final icons = [
      Icons.public_rounded,
      Icons.quiz_rounded,
      Icons.menu_book_rounded,
    ];
    return Center(
      child: Icon(
        icons[index % icons.length],
        size: 160,
        color: Colors.white.withOpacity(0.85),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String titleHighlight;
  final String subtitle;
  final String imagePath;

  const _OnboardingSlide({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.imagePath,
  });
}
