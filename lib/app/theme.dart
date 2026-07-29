import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;

  static ThemeData get darkTheme => ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(
        0xFFE11D48,
      ), //navigator barda secili olananin rengi ve ayarlar carkinin rengi
      secondary: Color(0xFF1E293B), //card/button rengi
      surface: Color(0xFF0F172A), // yuzey rengi
      tertiary: Color(0xFFF8FAFC), //metin renkleri
      onSecondary: Color(0xFFBE123C), // fav kalbi isaretlendindeki ici
      onTertiary: Color(
        0xFF94A3B8,
      ), // yardimci metinler (search bar hint i gibi)
      errorContainer: Color(0xFF10B981), //olumlu snack bar rengi
      error: Color(0xFFFF0000), //hata mesajlarinin rengi
    ),
  );
}
