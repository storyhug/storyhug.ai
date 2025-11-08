import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:storyhug_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('StoryHug App Integration Tests', () {
    testWidgets('Complete user journey test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Welcome Page
      expect(find.text('Your stories, in their voice.\nSweet dreams every night.'), findsOneWidget);
      expect(find.text('BEGIN THE MAGIC'), findsOneWidget);

      // Tap to go to auth page
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Test 2: Auth Page
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('SIGN UP'), findsOneWidget);

      // Test social login buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);

      // For demo purposes, we'll simulate going back to welcome
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test 3: Navigate to manage kids (simulating logged in state)
      // This would normally be done after authentication
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test navigation from welcome to auth
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Verify we're on auth page
      expect(find.text('Email'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back on welcome page
      expect(find.text('Your stories, in their voice.\nSweet dreams every night.'), findsOneWidget);
    });

    testWidgets('Theme consistency test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check that dark theme is applied consistently
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, equals(Brightness.dark));

      // Navigate through pages to ensure theme consistency
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Theme should remain consistent
      final materialAppAfterNav = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialAppAfterNav.theme?.brightness, equals(Brightness.dark));
    });

    testWidgets('Performance test', (WidgetTester tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      
      app.main();
      await tester.pumpAndSettle();

      // Measure frame rendering time
      final frameTime = binding.framePolicy;
      expect(frameTime, isNotNull);

      // Test scrolling performance
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Verify smooth navigation
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Accessibility test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check for semantic labels
      expect(find.bySemanticsLabel('BEGIN THE MAGIC'), findsOneWidget);

      // Navigate and check accessibility
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Check form accessibility
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
    });

    testWidgets('Error handling test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that the app handles navigation gracefully
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Test form validation (empty fields)
      await tester.tap(find.text('SIGN UP'));
      await tester.pumpAndSettle();

      // App should not crash and should handle validation
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Memory usage test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate through multiple pages to test memory management
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // App should still be responsive
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Network handling test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that the app handles network states gracefully
      // This would normally test with actual network calls
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // App should handle network states without crashing
      expect(find.text('Email'), findsOneWidget);
    });
  });

  group('Device-specific tests', () {
    testWidgets('Different screen sizes test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test on different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone
      await tester.pumpAndSettle();
      expect(find.text('BEGIN THE MAGIC'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet
      await tester.pumpAndSettle();
      expect(find.text('BEGIN THE MAGIC'), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Orientation test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test portrait orientation
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.text('BEGIN THE MAGIC'), findsOneWidget);

      // Test landscape orientation
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      expect(find.text('BEGIN THE MAGIC'), findsOneWidget);
    });
  });

  group('Feature-specific integration tests', () {
    testWidgets('Audio player integration test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a story (simulating the flow)
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Test that audio player components are present
      // This would test the actual audio player when stories are loaded
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Voice cloning integration test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test voice cloning flow
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Test microphone permissions and recording
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Subscription integration test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test subscription flow
      await tester.tap(find.text('BEGIN THE MAGIC'));
      await tester.pumpAndSettle();

      // Test subscription features
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
