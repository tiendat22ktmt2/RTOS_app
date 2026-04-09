import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgPrimary = Color(0xFF0D0F14);
  static const Color bgSecondary = Color(0xFF161A22);
  static const Color bgCard = Color(0xFF1E2330);
  static const Color bgCardHover = Color(0xFF252B3B);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentGlow = Color(0x333B82F6);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerGlow = Color(0x33EF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF334155);
  static const Color borderColor = Color(0xFF1E2D3D);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          error: danger,
          surface: bgCard,
        ),
        fontFamily: 'monospace',
        appBarTheme: const AppBarTheme(
          backgroundColor: bgSecondary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: textSecondary),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderColor, width: 0.5),
          ),
        ),
      );
}
