import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Écran de démarrage de l'application
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _progress = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _initializeAndNavigate();
  }

  Timer? _minDelayTimer;

  @override
  void dispose() {
    _minDelayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    // Real init (settings storage) + a short minimum delay for the animation
    final minDelay = Completer<void>();
    _minDelayTimer = Timer(const Duration(milliseconds: 1000), minDelay.complete);
    await Future.wait([SharedPreferences.getInstance(), minDelay.future]);

    if (mounted) {
      context.go(Routes.connections);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mutedOnNavy = Color(0xFF9FB2CC);

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientEnd, AppColors.gradientStart, Color(0xFF070E1A)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Halos de marque (bleu ciel en haut, orange en bas)
            Positioned(
              top: -160,
              right: -120,
              child: _Glow(color: AppColors.brandSky.withValues(alpha: 0.16), size: 440),
            ),
            Positioned(
              bottom: -200,
              left: -140,
              child: _Glow(color: AppColors.brandOrange.withValues(alpha: 0.10), size: 480),
            ),
            // Contenu principal
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo avec halo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandSky.withValues(alpha: 0.28),
                              blurRadius: 70,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logov2_no_back.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          // Nom de l'application
                          const Text(
                            'MyGlobalDC',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Sous-titre
                          Text(
                            'ECLYPSE · BACNET CONTROLLER MANAGEMENT',
                            style: AppTextStyles.overline.copyWith(
                              fontFamily: AppTextStyles.fontFamily,
                              color: mutedOnNavy,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Progression discrète
                  SizedBox(
                    width: 160,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => Stack(
                          children: [
                            Container(color: Colors.white.withValues(alpha: 0.08)),
                            FractionallySizedBox(
                              widthFactor: _progress.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.brandSky, AppColors.brandViolet, AppColors.brandOrange],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Version en bas
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.monospacedValue.copyWith(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halo radial décoratif.
class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
