import 'package:flutter/material.dart';

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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
