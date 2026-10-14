import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/database/tables/dashboard_tables.dart';
import '../../../../l10n/app_localizations.dart';

/// Dialogue pour ajouter un nouveau widget au dashboard
class AddWidgetDialog extends StatelessWidget {
  const AddWidgetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addWidget),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WidgetTypeOption(
              icon: Icons.show_chart,
              title: l10n.singleChart,
              description: l10n.singleChartDescription,
              color: Colors.blue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop({
                  'type': DashboardWidgetType.singleTrendChart,
                  'config': null,
                });
              },
            ),
            const SizedBox(height: 12),
            _WidgetTypeOption(
              icon: Icons.multiline_chart,
              title: l10n.multiCurveChart,
              description: l10n.multiCurveChartDescription,
              color: Colors.purple,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop({
                  'type': DashboardWidgetType.multiCurveChart,
                  'config': null,
                });
              },
            ),
            const SizedBox(height: 12),
            _WidgetTypeOption(
              icon: Icons.analytics,
              title: l10n.statsCard,
              description: l10n.statsCardDescription,
              color: Colors.teal,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop({
                  'type': DashboardWidgetType.statsCard,
                  'config': null,
                });
              },
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

class _WidgetTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _WidgetTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(50)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
