import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const felt = Color(0xFF0F3B2F);
  static const feltDeep = Color(0xFF07231B);
  static const gold = Color(0xFFE9C46A);
  static const cardFace = Color(0xFFF7F3E8);
  static const cardInk = Color(0xFF16211D);
  static const win = Color(0xFF3FBF7F);
  static const lose = Color(0xFFE06C5B);
  static const tie = Color(0xFFE9C46A);
}

class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.felt,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.gold,
        onPrimary: AppColors.feltDeep,
        surface: AppColors.felt,
      ),
      scaffoldBackgroundColor: AppColors.feltDeep,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.feltDeep,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
