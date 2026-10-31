import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_colors.dart';
import '../services/hearts_service.dart';
import '../storage/hive_storage.dart';

/// ❤ + current heart count. Rebuilds whenever the cached count changes.
class HeartsBadge extends StatefulWidget {
  /// Fetch the latest count from the server when shown. The quiz session
  /// manages its own count, so its app bar passes false.
  final bool refresh;

  const HeartsBadge({super.key, this.refresh = true});

  @override
  State<HeartsBadge> createState() => _HeartsBadgeState();
}

class _HeartsBadgeState extends State<HeartsBadge> {
  @override
  void initState() {
    super.initState();
    if (widget.refresh) HeartsService.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: HiveStorage.userBoxListenable,
      builder: (context, box, _) {
        final hearts = HiveStorage.getHearts();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hearts > 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppColors.heartRed,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$hearts',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.heartRed,
              ),
            ),
          ],
        );
      },
    );
  }
}
