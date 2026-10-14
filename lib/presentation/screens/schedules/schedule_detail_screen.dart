import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/schedule_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../domain/models/schedule.dart';
import 'widgets/schedule_dialogs.dart';
import 'widgets/schedule_colors.dart';
import 'widgets/vertical_day_schedule_view.dart';
import '../../../l10n/app_localizations.dart';

/// Écran de détail d'un schedule avec vue hebdomadaire et mode édition
class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final int instance;

  const ScheduleDetailScreen({
    super.key,
    required this.instance,
  });

  @override
  ConsumerState<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
  WeekDay? _selectedDay;
  bool _isEditing = false;

  @override
  void dispose() {
    // Note: Ne pas utiliser ref.read() dans dispose() car le widget est déjà disposé
    // Le reset sera fait automatiquement si nécessaire lors du prochain chargement
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleDetailProvider(widget.instance));
    final editState = ref.watch(scheduleEditProvider);
    // Rebuild the times when the 12/24 h setting changes
    ref.watch(settingsProvider.select((s) => s.use24HourFormat));

    // Écouter les messages de succès/erreur
    ref.listen(scheduleEditProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(scheduleEditProvider.notifier).clearSuccess();
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(scheduleEditProvider.notifier).clearError();
      }
    });

    return PopScope(
      canPop: !_isEditing || !editState.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isEditing && editState.hasChanges) {
          final discard = await showDialog<bool>(
            context: context,
            builder: (context) => const DiscardChangesDialog(),
          );
          if (discard == true && context.mounted) {
            ref.read(scheduleEditProvider.notifier).revert();
            setState(() => _isEditing = false);
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(scheduleAsync, editState),
        body: scheduleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(context, error),
          data: (schedule) {
            if (schedule == null) return _buildNotFound(context);

            // Utiliser le schedule édité si en mode édition (et seulement s'il
            // s'agit bien de ce planning)
            final edited = editState.editedSchedule;
            final displaySchedule =
                _isEditing && edited != null && edited.instance == widget.instance
                    ? edited
                    : schedule;

            return _ScheduleDetailContent(
              schedule: displaySchedule,
              isEditing: _isEditing,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() {
                _selectedDay = _selectedDay == day ? null : day;
              }),
            );
          },
        ),
        floatingActionButton: _buildFab(editState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<Schedule?> scheduleAsync,
    ScheduleEditState editState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: scheduleAsync.when(
        loading: () => Text(l10n.loadingEllipsis),
        error: (_, __) => Text(l10n.error),
        data: (schedule) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule?.objectName ?? l10n.scheduleInstance(widget.instance.toString()),
              style: const TextStyle(fontSize: 18),
            ),
            if (_isEditing)
              Text(
                editState.hasChanges ? l10n.modified : l10n.editMode,
                style: TextStyle(
                  fontSize: 12,
                  color: editState.hasChanges
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_isEditing) ...[
          // Bouton annuler les modifications
          if (editState.hasChanges)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: l10n.cancelChanges,
              onPressed: () {
                ref.read(scheduleEditProvider.notifier).revert();
              },
            ),
          // Bouton sauvegarder
          IconButton(
            icon: editState.isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: l10n.saveChanges,
            onPressed: editState.hasChanges && !editState.isSaving
                ? () => _handleSave()
                : null,
          ),
          // Bouton fermer l'édition
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.closeEdit,
            onPressed: () => _handleCloseEdit(),
          ),
        ] else ...[
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () {
              // Single read: the edit state is loaded only when entering edit mode
              ref.invalidate(scheduleDetailProvider(widget.instance));
            },
          ),
        ],
      ],
    );
  }

  Future<void> _startEditing() async {
    // The edit state is loaded lazily (the read-only view uses scheduleDetailProvider)
    final notifier = ref.read(scheduleEditProvider.notifier);
    final loaded = ref.read(scheduleDetailProvider(widget.instance)).valueOrNull;
    if (loaded != null) {
      // Already read for the view: no controller access
      notifier.loadFrom(loaded);
    } else {
      await notifier.loadSchedule(widget.instance);
      if (!mounted) return;
    }
    final edited = ref.read(scheduleEditProvider).editedSchedule;
    if (edited == null || edited.instance != widget.instance) return;
    setState(() => _isEditing = true);
    notifier.setEditing(true);
  }

  Widget? _buildFab(ScheduleEditState editState) {
    final l10n = AppLocalizations.of(context)!;
    if (_isEditing) return null;

    return FloatingActionButton.extended(
      onPressed: _startEditing,
      icon: const Icon(Icons.edit),
      label: Text(l10n.edit),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            l10n.loadingError,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(scheduleDetailProvider(widget.instance)),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scheduleNotFound,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const SaveConfirmDialog(changeCount: 1),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(scheduleEditProvider.notifier).save();
      if (success && mounted) {
        setState(() => _isEditing = false);
        ref.read(scheduleEditProvider.notifier).setEditing(false);
      }
    }
  }

  Future<void> _handleCloseEdit() async {
    final editState = ref.read(scheduleEditProvider);
    if (editState.hasChanges) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => const DiscardChangesDialog(),
      );
      if (!mounted || discard != true) return; // keep editing
      ref.read(scheduleEditProvider.notifier).revert();
    }
    setState(() => _isEditing = false);
    ref.read(scheduleEditProvider.notifier).setEditing(false);
  }
}

