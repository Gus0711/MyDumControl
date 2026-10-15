import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/database/tables/dashboard_tables.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/ui/ui.dart';

/// Dialogue pour ajouter un nouveau widget au dashboard
class AddWidgetDialog extends StatelessWidget {
  const AddWidgetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;

    void pick(DashboardWidgetType type) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop({
        'type': type,
        'config': null,
      });
    }

    return AlertDialog(
      icon: const Icon(Icons.add_chart_rounded),
      title: Text(l10n.addWidget),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WidgetTypeOption(
              icon: Icons.show_chart_rounded,
              title: l10n.singleChart,
              description: l10n.singleChartDescription,
              tone: dc.accentTone,
              onTap: () => pick(DashboardWidgetType.singleTrendChart),
            ),
            const SizedBox(height: 10),
            _WidgetTypeOption(
              icon: Icons.stacked_line_chart_rounded,
              title: l10n.multiCurveChart,
              description: l10n.multiCurveChartDescription,
              tone: dc.violet,
              onTap: () => pick(DashboardWidgetType.multiCurveChart),
            ),
            const SizedBox(height: 10),
            _WidgetTypeOption(
              icon: Icons.analytics_outlined,
              title: l10n.statsCard,
              description: l10n.statsCardDescription,
              tone: dc.success,
              onTap: () => pick(DashboardWidgetType.statsCard),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _WidgetTypeOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final DcTone tone;
  final VoidCallback onTap;

  const _WidgetTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
    required this.onTap,
  });

  @override
  State<_WidgetTypeOption> createState() => _WidgetTypeOptionState();
}

class _WidgetTypeOptionState extends State<_WidgetTypeOption> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return DcCard(
      onTap: widget.onTap,
      color: dc.surfaceSunken,
      borderColor: _hover ? widget.tone.border : null,
      padding: const EdgeInsets.all(14),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Row(
          children: [
            DcIconBox(icon: widget.icon, tone: widget.tone, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: _hover ? widget.tone.fg : dc.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
