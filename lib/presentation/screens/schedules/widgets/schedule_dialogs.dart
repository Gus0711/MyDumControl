import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/schedule.dart';

/// Dialogue pour ajouter ou modifier un créneau horaire
class TimeSlotDialog extends StatefulWidget {
  final Schedule schedule;
  final TimeSlot? existingSlot;
  final String title;

  const TimeSlotDialog({
    super.key,
    required this.schedule,
    this.existingSlot,
    this.title = 'Nouveau créneau',
  });

  @override
  State<TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  late int _startMinutes; // En minutes depuis minuit (0-1439)
  late int _endMinutes;   // En minutes depuis minuit (0-1440, 1440 = 24:00)
  late dynamic _selectedValue;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();

    if (widget.existingSlot != null) {
      // Édition: utiliser les valeurs existantes
      final slot = widget.existingSlot!;
      _startMinutes = slot.startMinutes;
      _endMinutes = slot.endMinutes;
      _selectedValue = slot.value;
      _isAllDay = slot.isAllDay;
    } else {
      // Nouveau: valeurs par défaut (08:00 - 18:00)
      _startMinutes = 8 * 60; // 08:00
      _endMinutes = 18 * 60;  // 18:00
      _selectedValue = widget.schedule.valueType == ScheduleValueType.boolean ? true : 1;
      _isAllDay = false;
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 1440) return '24:00';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final possibleValues = widget.schedule.possibleValues
        .where((pv) => pv.value != null) // Exclure "Auto" pour les créneaux
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option "Toute la journée"
            SwitchListTile(
              title: const Text('Toute la journée'),
              subtitle: const Text('00:00 - 24:00'),
              value: _isAllDay,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                  if (value) {
                    _startMinutes = 0;
                    _endMinutes = 1440; // 24:00
                  }
                });
              },
            ),

            const Divider(),
            const SizedBox(height: 8),

            // Sélecteurs d'heure (désactivés si "toute la journée")
            AnimatedOpacity(
              opacity: _isAllDay ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _isAllDay,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heure de début
                    Text(
                      'Heure de début',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildStartTimePicker(context, colorScheme, theme),

                    const SizedBox(height: 16),

                    // Heure de fin
                    Text(
                      'Heure de fin',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildEndTimePicker(context, colorScheme, theme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sélecteur d'état
            Text(
              'État',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: possibleValues.map((pv) {
                final isSelected = _selectedValue == pv.value;

                return ChoiceChip(
                  label: Text(pv.text),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedValue = pv.value);
                    }
                  },
                );
              }).toList(),
            ),

            // Affichage de la durée
            if (!_isAllDay) ...[
              const SizedBox(height: 16),
              _buildDurationInfo(theme, colorScheme),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _canSave() ? _save : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }

  /// Sélecteur pour l'heure de début (0:00 - 23:00)
  Widget _buildStartTimePicker(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return InkWell(
      onTap: () => _showCustomTimePicker(
        context: context,
        initialMinutes: _startMinutes,
        allowMidnight: false, // Pas de 24:00 pour le début
        onSelected: (minutes) => setState(() => _startMinutes = minutes),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatMinutes(_startMinutes),
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            Icon(Icons.access_time, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  /// Sélecteur pour l'heure de fin avec option 24:00 (minuit)
  Widget _buildEndTimePicker(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return InkWell(
      onTap: () => _showCustomTimePicker(
        context: context,
        initialMinutes: _endMinutes,
        allowMidnight: true, // 24:00 autorisé pour la fin
        onSelected: (minutes) => setState(() => _endMinutes = minutes),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatMinutes(_endMinutes),
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            Icon(Icons.access_time, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  /// Affiche un sélecteur d'heure personnalisé avec grille
  Future<void> _showCustomTimePicker({
    required BuildContext context,
    required int initialMinutes,
    required bool allowMidnight,
    required ValueChanged<int> onSelected,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => CustomTimePickerDialog(
        initialMinutes: initialMinutes,
        allowMidnight: allowMidnight,
      ),
    );
    if (result != null) {
      onSelected(result);
    }
  }

  Widget _buildDurationInfo(ThemeData theme, ColorScheme colorScheme) {
    final duration = _endMinutes - _startMinutes;

    final isValid = duration > 0;
    final hours = duration.abs() ~/ 60;
    final minutes = duration.abs() % 60;

    String durationText;
    if (!isValid) {
      durationText = 'L\'heure de fin doit être après l\'heure de début';
    } else if (hours == 0) {
      durationText = 'Durée: ${minutes}min';
    } else if (minutes == 0) {
      durationText = 'Durée: ${hours}h';
    } else {
      durationText = 'Durée: ${hours}h${minutes.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.timer_outlined : Icons.warning_amber,
            size: 18,
            color: isValid ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              durationText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isValid ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    if (_isAllDay) return true;
    return _endMinutes > _startMinutes;
  }

  void _save() {
    final TimeSlot slot;

    if (_isAllDay) {
      slot = TimeSlot.allDay(_selectedValue);
    } else {
      slot = TimeSlot(
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        value: _selectedValue,
      );
    }

    Navigator.of(context).pop(slot);
  }
}

/// Dialogue personnalisé pour sélectionner l'heure avec rouleaux (wheel pickers)
/// Style iOS/Material - très ergonomique sur mobile
/// Inclut 24:00 (minuit fin de journée) si allowMidnight est true
class CustomTimePickerDialog extends StatefulWidget {
  final int initialMinutes;
  final bool allowMidnight;

  const CustomTimePickerDialog({
    super.key,
    required this.initialMinutes,
    this.allowMidnight = false,
  });

  /// Affiche le dialogue et retourne les minutes sélectionnées (ou null si annulé)
  static Future<int?> show({
    required BuildContext context,
    required int initialMinutes,
    bool allowMidnight = false,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => CustomTimePickerDialog(
        initialMinutes: initialMinutes,
        allowMidnight: allowMidnight,
      ),
    );
  }

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  // Minutes disponibles (par pas de 15)
  static const List<int> _minuteOptions = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    if (widget.initialMinutes >= 1440) {
      _selectedHour = 24;
      _selectedMinute = 0;
    } else {
      _selectedHour = widget.initialMinutes ~/ 60;
      // Arrondir aux 15 minutes les plus proches
      final rawMinute = widget.initialMinutes % 60;
      _selectedMinute = _minuteOptions.reduce((a, b) =>
          (a - rawMinute).abs() < (b - rawMinute).abs() ? a : b);
    }

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _minuteOptions.indexOf(_selectedMinute),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _totalMinutes => _selectedHour == 24 ? 1440 : _selectedHour * 60 + _selectedMinute;
  int get _maxHour => widget.allowMidnight ? 24 : 23;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Sélectionner l\'heure'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Affichage de l'heure sélectionnée en grand
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _selectedHour == 24
                      ? '24:00'
                      : '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Rouleaux heures et minutes
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Rouleau des heures
                  Expanded(
                    child: _buildWheelPicker(
                      controller: _hourController,
                      itemCount: _maxHour + 1,
                      selectedValue: _selectedHour,
                      onChanged: (index) {
                        setState(() {
                          _selectedHour = index;
                          // Si 24h sélectionné, forcer minutes à 0
                          if (_selectedHour == 24 && _selectedMinute != 0) {
                            _selectedMinute = 0;
                            _minuteController.jumpToItem(0);
                          }
                        });
                      },
                      itemBuilder: (index) {
                        final is24 = index == 24;
                        return Text(
                          is24 ? '24' : index.toString().padLeft(2, '0'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: _selectedHour == index ? FontWeight.bold : FontWeight.normal,
                            color: _selectedHour == index
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        );
                      },
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ),

                  // Séparateur ":"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  // Rouleau des minutes (désactivé si 24:00)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _selectedHour == 24 ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _selectedHour == 24,
                        child: _buildWheelPicker(
                          controller: _minuteController,
                          itemCount: _minuteOptions.length,
                          selectedValue: _minuteOptions.indexOf(_selectedMinute),
                          onChanged: (index) {
                            setState(() => _selectedMinute = _minuteOptions[index]);
                          },
                          itemBuilder: (index) {
                            final minute = _minuteOptions[index];
                            return Text(
                              minute.toString().padLeft(2, '0'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: _selectedMinute == minute ? FontWeight.bold : FontWeight.normal,
                                color: _selectedMinute == minute
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            );
                          },
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Label pour 24:00
            if (_selectedHour == 24)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Minuit (fin de journée)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_totalMinutes),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedValue,
    required ValueChanged<int> onChanged,
    required Widget Function(int index) itemBuilder,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Stack(
      children: [
        // Indicateur de sélection (bande au centre)
        Positioned.fill(
          child: Center(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Fix Windows #125291: sur desktop, désactiver scroll natif et gérer manuellement
        // Sur mobile (Android/iOS), garder le scroll tactile natif
        _buildPlatformAwareWheel(
          controller: controller,
          itemCount: itemCount,
          onChanged: onChanged,
          itemBuilder: itemBuilder,
        ),
      ],
    );
  }

  /// Construit le wheel picker adapté à la plateforme
  Widget _buildPlatformAwareWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required Widget Function(int index) itemBuilder,
  }) {
    // Détecter si on est sur desktop (Windows, Linux, macOS) ou web
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    final wheelView = ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.5,
      // Sur desktop: désactiver scroll natif (bug molette)
      // Sur mobile: garder scroll tactile natif
      physics: isDesktop ? const NeverScrollableScrollPhysics() : const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(child: itemBuilder(index));
        },
      ),
    );

    // Sur mobile, retourner directement le wheel view
    if (!isDesktop) {
      return wheelView;
    }

    // Sur desktop, ajouter gestion manuelle molette + drag
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(event, (event) {
            final scrollEvent = event as PointerScrollEvent;
            final currentItem = controller.selectedItem;
            final direction = scrollEvent.scrollDelta.dy > 0 ? 1 : -1;
            final newItem = (currentItem + direction).clamp(0, itemCount - 1);
            if (newItem != currentItem) {
              controller.animateToItem(
                newItem,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final delta = details.primaryDelta ?? 0;
          if (delta.abs() > 15) {
            final currentItem = controller.selectedItem;
            final direction = delta < 0 ? 1 : -1;
            final newItem = (currentItem + direction).clamp(0, itemCount - 1);
            if (newItem != currentItem) {
              controller.animateToItem(
                newItem,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
              );
            }
          }
        },
        child: wheelView,
      ),
    );
  }
}

/// Dialogue pour ajouter ou modifier une transition (ancien, gardé pour compatibilité)
class TransitionDialog extends StatefulWidget {
  final Schedule schedule;
  final ScheduleTransition? existingTransition;
  final String title;

  const TransitionDialog({
    super.key,
    required this.schedule,
    this.existingTransition,
    this.title = 'Nouvelle transition',
  });

  @override
  State<TransitionDialog> createState() => _TransitionDialogState();
}

class _TransitionDialogState extends State<TransitionDialog> {
  late TimeOfDay _selectedTime;
  late dynamic _selectedValue;

  @override
  void initState() {
    super.initState();

    if (widget.existingTransition != null) {
      // Édition: utiliser les valeurs existantes
      final parts = widget.existingTransition!.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      _selectedValue = widget.existingTransition!.value;
    } else {
      // Nouvelle: valeurs par défaut
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _selectedValue = widget.schedule.valueType == ScheduleValueType.boolean ? true : 1;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00.00';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final possibleValues = widget.schedule.possibleValues;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur d'heure
          Text(
            'Heure',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Icon(Icons.access_time, color: colorScheme.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sélecteur de valeur
          Text(
            'État',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: possibleValues.map((pv) {
              final isSelected = _selectedValue == pv.value ||
                  (_selectedValue == null && pv.value == null);

              return ChoiceChip(
                label: Text(pv.text),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedValue = pv.value);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final transition = ScheduleTransition(
              time: _formatTime(_selectedTime),
              value: _selectedValue,
            );
            Navigator.of(context).pop(transition);
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

/// Dialogue pour les actions sur un jour (copier, coller, effacer)
class DayActionsDialog extends StatelessWidget {
  final WeekDay day;
  final bool hasClipboard;
  final WeekDay? clipboardSource;
  final bool hasTransitions;

  const DayActionsDialog({
    super.key,
    required this.day,
    required this.hasClipboard,
    this.clipboardSource,
    required this.hasTransitions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(day.displayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTransitions)
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copier ce jour'),
              onTap: () => Navigator.of(context).pop(DayAction.copy),
            ),
          if (hasClipboard) ...[
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: Text('Coller ici (depuis ${clipboardSource?.shortName})'),
              onTap: () => Navigator.of(context).pop(DayAction.paste),
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Coller sur jours ouvrés'),
              subtitle: const Text('Lun-Ven'),
              onTap: () => Navigator.of(context).pop(DayAction.pasteToWorkDays),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Coller sur tous les jours'),
              onTap: () => Navigator.of(context).pop(DayAction.pasteToAll),
            ),
          ],
          if (hasTransitions)
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(
                'Effacer ce jour',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => Navigator.of(context).pop(DayAction.clear),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Actions possibles sur un jour
enum DayAction {
  copy,
  paste,
  pasteToWorkDays,
  pasteToAll,
  clear,
}

/// Dialogue de confirmation avant de sauvegarder
class SaveConfirmDialog extends StatelessWidget {
  final int changeCount;

  const SaveConfirmDialog({
    super.key,
    required this.changeCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.save_outlined),
      title: const Text('Sauvegarder le planning ?'),
      content: const Text(
        'Les modifications seront envoyées à l\'automate et prendront effet immédiatement.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

/// Dialogue de confirmation pour annuler les modifications
class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
      title: const Text('Annuler les modifications ?'),
      content: const Text(
        'Toutes les modifications non sauvegardées seront perdues.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continuer l\'édition'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Dialogue de confirmation pour supprimer une transition
class DeleteTransitionDialog extends StatelessWidget {
  final ScheduleTransition transition;
  final String stateText;

  const DeleteTransitionDialog({
    super.key,
    required this.transition,
    required this.stateText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      title: const Text('Supprimer cette transition ?'),
      content: Text(
        'Transition à ${transition.formattedTime} → $stateText',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}

/// Dialogue de confirmation pour supprimer un créneau
class DeleteSlotDialog extends StatelessWidget {
  final TimeSlot slot;
  final String stateText;

  const DeleteSlotDialog({
    super.key,
    required this.slot,
    required this.stateText,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = slot.isAllDay
        ? 'Toute la journée'
        : '${slot.formattedStart} - ${slot.formattedEnd}';

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      title: const Text('Supprimer ce créneau ?'),
      content: Text(
        '$timeText : $stateText',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
