import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'models/category.dart';
import 'models/time_period.dart';
import 'models/notification_rule.dart';
import 'db/hive_boxes.dart';
import 'db/repositories.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TimePeriodAdapter());
  Hive.registerAdapter(NotificationRuleAdapter());

  // Open boxes
  await openHiveBoxes();
  await NotificationService.instance.initialize();

  runApp(const ProjectLifeApp());
}

class ProjectLifeApp extends StatelessWidget {
  const ProjectLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for theme changes in settings box
    return ValueListenableBuilder(
      valueListenable: Hive.box(settingsBoxName).listenable(),
      builder: (context, box, _) {
        final settings = SettingsRepository();
        final themeMode = settings.getThemeMode();

        return MaterialApp(
          title: 'Project: Life',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _getThemeMode(themeMode),
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
