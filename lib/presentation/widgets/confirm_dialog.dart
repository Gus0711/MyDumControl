import 'package:flutter/material.dart';

import '../../core/theme/dc_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Simple confirmation dialog (Cancel / [confirmLabel]).
/// Returns true only when the user confirms. [destructive] shows the
/// confirm button in red (deletions).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final dc = context.dc;
      return AlertDialog(
        icon: destructive
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dc.danger.bg,
                  border: Border.all(color: dc.danger.border),
                ),
                child: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
              )
            : null,
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: dc.danger.fg,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result == true;
}
