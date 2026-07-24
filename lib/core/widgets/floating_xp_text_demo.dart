import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'floating_xp_text.dart';

/// Standalone demo screen — wire this up as your `home:` temporarily
/// (or push it from any route) to see the "+XP" swoop trigger live.
class FloatingXpTextDemo extends StatelessWidget {
  const FloatingXpTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Floating XP Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => FloatingXpText.show(context, xp: 10),
          child: const Text('Answer correctly'),
        ),
      ),
    );
  }
}
