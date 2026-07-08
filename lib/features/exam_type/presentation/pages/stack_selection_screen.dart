import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:dio/dio.dart';

class StackSelectionScreen extends StatefulWidget {
  const StackSelectionScreen({super.key});

  @override
  State<StackSelectionScreen> createState() => _StackSelectionScreenState();
}

class _StackSelectionScreenState extends State<StackSelectionScreen> {
  String? _selectedStack;
  final _dioClient = DioClient();
  List<Map<String, dynamic>> _stacks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExamTypes();
  }

  Future<void> _fetchExamTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dioClient.get(ApiEndpoints.examTypes);
      final dataList = response.data['data'] as List;
      setState(() {
        _stacks = dataList.map((item) {
          final code = item['code'] as String;
          return {
            'id': item['id'] as int,
            'code': code,
            'name': item['name'] as String,
            'icon': _getExamTypeEmoji(code),
          };
        }).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exam types: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _getExamTypeEmoji(String code) {
    switch (code.toUpperCase()) {
      case 'BCS':
      case 'BCS_PRELIM':
        return '🎖️';
      case 'SSC':
        return '📚';
      case 'HSC':
        return '🏫';
      case 'IELTS':
        return '✈️';
      default:
        return '📝';
    }
  }

  void _onContinue() async {
    final selectedItem = _stacks.firstWhere((s) => s['code'] == _selectedStack, orElse: () => null);
    if (selectedItem == null) return;
    
    final id = selectedItem['id'] as int;
    final code = selectedItem['code'] as String;

    await HiveStorage.saveActiveExamTypeId(id);
    await HiveStorage.saveSelectedStack(code == 'BCS_PRELIM' ? 'BCS' : code);
    await HiveStorage.setExamTypeSelected(true);
    
    if (mounted) {
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
                  AppSizes.screenPadding, 32, AppSizes.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                          text: 'Quiz',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E))),
                      TextSpan(
                          text: 'Lo',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('Choose your path', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Select a preparation stack to customize your learning journey.',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Stacks Grid ──────────────────
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
                                  onTap: _fetchExamTypes,
                                  height: AppSizes.buttonHeightMd,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.screenPadding),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: _stacks.length,
                            itemBuilder: (context, index) {
                              final item = _stacks[index];
                              final code = item['code'] as String;
                              final name = item['name'] as String;
                              final icon = item['icon'] as String;
                              final isSelected = _selectedStack == code;

                              return _StackCard3D(
                                name: name,
                                icon: icon,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedStack = code;
                                  });
                                },
                              );
                            },
                          ),
                        ),
            ),

            // ── Continue Button ─────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: AppButton(
                label: 'Continue',
                onTap: _selectedStack != null ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackCard3D extends StatefulWidget {
  final String name;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StackCard3D({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StackCard3D> createState() => _StackCard3DState();
}

class _StackCard3DState extends State<_StackCard3D> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 5.0;
    const double borderRadius = 20.0;

    // Use CTA color (purple) for selected, Primary color (blue) for unselected
    final topColor = widget.isSelected ? AppColors.cta : AppColors.primary;
    final shadowColor = widget.isSelected ? const Color(0xFF4538C4) : AppColors.primaryDark;

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
          // Shadow Layer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: shadowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Front Card Layer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeIn,
            left: 0,
            right: 0,
            top: _isPressed ? shadowHeight : 0,
            bottom: _isPressed ? 0 : shadowHeight,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: topColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    widget.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
