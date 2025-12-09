import 'package:flutter/material.dart';

/// Widget shimmer pour effet de chargement
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF23262E) : const Color(0xFFE0E0E0));
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF2E3440) : const Color(0xFFF5F5F5));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + (_animation.value * 0.2),
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Skeleton pour une carte du dashboard
class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerEffect(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23262E) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Cercle pour l'icône
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2E3440) : const Color(0xFFD0D0D0),
                ),
              ),
            ),
            // Barre pour le titre
            Positioned(
              bottom: 14,
              left: 14,
              right: 40,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3440) : const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille de skeleton pour le dashboard
class DashboardSkeletonGrid extends StatelessWidget {
  final int itemCount;
  final String? statusMessage;
  final String? deviceName;

  const DashboardSkeletonGrid({
    super.key,
    this.itemCount = 8,
    this.statusMessage,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF111318),
                  const Color(0xFF151922),
                  const Color(0xFF111318),
                ]
              : [
                  const Color(0xFFF5F7FA),
                  const Color(0xFFE8ECF2),
                  const Color(0xFFF0F4F8),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth > 600) crossAxisCount = 3;
          if (constraints.maxWidth > 900) crossAxisCount = 4;

          final padding = 24.0;
          final spacing = 24.0;
          final statusHeight = statusMessage != null ? 80.0 : 0.0;
          final availableWidth = constraints.maxWidth - (padding * 2);
          final availableHeight = constraints.maxHeight - (padding * 2) - statusHeight;
          final rows = (itemCount / crossAxisCount).ceil();

          final maxCardWidth =
              (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
          final maxCardHeight = (availableHeight - (spacing * (rows - 1))) / rows;
          final cardSize = maxCardWidth < maxCardHeight ? maxCardWidth : maxCardHeight;

          return Column(
            children: [
              // Grille de skeletons
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Center(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        itemCount,
                        (index) => SizedBox(
                          width: cardSize.clamp(120.0, 180.0),
                          height: cardSize.clamp(120.0, 180.0),
                          child: _AnimatedSkeletonCard(index: index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Message de statut
              if (statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _StatusIndicator(
                    message: statusMessage!,
                    deviceName: deviceName,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Indicateur de statut animé
class _StatusIndicator extends StatefulWidget {
  final String message;
  final String? deviceName;

  const _StatusIndicator({required this.message, this.deviceName});

  @override
  State<_StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<_StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicateur de progression animé
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = ((_controller.value + delay) % 1.0);
                    final opacity = (value < 0.5 ? value : 1.0 - value) * 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: 0.3 + (opacity * 0.7),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF5E92F3)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        if (widget.deviceName != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.deviceName!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Carte skeleton avec animation d'apparition décalée
class _AnimatedSkeletonCard extends StatefulWidget {
  final int index;

  const _AnimatedSkeletonCard({required this.index});

  @override
  State<_AnimatedSkeletonCard> createState() => _AnimatedSkeletonCardState();
}

class _AnimatedSkeletonCardState extends State<_AnimatedSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Délai décalé pour effet cascade
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: const DashboardCardSkeleton(),
    );
  }
}

/// Skeleton pour une ligne de liste
class ListItemSkeleton extends StatelessWidget {
  final bool showAvatar;
  final bool showSubtitle;

  const ListItemSkeleton({
    super.key,
    this.showAvatar = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF23262E) : const Color(0xFFE8E8E8);

    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showAvatar) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
