// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'onboarding_screen.dart';
import 'main_navigation.dart';
import '../backend/data_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Logo animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;

  // Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  // Letter animations — "ClassFlow" = 9 chars
  late List<AnimationController> _letterControllers;
  late List<Animation<Offset>> _letterOffsets;
  late List<Animation<double>> _letterOpacities;

  // Tagline
  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  // Particles
  late AnimationController _particleController;

  // Exit fade
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;

  // Floating orbs
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;

  static const String _word = 'ClassFlow';

  // Random entry directions for each letter
  final List<Offset> _letterStartOffsets = [
    const Offset(-3.0, -2.0), // C
    const Offset(0.0, -3.5),  // l
    const Offset(2.5, -1.5),  // a
    const Offset(-2.0, 2.5),  // s
    const Offset(3.0, 1.0),   // s
    const Offset(-1.5, 3.0),  // F
    const Offset(1.0, -2.5),  // l
    const Offset(2.8, 2.0),   // o
    const Offset(-2.5, -1.0), // w
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Glow pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 60.0, end: 110.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Letters
    _letterControllers = List.generate(
      _word.length,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );
    _letterOffsets = List.generate(_word.length, (i) {
      return Tween<Offset>(
        begin: _letterStartOffsets[i],
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _letterControllers[i],
        curve: Curves.elasticOut,
      ));
    });
    _letterOpacities = List.generate(_word.length, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _letterControllers[i],
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ),
      );
    });

    // Tagline
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    // Particles
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Exit
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    // Floating orbs
    _orb1Controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    )..repeat(reverse: true);
    _orb2Controller = AnimationController(
      duration: const Duration(milliseconds: 2700),
      vsync: this,
    )..repeat(reverse: true);
    _orb3Controller = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _startSequence() async {
    // Play audio immediately if not muted
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (!dataProvider.muteStartupSound) {
      () async {
        try {
          await _audioPlayer.play(AssetSource('startup.mp3'));
        } catch (e) {
          debugPrint('Audio error: $e');
        }
      }();
    }

    // Logo pops in
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Letters fly in staggered
    await Future.delayed(const Duration(milliseconds: 700));
    for (int i = 0; i < _word.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      _letterControllers[i].forward();
    }

    // Tagline slides up
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    // Navigate
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 4000)),
      dataProvider.ready,
    ]);

    if (!mounted) return;

    // Fade out everything
    await _exitController.forward();

    if (!mounted) return;

    await _audioPlayer.stop();

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
    _logoController.dispose();
    _glowController.dispose();
    for (final c in _letterControllers) {
      c.dispose();
    }
    _taglineController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    Future.delayed(const Duration(seconds: 3), () => _audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: primary,
        body: Stack(
          children: [
            // Background gradient layers
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    Color.lerp(primary, Colors.black, 0.3)!,
                  ],
                ),
              ),
            ),

            // Floating orbs background
            _buildFloatingOrb(
              controller: _orb1Controller,
              begin: Offset(size.width * 0.1, size.height * 0.1),
              end: Offset(size.width * 0.25, size.height * 0.2),
              radius: 140,
              opacity: 0.12,
            ),
            _buildFloatingOrb(
              controller: _orb2Controller,
              begin: Offset(size.width * 0.7, size.height * 0.7),
              end: Offset(size.width * 0.85, size.height * 0.6),
              radius: 180,
              opacity: 0.09,
            ),
            _buildFloatingOrb(
              controller: _orb3Controller,
              begin: Offset(size.width * 0.8, size.height * 0.1),
              end: Offset(size.width * 0.65, size.height * 0.18),
              radius: 100,
              opacity: 0.10,
            ),

            // Particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(_particleController.value),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _glowController]),
                    builder: (context, _) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotate.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow
                                Container(
                                  width: _glowRadius.value * 2.8,
                                  height: _glowRadius.value * 2.8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.15),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                // Inner glow ring
                                Container(
                                  width: 320,
                                  height: 320,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        blurRadius: _glowRadius.value,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                // Logo container
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 40,
                                        offset: const Offset(0, 16),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Image.asset(
                                      'lib/assets/selogo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.school,
                                          size: 80,
                                          color: Color(0xFF2563EB),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Animated letters
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_word.length, (i) {
                      final isUpperFirst = i == 0; // C
                      final isUpperSecond = i == 5; // F
                      return AnimatedBuilder(
                        animation: _letterControllers[i],
                        builder: (context, _) {
                          return SlideTransition(
                            position: _letterOffsets[i],
                            child: Opacity(
                              opacity: _letterOpacities[i].value,
                              child: Text(
                                _word[i],
                                style: TextStyle(
                                  fontSize: (isUpperFirst || isUpperSecond) ? 46 : 40,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  // Tagline
                  AnimatedBuilder(
                    animation: _taglineController,
                    builder: (context, _) {
                      return ClipRect(
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: Opacity(
                            opacity: _taglineOpacity.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 1.5,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Academic Planning Made Simple',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 28,
                                  height: 1.5,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb({
    required AnimationController controller,
    required Offset begin,
    required Offset end,
    required double radius,
    required double opacity,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final x = begin.dx + (end.dx - begin.dx) * t;
        final y = begin.dy + (end.dy - begin.dy) * t;
        return Positioned(
          left: x - radius,
          top: y - radius,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = _generateParticles();

  _ParticlePainter(this.progress);

  static List<_Particle> _generateParticles() {
    final rng = math.Random(42);
    return List.generate(22, (i) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1,
        speed: rng.nextDouble() * 0.3 + 0.1,
        phase: rng.nextDouble(),
        amplitude: rng.nextDouble() * 0.04 + 0.01,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = (p.x + math.sin(t * math.pi * 2) * p.amplitude) * size.width;
      final y = (1.0 - t) * size.height * 0.8 + size.height * 0.1;
      final opacity = math.sin(t * math.pi) * 0.5;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase, amplitude;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.amplitude,
  });
}
