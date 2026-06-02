import 'package:flutter/material.dart';

/// App color palette based on the Interest screen design
class AppColors {
  // Primary colors (Bright Blue/Violet from reference design)
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF8B5CF6);

  // Gradient colors (matching the Continue button in reference - blue to violet)
  static const Color gradientStart = Color(0xFF3B82F6);
  static const Color gradientEnd = Color(0xFF8B5CF6);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Input field colors
  static const Color inputBackground = Color(0xFFF1F5F9);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputBorderFocused = Color(0xFF3B82F6);

  // Button colors
  static const Color buttonText = Color(0xFFFFFFFF);

  // Social button backgrounds
  static const Color googleButton = Color(0xFFFFFFFF);
  static const Color facebookButton = Color(0xFF1877F2);
  static const Color appleButton = Color(0xFF000000);

  // Accent colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Selected/Active states
  static const Color selectedCard = Color(0xFF3B82F6);
  static const Color selectedCardLight = Color(0xFFEFF6FF);

  // Primary gradient (Bright Blue to Violet - matching reference design)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Selected card gradient (same as button)
  static const LinearGradient selectedCardGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Session Analysis Colors
  static const Color sessionNavy = Color(0xFF1E3A8A); // primaryPurple
  static const Color sessionIndigo = Color(0xFF1E40AF); // primaryBlue
  static const Color sessionAccentBlue = Color(0xFF2563EB); // accentBlue
  static const Color sessionBackground = Color(0xFFEFF6FF); // backgroundColor

  static const Color starYellow = Color(0xFFFBBF24);
  static const Color progressBackground = Color(0xFFDBEAFE);

  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconGreen = Color(0xFF10B981);
  static const Color iconPurple = Color(0xFF1D4ED8);

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shinyPurpleGradient = LinearGradient(
    colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
