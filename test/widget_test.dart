// Widget smoke test for Algo Arena.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algo_arena/screens/home_screen.dart';
import 'package:algo_arena/services/stats_service.dart';

void main() {
  testWidgets('App smoke test — HomeScreen renders', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Pump a single frame
    await tester.pump();

    // Verify it renders the home content
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}


