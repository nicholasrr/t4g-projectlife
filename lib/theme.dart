import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      background: const Color(0xFFF5F5F5), // off-white
      surface: Colors.white,
      onSurface: Colors.grey[850]!, // dark grey text
      primary: Colors.deepPurple,
      secondary: Colors.deepPurple[300]!,
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[850],
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey[600],
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      background: const Color(0xFF303030), // dark grey
      surface: const Color(0xFF424242), // slightly lighter grey
      onSurface: Colors.white,
      primary: Colors.deepPurple,
      secondary: Colors.deepPurple[200]!,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF303030),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF303030),
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF424242),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  /// Returns a color with reduced opacity for completed tasks
  static Color withCompletedOpacity(Color color) {
    return color.withOpacity(0.6);
  }

  /// Returns a smaller elevation for completed tasks
  static double get completedElevation => 1.0;

  /// Common spacing values for consistent layout
  static const double spacing = 8.0;
  static const double padding = 16.0;
  static const double radius = 12.0;

  /// Size proportions (multiply by screen size)
  static const double buttonHeightRatio = 0.08; // 8% of screen height
  static const double taskCardHeightRatio = 0.12; // 12% of screen height
  static const double bottomBarHeightRatio = 0.1; // 10% of screen height

  /// Icons
  static const IconData filterIcon = Icons.filter_list;
  static const IconData filterActiveIcon = Icons.filter_list_sharp;
  static const IconData recurringIcon = Icons.replay;
  static const IconData adhocIcon = Icons.check;
  static const IconData helpIcon = Icons.help_outline;
  static const IconData settingsIcon = Icons.settings;
  static const IconData addIcon = Icons.add;
  static const IconData deleteIcon = Icons.delete;
  static const IconData completeIcon = Icons.check_circle;
  static const IconData categoryIcon = Icons.label;
  static const IconData engineIcon = Icons.build;
}
