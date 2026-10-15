import 'package:flutter/material.dart';

import '../../../core/theme/dc_tokens.dart';

/// État vide / erreur / information pleine page : icône, titre, message, action.
class DcEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Widget? secondaryAction;
  final DcTone? tone;

  const DcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.tone,
  });

  /// Variante erreur (ton danger).
  factory DcEmptyState.error(
    BuildContext context, {
    Key? key,
    IconData icon = Icons.error_outline_rounded,
    required String title,
    String? message,
    Widget? action,
    Widget? secondaryAction,
  }) =>
      DcEmptyState(
        key: key,
        icon: icon,
        title: title,
        message: message,
        action: action,
        secondaryAction: secondaryAction,
        tone: context.dc.danger,
      );

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.neutral;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.bg,
                  border: Border.all(color: t.border),
                ),
                child: Icon(icon, size: 34, color: t.fg),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(color: dc.textPrimary),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: dc.textSecondary),
                ),
              ],
              if (action != null || secondaryAction != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [?action, ?secondaryAction],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur de chargement centré avec message optionnel.
class DcLoading extends StatelessWidget {
  final String? message;

  const DcLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: dc.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
