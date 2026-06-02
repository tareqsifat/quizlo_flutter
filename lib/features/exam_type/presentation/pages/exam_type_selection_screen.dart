import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';


/// ─────────────────────────────────────────────
/// Exam Type Selection Screen
/// Shown ONCE to new users after registration
/// Old users with saved exam type skip directly to Home
///
/// Exam types shown: BCS, SSC, HSC, University Prep, Job Prep, etc.
/// Fetched from GET /exam-types (or cached locally)
/// ─────────────────────────────────────────────
class ExamTypeSelectionScreen extends StatefulWidget {
  const ExamTypeSelectionScreen({super.key});

  @override
  State<ExamTypeSelectionScreen> createState() => _ExamTypeSelectionScreenState();
}

class _ExamTypeSelectionScreenState extends State<ExamTypeSelectionScreen> {
  final Set<int> _selected = {};
  bool _loading = false;

  // Mock exam types — in production, fetched from GET /exam-types
  static const _examTypes = [
    _ExamType(id: 1, name: 'BCS Preliminary', nameBn: 'বিসিএস প্রিলিমিনারি', code: 'BCS', icon: '🎖️', color: Color(0xFF5B4FDC)),
    _ExamType(id: 2, name: 'SSC', nameBn: 'এসএসসি', code: 'SSC', icon: '📚', color: Color(0xFF27AE60)),
    _ExamType(id: 3, name: 'HSC', nameBn: 'এইচএসসি', code: 'HSC', icon: '🏫', color: Color(0xFFE67E22)),
    _ExamType(id: 4, name: 'University Prep', nameBn: 'বিশ্ববিদ্যালয় ভর্তি', code: 'UNIV', icon: '🎓', color: Color(0xFF3498DB)),
    _ExamType(id: 5, name: 'Job Prep', nameBn: 'চাকরির প্রস্তুতি', code: 'JOB', icon: '💼', color: Color(0xFF9B59B6)),
    _ExamType(id: 6, name: 'Medical Admission', nameBn: 'মেডিকেল ভর্তি', code: 'MED', icon: '⚕️', color: Color(0xFFE74C3C)),
    _ExamType(id: 7, name: 'Bank Jobs', nameBn: 'ব্যাংক চাকরি', code: 'BANK', icon: '🏦', color: Color(0xFF1ABC9C)),
    _ExamType(id: 8, name: 'Primary Teacher', nameBn: 'প্রাথমিক শিক্ষক', code: 'PRIMARY', icon: '✏️', color: Color(0xFFF39C12)),
  ];

  void _proceed() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    // TODO: Call POST /user/exam-types for each selected type
    // First selected is primary
    final activeExamTypeId = _selected.first;
    await HiveStorage.saveActiveExamTypeId(activeExamTypeId);
    await HiveStorage.setExamTypeSelected(true);
    if (mounted) {
      setState(() => _loading = false);
      context.go(AppRoutes.home);
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
            // ── Header ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding, 24, AppSizes.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo top
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(text: 'Quiz', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      TextSpan(text: 'Lo', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('What are you\npreparing for?', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Select one or more exam types. You can change this later.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Grid ────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _examTypes.length,
                  itemBuilder: (context, i) {
                    final type = _examTypes[i];
                    final isSelected = _selected.contains(type.id);
                    return _ExamTypeCard(
                      examType: type,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        if (isSelected) _selected.remove(type.id);
                        else _selected.add(type.id);
                      }),
                    );
                  },
                ),
              ),
            ),

            // ── Continue Button ─────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                children: [
                  if (_selected.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${_selected.length} exam type${_selected.length > 1 ? 's' : ''} selected',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  AppButton(
                    label: 'Continue',
                    isLoading: _loading,
                    onTap: _selected.isNotEmpty ? _proceed : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamTypeCard extends StatelessWidget {
  final _ExamType examType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamTypeCard({
    required this.examType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? examType.color.withOpacity(0.1) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: isSelected ? examType.color : AppColors.border,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: examType.color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
            : [const BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(examType.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  examType.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? examType.color : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: examType.color),
                      const SizedBox(width: 4),
                      Text('Selected', style: AppTextStyles.caption.copyWith(color: examType.color)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamType {
  final int id;
  final String name;
  final String nameBn;
  final String code;
  final String icon;
  final Color color;

  const _ExamType({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.code,
    required this.icon,
    required this.color,
  });
}
