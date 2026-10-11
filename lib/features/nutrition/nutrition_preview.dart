import 'package:flutter/material.dart';
import 'presentation/nutrition_navigation_screen.dart';

/// Standalone test runner for the Nutrition & Suivi module.
/// Run with:
///   flutter run -t lib/features/nutrition/nutrition_preview.dart -d edge
///   or
///   flutter run -t lib/features/nutrition/nutrition_preview.dart -d windows
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutritionAppPreview());
}

class NutritionAppPreview extends StatelessWidget {
  const NutritionAppPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife - Nutrition & Suivi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      home: const NutritionNavigationScreen(),
    );
  }
}
