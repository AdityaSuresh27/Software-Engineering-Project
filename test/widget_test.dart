import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:classflow/main.dart';
import 'package:classflow/frontend/theme_provider.dart';
import 'package:classflow/backend/data_provider.dart';

void main() {
  testWidgets('ClassFlow app builds successfully', (WidgetTester tester) async {
    // Build app with same providers as main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => DataProvider()),
        ],
        child: const ClassFlowApp(),
      ),
    );

    // Initial frame
    await tester.pump();

    // ⬇️ VERY IMPORTANT ⬇️
    // SplashScreen uses a 2.5s Timer
    // Advance fake time so timer finishes
    await tester.pump(const Duration(seconds: 3));

    // Settle remaining frames
    await tester.pumpAndSettle();

    // Assertions
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
