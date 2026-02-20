//main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'frontend/splash_screen.dart';
import 'frontend/theme.dart';
import 'frontend/theme_provider.dart';
import 'backend/data_provider.dart';
import 'backend/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const ClassFlowApp(),
    ),
  );
}

// Global key so notification taps can navigate without a BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class ClassFlowApp extends StatelessWidget {
  const ClassFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ClassFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          navigatorKey: navigatorKey,
        );
      },
    );
  }
}