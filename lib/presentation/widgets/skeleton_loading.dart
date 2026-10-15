import 'package:flutter/material.dart';

import '../../core/theme/dc_tokens.dart';

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
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
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
    final dc = context.dc;
    final baseColor = widget.baseColor ?? dc.surfaceSunken;
    final highlightColor = widget.highlightColor ??
        Color.lerp(dc.surfaceSunken, dc.borderStrong, dc.isDark ? 0.55 : 0.35)!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.5, 0.65],
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

/// Bloc gris arrondi (ligne de texte, icône…) d'un squelette.
class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _Bone({this.width, required this.height, this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.dc.surfaceSunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Cadre de carte (surface + bordure) contenant des os de squelette.
class _SkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SkeletonCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dc.surface,
        borderRadius: BorderRadius.circular(DcRadius.lg),
        border: Border.all(color: dc.border),
      ),
      child: child,
    );
  }
}

/// Skeleton d'une tuile de module de l'accueil
class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      child: ShimmerEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Bone(width: 44, height: 44, radius: 12),
            SizedBox(height: 16),
            _Bone(width: 110, height: 14),
            SizedBox(height: 8),
            _Bone(height: 10),
            SizedBox(height: 5),
            _Bone(width: 140, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Squelette de l'accueil d'un automate pendant la connexion : reprend la
/// mise en page de l'accueil (en-tête, indicateurs, modules).
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
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth) - 40;
              final kpiColumns = width >= 860 ? 4 : 2;
              final moduleColumns = width >= 1000 ? 4 : (width >= 640 ? 3 : (width >= 380 ? 2 : 1));
              const spacing = 14.0;
              final kpiWidth = (width - spacing * (kpiColumns - 1)) / kpiColumns;
              final moduleWidth = (width - spacing * (moduleColumns - 1)) / moduleColumns;

              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: DcSpace.contentMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête de l'automate
                          const _SkeletonCard(
                            padding: EdgeInsets.all(18),
                            child: ShimmerEffect(
                              child: Row(
                                children: [
                                  _Bone(width: 56, height: 56, radius: 16),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _Bone(width: 220, height: 20, radius: 5),
                                        SizedBox(height: 14),
                                        Row(
                                          children: [
                                            _Bone(width: 130, height: 20, radius: 6),
                                            SizedBox(width: 6),
                                            _Bone(width: 110, height: 20, radius: 6),
                                            SizedBox(width: 6),
                                            _Bone(width: 60, height: 20, radius: 6),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: spacing),
                          // Indicateurs
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: List.generate(
                              4,
                              (_) => SizedBox(
                                width: kpiWidth,
                                child: const _SkeletonCard(
                                  padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: ShimmerEffect(
                                    child: Row(
                                      children: [
                                        _Bone(width: 36, height: 36, radius: 10),
                                        SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _Bone(width: 48, height: 20, radius: 5),
                                            SizedBox(height: 6),
                                            _Bone(width: 80, height: 10),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _Bone(width: 70, height: 10),
                          const SizedBox(height: 14),
                          // Modules
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: List.generate(
                              itemCount,
                              (index) => SizedBox(
                                width: moduleWidth,
                                child: _AnimatedSkeletonCard(index: index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Message de statut
        if (statusMessage != null)
          _StatusIndicator(
            message: statusMessage!,
            deviceName: deviceName,
          ),
      ],
    );
  }
}

/// Barre de statut de la connexion (progression + message + automate)
class _StatusIndicator extends StatelessWidget {
  final String message;
  final String? deviceName;

  const _StatusIndicator({required this.message, this.deviceName});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(top: BorderSide(color: dc.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: dc.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (deviceName != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('·', style: textTheme.bodyMedium?.copyWith(color: dc.textMuted)),
                  ),
                  Flexible(
                    child: Text(
                      deviceName!,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: dc.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
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
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showAvatar) ...[
              const _Bone(width: 40, height: 40, radius: 10),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Bone(width: double.infinity, height: 14),
                  if (showSubtitle) ...[
                    const SizedBox(height: 8),
                    const _Bone(width: 150, height: 12),
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
