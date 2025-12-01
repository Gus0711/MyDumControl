import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget d'overlay de chargement avec animation élégante
/// Affiche une animation de connexion avec des étapes progressives
class ConnectionLoadingOverlay extends StatefulWidget {
  final String? message;
  final String? subMessage;
  final bool showSteps;
  final int currentStep;

  const ConnectionLoadingOverlay({
    super.key,
    this.message,
    this.subMessage,
    this.showSteps = true,
    this.currentStep = 0,
  });

  @override
  State<ConnectionLoadingOverlay> createState() => _ConnectionLoadingOverlayState();
}

class _ConnectionLoadingOverlayState extends State<ConnectionLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour le cercle extérieur
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de rotation pour l'icône
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Animation pour les points de chargement
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.black.withAlpha(200)
          : Colors.white.withAlpha(230),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation principale
            _buildMainAnimation(theme),
            const SizedBox(height: 32),

            // Message principal
            Text(
              widget.message ?? 'Connexion en cours',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // Points de chargement animés
            _buildAnimatedDots(theme),

            const SizedBox(height: 16),

            // Sous-message ou étapes
            if (widget.subMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.subMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (widget.showSteps) ...[
              const SizedBox(height: 24),
              _buildProgressSteps(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainAnimation(ThemeData theme) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle externe pulsant
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(60),
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),

          // Cercle intermédiaire avec gradient rotatif
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        theme.colorScheme.primary.withAlpha(0),
                        theme.colorScheme.primary.withAlpha(100),
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(100),
                        theme.colorScheme.primary.withAlpha(0),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              );
            },
          ),

          // Icône centrale
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(40),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.settings_remote,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots(ThemeData theme) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_dotsController.value + delay) % 1.0;
            final opacity = (math.sin(value * math.pi)).clamp(0.3, 1.0);
            final scale = 0.6 + (0.4 * math.sin(value * math.pi));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withAlpha((opacity * 255).toInt()),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgressSteps(ThemeData theme) {
    final steps = [
      ('Connexion', Icons.wifi),
      ('Authentification', Icons.lock_open),
      ('Données', Icons.cloud_download),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Ligne entre les étapes
            final stepIndex = index ~/ 2;
            final isCompleted = widget.currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(50),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          // Étape
          final stepIndex = index ~/ 2;
          final step = steps[stepIndex];
          final isActive = widget.currentStep == stepIndex;
          final isCompleted = widget.currentStep > stepIndex;

          return _buildStepIndicator(
            theme,
            icon: step.$2,
            label: step.$1,
            isActive: isActive,
            isCompleted: isCompleted,
          );
        }),
      ),
    );
  }

  Widget _buildStepIndicator(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      backgroundColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.onPrimary;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.primary;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      iconColor = theme.colorScheme.outline;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(60),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
