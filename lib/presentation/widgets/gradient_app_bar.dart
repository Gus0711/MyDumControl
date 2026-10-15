import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Barre d'application de l'app : bleu nuit, filet de marque bleu → orange,
/// titre et sous-titre optionnel. Identique en thème clair et sombre.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;

  /// Ligne secondaire sous le titre (adresse, nombre d'éléments…).
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const GradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation = 0,
  });

  static const double _lineHeight = 1.5;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0) + _lineHeight,
      );

  @override
  Widget build(BuildContext context) {
    Widget? titleChild = titleWidget;
    if (titleChild == null && title != null) {
      titleChild = subtitle == null
          ? Text(title!, overflow: TextOverflow.ellipsis)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title!, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9FB2CC),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: titleChild,
            actions: actions == null ? null : [...actions!, const SizedBox(width: 6)],
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: elevation,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            bottom: bottom,
          ),
          Container(
            height: _lineHeight,
            decoration: const BoxDecoration(gradient: AppColors.brandLine),
          ),
        ],
      ),
    );
  }
}
