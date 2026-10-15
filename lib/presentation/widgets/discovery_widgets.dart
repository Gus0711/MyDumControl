import 'package:flutter/material.dart';

import 'ui/ui.dart';

/// En-tête des écrans de découverte réseau : icône animée pendant la
/// recherche, titre, explication, compteur et barre de progression.
class DiscoveryHeader extends StatelessWidget {
  final IconData icon;
  final DcTone tone;
  final String title;
  final String subtitle;
  final bool scanning;

  /// Compteur affiché à droite (« 5 appareils »), null pour le masquer.
  final String? countLabel;

  /// Contenu additionnel sous le texte (options de recherche…).
  final Widget? child;

  const DiscoveryHeader({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.scanning,
    this.countLabel,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return DcCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _PulsingIcon(icon: icon, tone: tone, active: scanning),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.titleMedium),
                          const SizedBox(height: 3),
                          Text(subtitle, style: context.text.bodySmall?.copyWith(color: dc.textSecondary)),
                        ],
                      ),
                    ),
                    if (countLabel != null) ...[
                      const SizedBox(width: 12),
                      DcTag(countLabel!, tone: scanning ? dc.neutral : tone),
                    ],
                  ],
                ),
                ?child,
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: scanning
                ? LinearProgressIndicator(color: tone.fg, backgroundColor: Colors.transparent)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final DcTone tone;
  final bool active;

  const _PulsingIcon({required this.icon, required this.tone, required this.active});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tone;
    return SizedBox(
      width: 52,
      height: 52,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final v = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Container(
                  width: 52 + 10 * v,
                  height: 52 + 10 * v,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 + 3 * v),
                    border: Border.all(color: t.fg.withValues(alpha: 0.45 * (1 - v)), width: 2),
                  ),
                ),
              child!,
            ],
          );
        },
        child: DcIconBox(icon: widget.icon, tone: t, size: 52),
      ),
    );
  }
}

/// Grille responsive de cartes d'appareils (1 à 3 colonnes).
class DiscoveryGrid extends StatelessWidget {
  final List<Widget> children;

  const DiscoveryGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050 ? 3 : (constraints.maxWidth >= 680 ? 2 : 1);
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}
