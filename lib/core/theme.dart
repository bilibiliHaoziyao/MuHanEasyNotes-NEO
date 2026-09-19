import 'package:flutter/material.dart';

/// 7 种主题色（与 Rust 端保持一致）
class NoteColors {
  static const red = Color(0xFFE74C3C);
  static const orange = Color(0xFFE67E22);
  static const yellow = Color(0xFFF1C40F);
  static const green = Color(0xFF2ECC71);
  static const blue = Color(0xFF3498DB);
  static const purple = Color(0xFF9B59B6);
  static const gray = Color(0xFF95A5A6);

  static const Map<String, Color> map = {
    'red': red,
    'orange': orange,
    'yellow': yellow,
    'green': green,
    'blue': blue,
    'purple': purple,
    'gray': gray,
  };

  static const List<String> names = [
    'red', 'orange', 'yellow', 'green', 'blue', 'purple', 'gray',
  ];

  static Color of(String name) => map[name] ?? yellow;
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color cardAccent;
  final Color surfaceSoft;
  final double cardRadius;
  final double platformPadding;

  const AppThemeExtension({
    required this.cardAccent,
    required this.surfaceSoft,
    required this.cardRadius,
    required this.platformPadding,
  });

  @override
  AppThemeExtension copyWith({
    Color? cardAccent,
    Color? surfaceSoft,
    double? cardRadius,
    double? platformPadding,
  }) {
    return AppThemeExtension(
      cardAccent: cardAccent ?? this.cardAccent,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      cardRadius: cardRadius ?? this.cardRadius,
      platformPadding: platformPadding ?? this.platformPadding,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      cardAccent: Color.lerp(cardAccent, other.cardAccent, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      platformPadding: platformPadding + (other.platformPadding - platformPadding) * t,
    );
  }
}

ThemeData buildTheme({bool dark = false, bool isMacOS = false}) {
  const seed = Color(0xFFF9CA24);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: isMacOS ? 48 : 56,
    ),
    extensions: [
      AppThemeExtension(
        cardAccent: seed,
        surfaceSoft: dark ? const Color(0xFF1E1E2E) : const Color(0xFFFDFDFD),
        cardRadius: isMacOS ? 10 : 12,
        platformPadding: isMacOS ? 16 : 20,
      ),
    ],
  );
}
