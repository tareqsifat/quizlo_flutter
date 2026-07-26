import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/global_top_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/app_toast.dart';
import 'package:dio/dio.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> with RouteAware {
  final _dioClient = DioClient();
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returning from the quiz flow (or any pushed route) — the per-subject
    // "solved" counts in Hive may have changed, so rebuild to re-read them.
    setState(() {});
  }

  Future<void> _fetchSubjects() async {
    if (HiveStorage.isDemoMode()) {
      _loadDemoSubjects();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
      final response = await _dioClient.get(
        ApiEndpoints.subjects,
        queryParams: {'exam_type_id': examTypeId},
      );
      final dataList = response.data['data'] as List;
      setState(() {
        _subjects = dataList.map((item) {
          final slug = item['slug'] as String;
          return {
            'name': slug,
            'displayName': item['name'] as String,
            'icon': _getEmojiIcon(slug),
            'total': item['total_marks'] as int? ?? 10,
          };
        }).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      AppToast.showError('API failed. Loading default subjects.');
      await HiveStorage.setDemoMode(true);
      _loadDemoSubjects();
    } catch (e) {
      AppToast.showError('An unexpected error occurred. Loading default subjects.');
      await HiveStorage.setDemoMode(true);
      _loadDemoSubjects();
    }
  }

  void _loadDemoSubjects() {
    final List<Map<String, dynamic>> demoSubjects = [
      {'name': 'bangla', 'displayName': 'Bangla Literature', 'icon': '🇧🇩', 'total': 35},
      {'name': 'english', 'displayName': 'English Grammar', 'icon': '🇬🇧', 'total': 35},
      {'name': 'Math & logic', 'displayName': 'Math & logic', 'icon': '📐', 'total': 16},
      {'name': 'ICT', 'displayName': 'ICT', 'icon': '💻', 'total': 18},
      {'name': 'cognitive ability', 'displayName': 'cognitive ability', 'icon': '🧠', 'total': 15},
      {'name': 'Etics & Value', 'displayName': 'Ethics & Values', 'icon': '⚖️', 'total': 10},
    ];

    setState(() {
      _subjects = demoSubjects;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  String _getEmojiIcon(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('bangla')) {
      return '🇧🇩';
    } else if (s.contains('english')) {
      return '🇬🇧';
    } else if (s.contains('math') || s.contains('reasoning') || s.contains('logic')) {
      return '📐';
    } else if (s.contains('ict') || s.contains('computer') || s.contains('information')) {
      return '💻';
    } else if (s.contains('cognitive') || s.contains('mental') || s.contains('ability')) {
      return '🧠';
    } else if (s.contains('bangladesh')) {
      return '🏛️';
    } else if (s.contains('international') || s.contains('global') || s.contains('affairs')) {
      return '🌍';
    } else if (s.contains('geography') || s.contains('environment') || s.contains('disaster')) {
      return '🗺️';
    } else if (s.contains('ethics') || s.contains('values')) {
      return '⚖️';
    } else if (s.contains('science')) {
      return '🧪';
    } else {
      return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlobalTopBar(),
            // ── Header ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding, 8, AppSizes.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                          text: 'Quiz',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E))),
                      TextSpan(
                          text: 'Lo',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('Choose a Subject', style: AppTextStyles.h1),
                  const SizedBox(height: 6),
                  Text(
                    'Select a subject to practice, or play a mixed random quiz.',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),

            if (HiveStorage.isDemoMode()) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connection offline. Running in Demo Mode with local default subjects.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 16),

            // ── Grid of Subjects ─────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.screenPadding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Retry',
                                  onTap: _fetchSubjects,
                                  height: AppSizes.buttonHeightMd,
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.screenPadding, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16, // Extra vertical space for 3D card layout
                            childAspectRatio: 1.25,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final sub = _subjects[index];
                            final name = sub['name'] as String;
                            final displayName = sub['displayName'] as String;
                            final icon = sub['icon'] as String;
                            final total = sub['total'] as int;

                            // Get correct answers count from Hive
                            final correctCount = HiveStorage.getCorrectQuestionsCount(name);
                            final progress = (correctCount / total).clamp(0.0, 1.0);

                            return _SubjectCard3D(
                              name: name,
                              displayName: displayName,
                              icon: icon,
                              correctCount: correctCount,
                              total: total,
                              progress: progress,
                              onTap: () {
                                context.push(AppRoutes.quizLoading, extra: {
                                  'lesson_id': 0,
                                  'title': displayName,
                                  'subject': name,
                                });
                              },
                            );
                          },
                        ),
            ),

            // ── Random/Mixup Button ──────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: AppButton.cta(
                label: 'Random / Mixup',
                icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 20),
                onTap: () {
                  context.push(AppRoutes.quizLoading, extra: {
                    'lesson_id': 0,
                    'title': 'Random Mixup',
                    'subject': '', // Empty indicates all subjects mixed
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard3D extends StatefulWidget {
  final String name;
  final String displayName;
  final String icon;
  final int correctCount;
  final int total;
  final double progress;
  final VoidCallback onTap;

  const _SubjectCard3D({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.correctCount,
    required this.total,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_SubjectCard3D> createState() => _SubjectCard3DState();
}

class _SubjectCard3DState extends State<_SubjectCard3D> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 4.0;
    const double borderRadius = 18.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow layer (3D effect)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: shadowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Front Card Content
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeIn,
            left: 0,
            right: 0,
            top: _isPressed ? shadowHeight : 0,
            bottom: _isPressed ? 0 : shadowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius - 1.5),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              widget.displayName,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.correctCount}/${widget.total} solved',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Thin progress line at the bottom of the card
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: AppColors.divider,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: widget.progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
