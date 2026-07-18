import 'package:client/common/config/app_config.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:flutter/material.dart';

ThemeData buildAppTheme(AppBrand brand) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: brand.seedColor,
    primary: brand.primary,
    brightness: Brightness.light,
  );

  const borderRadius = BorderRadius.all(Radius.circular(16));

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ColorPalette.primaryBackground,
    fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: ColorPalette.primaryText,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ColorPalette.primaryText,
      ),
      iconTheme: IconThemeData(color: ColorPalette.primaryText),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      titleSmall: TextStyle(fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500),
      bodySmall: TextStyle(fontWeight: FontWeight.w500),
    ),
    dividerTheme: DividerThemeData(color: ColorPalette.shadow(.08)),
    cardTheme: CardThemeData(
      color: ColorPalette.secondaryBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorPalette.secondaryBackground,
      hintStyle: TextStyle(color: ColorPalette.secondaryText.withOpacity(.45)),
      labelStyle: TextStyle(color: ColorPalette.secondaryText.withOpacity(.70)),
      border: const OutlineInputBorder(borderRadius: borderRadius),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide:
            BorderSide(color: ColorPalette.secondaryText.withOpacity(.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconTheme: IconThemeData(color: colorScheme.primary),
  );
}
