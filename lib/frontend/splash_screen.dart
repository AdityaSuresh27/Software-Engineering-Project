// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'main_navigation.dart';
import '../backend/data_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    () async {
      try {
        await _audioPlayer.play(AssetSource('startup.mp3'));
      } catch (e) {
        print('>>> Audio error: $e');
      }
    }();

    // Wait for both the minimum splash duration and DataProvider to finish
    // loading from SharedPreferences before deciding where to navigate.
    // Using Future.wait means we never flash the splash longer than needed,
    // but we also never skip it entirely on fast devices.
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    // Wait for both the minimum splash duration AND DataProvider to fully
    // finish loading from SharedPreferences (including _checkAuthStatus).
    // dataProvider.ready is a Completer that resolves only after both
    // _loadData() and _checkAuthStatus() have completed, so isAuthenticated
    // is guaranteed to reflect the persisted value by the time we read it.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 4000)),
      dataProvider.ready,
    ]);

    if (!mounted) return;

    if (dataProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
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

  @override
void dispose() {
  _controller.dispose();
  // Don't dispose audioPlayer immediately - let it finish playing
  Future.delayed(const Duration(seconds: 6), () {
    _audioPlayer.dispose();
  });
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