import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storyhug_app/main.dart';
import 'package:storyhug_app/core/theme/app_theme.dart';

void main() {
  group('StoryHug App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const StoryHugApp());

      // Verify that the app builds without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Theme should be applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const StoryHugApp());

      // Check that the theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, equals(AppTheme.darkTheme));
    });

    testWidgets('App should have proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(const StoryHugApp());

      // Check that the app has the basic structure
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    test('should have correct color scheme', () {
      final theme = AppTheme.darkTheme;
      
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.primaryColor, equals(AppTheme.primaryColor));
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.surfaceColor));
    });

    test('should have correct text theme', () {
      final theme = AppTheme.darkTheme;
      
      expect(theme.textTheme.headlineLarge?.fontSize, equals(22));
      expect(theme.textTheme.bodyLarge?.fontSize, equals(16));
      expect(theme.textTheme.labelLarge?.fontSize, equals(14));
    });
  });
}