/// Contenu de l'écran de détail
class _ScheduleDetailContent extends StatefulWidget {
  final Schedule schedule;
  final bool isEditing;
  final WeekDay? selectedDay;
  final ValueChanged<WeekDay> onDaySelected;

  const _ScheduleDetailContent({
    required this.schedule,
    required this.isEditing,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<_ScheduleDetailContent> createState() => _ScheduleDetailContentState();
}

class _ScheduleDetailContentState extends State<_ScheduleDetailContent> {
  WeekDay? _currentDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600; // Mobile/compact view

    return Column(
      children: [
        // Header avec infos du schedule (compact sur mobile)
        _buildHeader(context, theme, colorScheme, isCompact),

        // Légende des états
        _buildLegend(context, theme, colorScheme),

        // Mode édition: indicateur
        if (widget.isEditing)
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCompact
                            ? l10n.editModeTapSlot
                            : l10n.editModeTapDay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        // Vue du planning - toujours verticale (style Google Agenda)
        Expanded(
          child: VerticalDayScheduleView(
            schedule: widget.schedule,
            isEditing: widget.isEditing,
            initialDay: _currentDay,
            onDayChanged: (day) {
              setState(() => _currentDay = day);
              widget.onDaySelected(day);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description si présente
          if (widget.schedule.description != null && widget.schedule.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.schedule.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: isCompact ? 2 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
            ),

          // Infos techniques
          Wrap(
            spacing: isCompact ? 8 : 16,
            runSpacing: 8,
            children: [
              if (!isCompact)
                _buildInfoChip(
                  context,
                  icon: Icons.tag,
                  label: AppLocalizations.of(context)!.instanceLabel(widget.schedule.instance.toString()),
                ),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return _buildInfoChip(
                    context,
                    icon: widget.schedule.valueType == ScheduleValueType.boolean
                        ? Icons.toggle_on_outlined
                        : Icons.format_list_numbered,
                    label: widget.schedule.valueType == ScheduleValueType.boolean
                        ? l10n.boolean
                        : l10n.multiState,
                  );
                },
              ),
              if (widget.schedule.presentValue != null)
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return _buildInfoChip(
                      context,
                      icon: Icons.play_arrow,
                      label: l10n.currentState(widget.schedule.getStateText(widget.schedule.presentValue)),
                      highlighted: true,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: highlighted
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final possibleValues = widget.schedule.possibleValues;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.legend,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: possibleValues.map((pv) {
                final color = _getColorForValue(pv.value, colorScheme);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        border: pv.value == null
                            ? Border.all(color: colorScheme.outline)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pv.text,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForValue(dynamic value, ColorScheme colorScheme) {
    return ScheduleColors.getColorForValue(value, widget.schedule.valueType, colorScheme);
  }
}
