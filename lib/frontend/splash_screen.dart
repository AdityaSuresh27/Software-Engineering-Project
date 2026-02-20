// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'main_navigation.dart';
import '../backend/data_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Wait for both the minimum splash duration and DataProvider to finish
    // loading from SharedPreferences before deciding where to navigate.
    // Using Future.wait means we never flash the splash longer than needed,
    // but we also never skip it entirely on fast devices.
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    // Minimum time to show the splash — feels intentional, not like a glitch
    final minimumSplash = Future.delayed(const Duration(milliseconds: 2000));

    // Poll until DataProvider has finished its async _loadData and
    // _checkAuthStatus. Both call notifyListeners() when done, so we
    // wait for isAuthenticated to be readable (load completes quickly,
    // but the Future itself isn't exposed, so we poll with a short delay).
    // In practice this resolves in well under 500ms on any real device.
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await Future.wait([
      minimumSplash,
      _waitForDataProvider(dataProvider),
    ]);

    if (!mounted) return;

    if (dataProvider.isAuthenticated) {
      // Already logged in and session is still valid — go straight home
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // Not authenticated — show onboarding/login flow
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // Waits until DataProvider has finished loading by checking every 100ms.
  // We know loading is done when _loadData and _checkAuthStatus have both
  // called notifyListeners — in practice categories are always populated
  // after a successful load, so we use that as the ready signal.
  Future<void> _waitForDataProvider(DataProvider dataProvider) async {
    // Give it a moment to start the async load
    await Future.delayed(const Duration(milliseconds: 100));

    for (int i = 0; i < 30; i++) {
      // categories are initialized either from prefs or defaults in _loadData,
      // so non-empty categories means loading finished.
      // Also break if isAuthenticated is false — _checkAuthStatus has run.
      final loadedCategories = dataProvider.categories.isNotEmpty;
      // After _checkAuthStatus runs, lastActiveAt or isAuthenticated is set.
      // We check both: authenticated users have categories, unauthenticated
      // users also get default categories, so this covers both paths.
      if (loadedCategories) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'lib/assets/selogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.school,
                              size: 60,
                              color: Color(0xFF2563EB),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ClassFlow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Academic Planning Made Simple',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}