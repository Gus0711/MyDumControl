import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// AppBar avec dégradé pour un style professionnel cohérent
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const GradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: elevation,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        bottom: bottom,
      ),
    );
  }
}
