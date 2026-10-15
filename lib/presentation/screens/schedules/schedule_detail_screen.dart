import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/schedule_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../domain/models/schedule.dart';
import 'widgets/schedule_dialogs.dart';
import 'widgets/schedule_colors.dart';
import 'widgets/vertical_day_schedule_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/utils/schedule_l10n.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';
import '../../../core/theme/app_colors.dart';

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
        context.showSuccess(next.successMessage!);
        ref.read(scheduleEditProvider.notifier).clearSuccess();
      }
      if (next.error != null && previous?.error != next.error) {
        context.showError(next.error!);
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
          loading: () => const DcLoading(),
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
    return GradientAppBar(
      titleWidget: scheduleAsync.when(
        loading: () => Text(l10n.loadingEllipsis),
        error: (_, _) => Text(l10n.error),
        data: (schedule) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schedule?.objectName ?? l10n.scheduleInstance(widget.instance.toString()),
              overflow: TextOverflow.ellipsis,
            ),
            if (_isEditing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DcStatusDot(
                    color: editState.hasChanges ? AppColors.brandOrange : AppColors.brandSky,
                    size: 6,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    editState.hasChanges ? l10n.modified : l10n.editMode,
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: editState.hasChanges ? const Color(0xFFFFB066) : const Color(0xFF9FB2CC),
                    ),
                  ),
                ],
              )
            else
              Text(
                l10n.instanceLabel(widget.instance.toString()),
                style: AppTextStyles.monospacedValue.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF9FB2CC),
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
              icon: const Icon(Icons.undo_rounded),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            tooltip: l10n.saveChanges,
            onPressed: editState.hasChanges && !editState.isSaving
                ? () => _handleSave()
                : null,
          ),
          // Bouton fermer l'édition
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: l10n.closeEdit,
            onPressed: () => _handleCloseEdit(),
          ),
        ] else ...[
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
    // Unreadable weekly-schedule: read-only (never overwrite the controller)
    if (!edited.weeklyScheduleReadable) return;
    setState(() => _isEditing = true);
    notifier.setEditing(true);
  }

  Widget? _buildFab(ScheduleEditState editState) {
    final l10n = AppLocalizations.of(context)!;
    if (_isEditing) return null;
    // Unreadable weekly-schedule: no edition
    final schedule = ref.read(scheduleDetailProvider(widget.instance)).valueOrNull;
    if (schedule != null && !schedule.weeklyScheduleReadable) return null;

    return FloatingActionButton.extended(
      onPressed: _startEditing,
      icon: const Icon(Icons.edit_calendar_rounded),
      label: Text(l10n.edit),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState.error(
      context,
      title: l10n.loadingError,
      message: error.toString(),
      action: FilledButton.icon(
        onPressed: () => ref.invalidate(scheduleDetailProvider(widget.instance)),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.retry),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState(
      icon: Icons.event_busy_rounded,
      title: l10n.scheduleNotFound,
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
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600; // Mobile/compact view

    return Column(
      children: [
        // En-tête : infos du planning et légende des états
        _buildHeader(context, isCompact),

        // Weekly-schedule illisible : lecture seule
        if (!widget.schedule.weeklyScheduleReadable)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: DcBanner(
              tone: dc.danger,
              icon: Icons.warning_amber_rounded,
              message: l10n.weeklyScheduleUnreadable,
              dense: true,
            ),
          ),

        // Mode édition: indicateur
        if (widget.isEditing)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: DcBanner(
              tone: dc.info,
              icon: Icons.touch_app_outlined,
              message: isCompact ? l10n.editModeTapSlot : l10n.editModeTapDay,
              dense: true,
            ),
          ),

        const SizedBox(height: 8),

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

  Widget _buildHeader(BuildContext context, bool isCompact) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final schedule = widget.schedule;
    final isBoolean = schedule.valueType == ScheduleValueType.boolean;
    final hasDescription = schedule.description != null && schedule.description!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, isCompact ? 12 : 14, 16, isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(bottom: BorderSide(color: dc.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description si présente
          if (hasDescription)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                schedule.description!,
                style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                maxLines: isCompact ? 2 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
            ),

          // Infos techniques
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (schedule.presentValue != null)
                DcTag(
                  l10n.currentState(schedule.localizedStateText(l10n, schedule.presentValue)),
                  icon: Icons.play_arrow_rounded,
                  tone: ScheduleColors.blockTone(context, schedule.presentValue, schedule.valueType),
                ),
              DcTag(
                isBoolean ? l10n.boolean : l10n.multiState,
                icon: isBoolean ? Icons.toggle_on_outlined : Icons.format_list_numbered_rounded,
              ),
              if (!isCompact)
                DcTag(
                  l10n.instanceLabel(schedule.instance.toString()),
                  icon: Icons.tag_rounded,
                  mono: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final possibleValues = widget.schedule.localizedPossibleValues(l10n);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            l10n.legend.toUpperCase(),
            style: AppTextStyles.overline.copyWith(color: dc.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: possibleValues.map((pv) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScheduleSwatch(value: pv.value, valueType: widget.schedule.valueType),
                  const SizedBox(width: 6),
                  Text(
                    pv.text,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
