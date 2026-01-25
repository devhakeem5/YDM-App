import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1E3A5F);
  static const Color secondary = Color(0xFF3A6B8E); // Calculated complementary/analogous
  static const Color accent = Color(0xFFEF476F); // For potential highlights

  // Neutral Colors (Light)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6C757D);

  // Neutral Colors (Dark)
  static const Color backgroundDark = Color(0xFF121212); // True Dark, not just grey
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFEDEDED);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Material 3 Seed Generate (Use this for dynamic schemes if needed)
  static const Color seedColor = primary;
}
