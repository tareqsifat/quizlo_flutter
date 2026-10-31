import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/hearts_service.dart';

/// Shown over the quiz when the hearts run out: the backend rejects answers
/// at 0 hearts, so this blocks the quiz until the user refills.
/// The "Auto Refill" button is where a rewarded ad will go in future.
class OutOfHeartsToast extends StatefulWidget {
  const OutOfHeartsToast({super.key});

  @override
  State<OutOfHeartsToast> createState() => _OutOfHeartsToastState();
}

class _OutOfHeartsToastState extends State<OutOfHeartsToast> {
  bool _refilling = false;

  Future<void> _refill() async {
    setState(() => _refilling = true);
    // TODO: show a rewarded ad here, then refill once it has been watched.
    final ok = await HeartsService.autoRefill();
    if (!mounted) return;
    setState(() => _refilling = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill failed. Please try again.')),
      );
    }
    // On success the cached count goes up and the quiz screen removes this.
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black38),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: const Color(0xFF323232),
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.heart_broken_rounded, color: AppColors.heartRed),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'আপনার হার্ট শেষ হয়ে গেছে',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _refilling ? null : _refill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.heartRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.heartRed.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _refilling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Auto Refill'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
