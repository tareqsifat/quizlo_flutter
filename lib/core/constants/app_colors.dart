import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// Quizlo Design System — Color Tokens
/// Extracted pixel-perfect from Figma screens
/// ─────────────────────────────────────────────
abstract class AppColors {
  // ── Primary Brand ──────────────────────────
  static const Color primary = Color(0xFF1BA1F2);
  static const Color primaryLight = Color(0xFF4FC3F7);
  static const Color primaryDark = Color(0xFF0A75B6);
  static const Color primarySurface = Color(0xFFE8F5FE);

  // ── CTA Color ──────────────────────────────
  static const Color cta = Color(0xFF5B4FDC);

  // ── Accent / Orange ────────────────────────
  static const Color accent = Color(0xFFF39C12);
  static const Color accentLight = Color(0xFFFAB641);
  static const Color accentDark = Color(0xFFE67E22);

  // ── Backgrounds ────────────────────────────
  static const Color scaffoldBg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color onboardingBg = Color(0xFF1BA1F2);
  static const Color darkOverlay = Color(0x80000000);

  // ── Text ───────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Answer States ──────────────────────────
  static const Color answerDefault = Color(0xFFFFFFFF);
  static const Color answerSelected = Color(0xFFEAF6FD);
  static const Color answerSelectedBorder = Color(0xFF1BA1F2);
  static const Color answerCorrect = Color(0xFFEAF6FD);
  static const Color answerCorrectBorder = Color(0xFF1BA1F2);
  static const Color answerCorrectText = Color(0xFF0E7DBF);
  static const Color answerWrong = Color(0xFFFFF8EC);
  static const Color answerWrongBorder = Color(0xFFF39C12);
  static const Color answerWrongText = Color(0xFFB87A00);

  // Transient tap-feedback flash (pastel tints of green/red, blended
  // toward white so the flash reads as gentle rather than alarming).
  static const Color answerFlashCorrect = Color(0xFFC9E7CB);
  static const Color answerFlashWrong = Color(0xFFFCC7C3);

  // ── Status ─────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // ── Feedback Banner ────────────────────────
  static const Color feedbackCorrectBg = Color(0xFFEAF6FD);
  static const Color feedbackCorrectBorder = Color(0xFFC8E8F9);
  static const Color feedbackWrongBg = Color(0xFFFFF8EC);
  static const Color feedbackWrongBorder = Color(0xFFF5D78A);

  // ── Rankings ───────────────────────────────
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  // ── Gamification ───────────────────────────
  static const Color heartRed = Color(0xFFE74C3C);
  static const Color coinGold = Color(0xFFF1C40F);
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color xpPurple = Color(0xFF5B4FDC);

  // ── Quiz Stats ─────────────────────────────
  static const Color statGreen = Color(0xFF27AE60);
  static const Color statGreenBg = Color(0xFFE8F8F0);
  static const Color statOrange = Color(0xFFF39C12);
  static const Color statOrangeBg = Color(0xFFFEF9EC);
  static const Color statPurple = Color(0xFF5B4FDC);
  static const Color statPurpleBg = Color(0xFFEEECFB);

  // ── UI Elements ────────────────────────────
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFDDDDDD);
  static const Color shadowColor = Color(0x1A000000);
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ── Social Auth ────────────────────────────
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color googleWhite = Color(0xFFFFFFFF);

  // ── Category Chips ─────────────────────────
  static const Color chipBg = Color(0xFFE8F5FE);
  static const Color chipText = Color(0xFF1BA1F2);
  static const Color chipBgActive = Color(0xFF1BA1F2);
  static const Color chipTextActive = Color(0xFFFFFFFF);

  // ── Bottom Nav ─────────────────────────────
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFF1BA1F2);
  static const Color navInactive = Color(0xFFAAAAAA);

  // ── Progress Bar ───────────────────────────
  static const Color progressFill = Color(0xFF1BA1F2);
  static const Color progressTrack = Color(0xFFDDDDDD);

  // ── Onboarding Dots ────────────────────────
  static const Color dotActive = Color(0xFFF39C12);
  static const Color dotInactive = Color(0xFFDDDDDD);
}
