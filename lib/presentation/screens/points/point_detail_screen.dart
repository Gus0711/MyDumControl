import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/trend_log_viewer.dart';
import '../../widgets/app_override_info.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';

/// Écran de détail d'un point BACnet
class PointDetailScreen extends ConsumerStatefulWidget {
  final String pointId;

  const PointDetailScreen({super.key, required this.pointId});

  @override
  ConsumerState<PointDetailScreen> createState() => _PointDetailScreenState();
}

/// Mode d'écriture BACnet
enum WriteMode {
  regler,   // Régler: Écriture simple (sans priorité) - uniquement pour Values
  forcage,  // Forçage: Écriture avec priorité 1
  auto,     // Auto: Libération normale puis urgence en succession
}

/// Apparence du bouton d'application selon le mode d'écriture.
class _ApplyStyle {
  final String label;
  final IconData icon;
  final DcTone tone;

  const _ApplyStyle(this.label, this.icon, this.tone);
}

class _PointDetailScreenState extends ConsumerState<PointDetailScreen> {
  bool _isEditing = false;
  WriteMode _writeMode = WriteMode.regler;

  /// Durée du forçage (null = permanent)
  Duration? _overrideDuration;
  final _formKey = GlobalKey<FormState>();
  dynamic _editValue;
  bool _isWriting = false;

  void _toggleEditing(BacnetObject point) {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _editValue = point.presentValue;
      }
    });
  }

  Scaffold _messageScaffold(String title, Widget body) => Scaffold(
        appBar: GradientAppBar(title: title),
        body: body,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuild the values when the display settings change
    ref.watch(settingsProvider.select((s) => (s.decimalPlaces, s.temperatureUnit)));

    // Parser l'ID du point (format: "type:instance")
    final parts = widget.pointId.split(':');
    if (parts.length != 2) {
      return _messageScaffold(
        l10n.error,
        DcEmptyState.error(context, title: l10n.invalidPointId),
      );
    }

    final typeName = parts[0];
    final instance = int.tryParse(parts[1]);
    if (instance == null) {
      return _messageScaffold(
        l10n.error,
        DcEmptyState.error(context, title: l10n.invalidInstance),
      );
    }

    // Trouver le type correspondant
    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.name == typeName,
          orElse: () => null,
        );

    if (type == null) {
      return _messageScaffold(
        l10n.error,
        DcEmptyState.error(context, title: l10n.unknownType(typeName)),
      );
    }

    // Récupérer le point depuis le provider
    final point = ref.watch(pointDetailProvider((type, instance)));

    if (point == null) {
      return _messageScaffold(
        l10n.pointNotFound,
        DcEmptyState(
          icon: Icons.search_off_rounded,
          title: l10n.pointNotFound,
          message: l10n.pointNotFoundMessage(type.shortName, instance.toString()),
          action: FilledButton.icon(
            onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.reloadPoints),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: point.displayName,
        subtitle: '${point.objectId} · ${BacnetTypeUtils.getTypeDisplayName(l10n, point.type)}',
        actions: [
          // Bouton favori
          FavoriteButton(point: point, size: 22, color: const Color(0xFFB7C6DA)),
          if (_canWrite(point.type))
            IconButton(
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined),
              tooltip: _isEditing ? l10n.cancel : l10n.edit,
              onPressed: () => _toggleEditing(point),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DcContent(
            maxWidth: 980,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte principale avec la valeur
                _buildValueCard(context, point, l10n),

                // Carte d'alarme (si point en alarme)
                if (point.inAlarm) ...[
                  const SizedBox(height: 14),
                  _buildAlarmCard(context, point, l10n),
                ],

                // Carte de forçage (si point forcé via priority-array)
                if (point.isOverridden) ...[
                  const SizedBox(height: 14),
                  _buildOverrideCard(context, point, l10n),
                ],

                // Carte de forçage pour les entrées (si out-of-service = true)
                if (point.type.isInput && point.outOfService == true) ...[
                  const SizedBox(height: 14),
                  _buildInputForcedCard(context, point, l10n),
                ],

                // Historique (si disponible)
                _buildTrendLogSection(context, point),

                // Informations générales
                DcSectionHeader(l10n.information, icon: Icons.info_outline_rounded, padding: _sectionPadding),
                _buildInfoCard(context, point, l10n),

                // Propriétés techniques
                _buildPropertiesCard(context, point, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _sectionPadding = EdgeInsets.fromLTRB(4, 24, 0, 10);

  Widget _buildTrendLogSection(BuildContext context, BacnetObject point) {
    // Clé pour le mapping : "objectType:objectInstance"
    final pointKey = '${point.type.apiName}:${point.instance}';

    return Consumer(
      builder: (context, ref, child) {
        final trendLogInstance = ref.watch(trendLogInstanceProvider(pointKey));

        if (trendLogInstance == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: TrendLogViewer(
            trendLogInstance: trendLogInstance,
            pointName: point.displayName,
            units: point.units,
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicators(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    final hasFault = point.reliability != null && point.reliability != 'no-fault-detected';
    if (!point.inAlarm && !point.isOverridden && point.outOfService != true && !hasFault) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          // Indicateur d'alarme
          if (point.inAlarm)
            DcTag(l10n.alarm, icon: Icons.notifications_active_rounded, tone: dc.danger),
          // Indicateur de forçage
          if (point.isOverridden)
            DcTag(
              l10n.forcedP(point.overridePriority?.toString() ?? '?'),
              icon: Icons.back_hand_rounded,
              tone: dc.overrideTone,
            ),
          if (point.outOfService == true)
            DcTag(l10n.outOfService, icon: Icons.power_settings_new_rounded, tone: dc.overrideTone),
          if (hasFault) DcTag(point.reliability!, icon: Icons.report_problem_outlined, tone: dc.danger, mono: true),
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    return DcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PointTypeBadge(type: point.type, size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type et instance
                    Text(
                      '${BacnetTypeUtils.getTypeDisplayName(l10n, point.type)} · #${point.instance}',
                      style: context.text.labelMedium?.copyWith(color: dc.textMuted),
                    ),
                    const SizedBox(height: 6),
                    _buildValueDisplay(context, point),
                    // Indicateurs d'état
                    _buildStatusIndicators(context, point, l10n),
                  ],
                ),
              ),
              if (_canWrite(point.type) && !_isEditing) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _toggleEditing(point),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                ),
              ],
            ],
          ),
          // Édition de la valeur
          if (_isEditing) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 18),
            _buildEditWidget(context, point, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildValueDisplay(BuildContext context, BacnetObject point) {
    final tone = BacnetTypeUtils.valueTone(context, point);
    final isBinary = point.type.isBinary && point.presentValue != null;
    final active = isBinary && BacnetTypeUtils.isBinaryActive(point.presentValue);
    final color = tone == context.dc.neutral ? context.dc.textPrimary : tone.fg;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isBinary) ...[
          DcStatusDot(color: active ? tone.fg : context.dc.textMuted, size: 12, glow: active),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: SelectableText(
            point.formattedValue,
            style: context.text.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditWidget(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    return Column(
      children: [
        // Sélecteur de mode d'écriture selon le type
        if (point.type.canWriteSimple)
          // Values: peuvent régler, forcer ou auto
          _buildWriteModeSelector(point, l10n)
        else if (point.type.isInput)
          // Entrées: forçage via out-of-service
          DcBanner(
            tone: dc.overrideTone,
            icon: Icons.power_settings_new_rounded,
            message: l10n.forcingOutOfService,
            dense: true,
          )
        else
          // Outputs: forçage via priority-array
          DcBanner(
            tone: dc.overrideTone,
            icon: Icons.back_hand_rounded,
            message: l10n.forcingPriority1,
            dense: true,
          ),
        if (point.type.isInput ||
            !point.type.canWriteSimple ||
            _writeMode == WriteMode.forcage) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OverrideDurationSelector(
              value: _overrideDuration,
              onChanged: (d) => setState(() => _overrideDuration = d),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Éditeur selon le type
        if (point.type.isBinary)
          _buildBinaryEditor(context, point, l10n)
        else if (point.type.isAnalog)
          _buildAnalogEditor(context, point, l10n)
        else if (point.type.isMultiState)
          _buildMultiStateEditor(context, point, l10n)
        else
          Text(l10n.typeNotEditable, style: TextStyle(color: dc.textSecondary)),
      ],
    );
  }

  Widget _buildWriteModeSelector(BacnetObject point, AppLocalizations l10n) {
    return SegmentedButton<WriteMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: WriteMode.regler, icon: const Icon(Icons.tune_rounded, size: 18), label: Text(l10n.set)),
        ButtonSegment(value: WriteMode.forcage, icon: const Icon(Icons.back_hand_rounded, size: 18), label: Text(l10n.force)),
        ButtonSegment(value: WriteMode.auto, icon: const Icon(Icons.autorenew_rounded, size: 18), label: Text(l10n.auto)),
      ],
      selected: {_writeMode},
      onSelectionChanged: (s) => setState(() => _writeMode = s.first),
    );
  }

  Widget _buildBinaryEditor(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    // Normaliser la valeur pour détecter si actif
    // La valeur peut être: true, 1, 'active', 'true', 'TRUE', 'Active', etc.
    final isActive = BacnetTypeUtils.isBinaryActive(_editValue);

    // Utiliser activeText/inactiveText si disponibles
    final activeLabel = point.activeText ?? 'ON';
    final inactiveLabel = point.inactiveText ?? 'OFF';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBinaryButton(inactiveLabel, false, !isActive),
            const SizedBox(width: 14),
            _buildBinaryButton(activeLabel, true, isActive),
          ],
        ),
        const SizedBox(height: 20),
        _buildApplyButton(point, l10n),
      ],
    );
  }

  /// Libellé, icône et ton du bouton d'application selon le type et le mode.
  _ApplyStyle _applyStyle(BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    // Les entrées ont un traitement spécial
    if (point.type.isInput) {
      return _ApplyStyle(l10n.force, Icons.power_settings_new_rounded, dc.overrideTone);
    }
    // Texte du bouton selon le mode
    final effectiveMode = point.type.canWriteSimple ? _writeMode : WriteMode.forcage;
    switch (effectiveMode) {
      case WriteMode.regler:
        return _ApplyStyle(l10n.set, Icons.check_rounded, dc.accentTone);
      case WriteMode.forcage:
        return _ApplyStyle(l10n.force, Icons.back_hand_rounded, dc.overrideTone);
      case WriteMode.auto:
        return _ApplyStyle(l10n.auto, Icons.autorenew_rounded, dc.success);
    }
  }

  Widget _applyButton(BacnetObject point, AppLocalizations l10n, VoidCallback onPressed) {
    final style = _applyStyle(point, l10n);
    final onColor = context.dc.onSolid;
    return FilledButton.icon(
      onPressed: _isWriting ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: style.tone.fg,
        foregroundColor: onColor,
        minimumSize: const Size(180, 44),
      ),
      icon: _isWriting
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: context.dc.textMuted),
            )
          : Icon(style.icon, size: 18),
      label: Text(_isWriting ? l10n.inProgress : style.label),
    );
  }

  /// Bouton Appliquer avec état de chargement
  Widget _buildApplyButton(BacnetObject point, AppLocalizations l10n) {
    return _applyButton(point, l10n, () => _writeValue(point, _editValue, l10n));
  }

  Widget _buildBinaryButton(String label, bool value, bool isSelected) {
    final dc = context.dc;
    final tone = value ? dc.success : dc.neutral;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(DcRadius.lg),
        onTap: () {
          setState(() {
            _editValue = value ? 'active' : 'inactive';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? tone.bg : dc.surfaceSunken,
            borderRadius: BorderRadius.circular(DcRadius.lg),
            border: Border.all(
              color: isSelected ? tone.fg : dc.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DcStatusDot(
                color: isSelected ? tone.fg : dc.textMuted,
                size: 9,
                glow: isSelected && value,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: context.text.titleMedium?.copyWith(
                  color: isSelected ? (value ? tone.fg : dc.textPrimary) : dc.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalogEditor(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            width: 240,
            child: TextFormField(
              initialValue: point.presentValue?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.value,
                suffixText: point.units,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.monospacedValue.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
              onChanged: (value) {
                _editValue = double.tryParse(value) ?? 0.0;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterValue;
                }
                if (double.tryParse(value) == null) {
                  return l10n.invalidValue;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildApplyButtonWithValidation(point, l10n),
        ],
      ),
    );
  }

  Widget _buildMultiStateEditor(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    // Si on a les états possibles, afficher un dropdown
    if (point.stateText != null && point.stateText!.isNotEmpty) {
      return _buildMultiStateDropdown(context, point, l10n);
    }

    // Sinon on utilise un champ texte numérique (fallback)
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            width: 240,
            child: TextFormField(
              initialValue: point.presentValue?.toString() ?? '',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.state,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.monospacedValue.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
              onChanged: (value) {
                _editValue = int.tryParse(value) ?? 1;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterState;
                }
                final intValue = int.tryParse(value);
                if (intValue == null || intValue < 1) {
                  return l10n.invalidStateMin1;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildApplyButtonWithValidation(point, l10n),
        ],
      ),
    );
  }

  Widget _buildMultiStateDropdown(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    final stateText = point.stateText!;

    // Valeur actuelle (BACnet est indexé à partir de 1)
    int currentValue;
    if (_editValue is int) {
      currentValue = _editValue;
    } else if (point.presentValue is int) {
      currentValue = point.presentValue;
    } else if (point.presentValue is num) {
      currentValue = (point.presentValue as num).toInt();
    } else {
      currentValue = 1;
    }

    // S'assurer que la valeur est dans les bornes
    if (currentValue < 1 || currentValue > stateText.length) {
      currentValue = 1;
    }

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: dc.surfaceSunken,
            border: Border.all(color: dc.border),
            borderRadius: BorderRadius.circular(DcRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: currentValue,
              isExpanded: true,
              borderRadius: BorderRadius.circular(DcRadius.md),
              dropdownColor: dc.surfaceRaised,
              icon: Icon(Icons.expand_more_rounded, color: dc.textMuted),
              style: context.text.titleMedium?.copyWith(color: dc.textPrimary),
              items: List.generate(stateText.length, (index) {
                final stateValue = index + 1; // BACnet indexé à partir de 1
                final label = stateText[index];
                final selected = stateValue == currentValue;
                return DropdownMenuItem<int>(
                  value: stateValue,
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? dc.accentTone.bg : dc.surfaceSunken,
                          borderRadius: BorderRadius.circular(DcRadius.sm),
                          border: Border.all(color: selected ? dc.accentTone.border : dc.border),
                        ),
                        child: Text(
                          stateValue.toString(),
                          style: AppTextStyles.monospacedValue.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? dc.accentTone.fg : dc.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _editValue = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Affichage de la sélection actuelle
        Text(
          l10n.selectedState(stateText[currentValue - 1], currentValue.toString()),
          style: context.text.bodySmall?.copyWith(color: dc.textMuted),
        ),
        const SizedBox(height: 20),
        _buildApplyButton(point, l10n),
      ],
    );
  }

  /// Bouton Appliquer avec validation de formulaire
  Widget _buildApplyButtonWithValidation(BacnetObject point, AppLocalizations l10n) {
    return _applyButton(point, l10n, () {
      if (_formKey.currentState!.validate()) {
        _writeValue(point, _editValue, l10n);
      }
    });
  }

  /// Runs a write action; any exception counts as a failure so that
  /// `_isWriting` is always reset by the caller.
  /// Ajoute au message d'échec la raison donnée par l'automate, si connue.
  String _withFailureDetail(String message) {
    final detail = ref.read(pointsProvider.notifier).lastActionError;
    return detail == null || detail.isEmpty ? message : '$message\n$detail';
  }

  Future<bool> _safe(Future<bool> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeValue(BacnetObject point, dynamic value, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    bool success;
    String successMessage;

    // Les entrées utilisent une méthode différente (out-of-service)
    if (point.type.isInput) {
      success = await _safe(() => ref
          .read(pointsProvider.notifier)
          .forceInput(point, value, duration: _overrideDuration));
      successMessage = l10n.inputForced;
    } else {
      // Déterminer le mode d'écriture effectif
      // Pour les Outputs, on force toujours (pas de choix)
      final effectiveMode = point.type.canWriteSimple ? _writeMode : WriteMode.forcage;

      switch (effectiveMode) {
        case WriteMode.regler:
          // Écriture simple (sans priorité)
          success = await _safe(() => ref.read(pointsProvider.notifier).writeValue(point, value));
          successMessage = l10n.valueSet;
          break;

        case WriteMode.forcage:
          // Forçage avec priorité 1
          success = await _safe(() => ref
              .read(pointsProvider.notifier)
              .writeOverride(point, value, priority: 1, duration: _overrideDuration));
          successMessage = l10n.valueForcedPriority1;
          break;

        case WriteMode.auto:
          // Mode Auto: libération normale puis urgence en succession
          // D'abord, libération normale à la priorité détectée (ou 1 par défaut)
          final priority = point.overridePriority ?? 1;
          success = await _safe(() => ref.read(pointsProvider.notifier).releaseOverride(point, priority: priority));

          // Ensuite, libération d'urgence (toutes les priorités)
          if (success) {
            success = await _safe(() => ref.read(pointsProvider.notifier).emergencyRelease(point));
          }

          successMessage = success ? l10n.pointSetToAuto : l10n.errorSettingAuto;
          break;
      }
    }

    if (mounted) {
      setState(() {
        _isWriting = false;
        if (success) _isEditing = false;
      });

      if (success) {
        context.showSuccess(successMessage);
      } else {
        context.showError(_withFailureDetail(l10n.writeError));
      }
    }
  }

  /// En-tête d'une carte d'état (alarme, forçage) : icône teintée + titre.
  Widget _stateHeader(BuildContext context, IconData icon, String title, DcTone tone) {
    return Row(
      children: [
        DcIconBox(icon: icon, tone: tone, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: context.text.titleMedium?.copyWith(color: tone.fg)),
        ),
      ],
    );
  }

  Widget _buildAlarmCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    return DcCard(
      accentColor: dc.danger.fg,
      borderColor: dc.danger.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stateHeader(context, Icons.notifications_active_rounded, l10n.pointInAlarm, dc.danger),
          const SizedBox(height: 10),
          Text(
            l10n.alarmTriggeredMessage,
            style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
          ),
          if (point.alarmTimestamp != null) ...[
            const SizedBox(height: 10),
            DcTag(
              _formatAlarmTimestamp(point.alarmTimestamp!),
              icon: Icons.schedule_rounded,
              tone: dc.danger,
              mono: true,
            ),
          ],
          if (point.alarmMessage != null && point.alarmMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              point.alarmMessage!,
              style: context.text.bodyMedium?.copyWith(
                color: dc.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAlarmTimestamp(DateTime timestamp) => DisplayPreferences.formatDateTime(timestamp);

  Widget _buildOverrideCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    return DcCard(
      accentColor: dc.overrideTone.fg,
      borderColor: dc.overrideTone.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stateHeader(context, Icons.back_hand_rounded, l10n.pointForced, dc.overrideTone),
          const SizedBox(height: 10),
          DcInfoRow(label: l10n.priority, value: l10n.level(point.overridePriority ?? 0)),
          DcInfoRow(
            label: l10n.forcedValue,
            value: _formatOverrideValue(point, l10n),
            mono: true,
            valueColor: dc.overrideTone.fg,
          ),
          AppOverrideInfo(point: point),
          const SizedBox(height: 16),
          // Boutons de libération
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _isWriting ? null : () => _releaseOverride(point, l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: dc.overrideTone.fg,
                  foregroundColor: dc.onSolid,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(l10n.release),
              ),
              OutlinedButton.icon(
                onPressed: _isWriting ? null : () => _emergencyRelease(point, l10n),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dc.danger.fg,
                  side: BorderSide(color: dc.danger.border),
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text(l10n.emergency),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte affichée quand une entrée est forcée via out-of-service
  Widget _buildInputForcedCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    return DcCard(
      accentColor: dc.overrideTone.fg,
      borderColor: dc.overrideTone.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stateHeader(context, Icons.power_settings_new_rounded, l10n.inputForcedTitle, dc.overrideTone),
          const SizedBox(height: 10),
          Text(
            l10n.inputForcedMessage,
            style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
          ),
          AppOverrideInfo(point: point),
          const SizedBox(height: 16),
          // Bouton pour libérer l'entrée
          FilledButton.icon(
            onPressed: _isWriting ? null : () => _releaseInput(point, l10n),
            style: FilledButton.styleFrom(
              backgroundColor: dc.success.fg,
              foregroundColor: dc.onSolid,
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text(l10n.releaseInput),
          ),
        ],
      ),
    );
  }

  Future<void> _releaseInput(BacnetObject point, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    final success = await _safe(() => ref.read(pointsProvider.notifier).releaseInput(point));

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        context.showSuccess(l10n.inputReleased);
      } else {
        context.showError(_withFailureDetail(l10n.inputReleaseError));
      }
    }
  }

  Future<void> _releaseOverride(BacnetObject point, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    final success = await _safe(() => ref.read(pointsProvider.notifier).releaseOverride(
          point,
          priority: point.overridePriority ?? 8,
        ));

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        context.showSuccess(l10n.overrideReleased);
      } else {
        context.showError(_withFailureDetail(l10n.releaseError));
      }
    }
  }

  Future<void> _emergencyRelease(BacnetObject point, AppLocalizations l10n) async {
    // Confirmation avant libération d'urgence
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dc = context.dc;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: dc.danger.fg),
          title: Text(l10n.emergencyRelease),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(l10n.emergencyReleaseMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: dc.danger.fg,
                foregroundColor: dc.onSolid,
              ),
              child: Text(l10n.releaseAll),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWriting = true);

    final success = await _safe(() => ref.read(pointsProvider.notifier).emergencyRelease(point));

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        context.showSuccess(l10n.allPrioritiesReleased);
      } else {
        context.showError(_withFailureDetail(l10n.emergencyReleaseError));
      }
    }
  }

  String _formatOverrideValue(BacnetObject point, AppLocalizations l10n) {
    final value = point.overrideValue;
    if (value == null) return '-';

    if (point.type.isBinary) {
      final isActive = BacnetTypeUtils.isBinaryActive(value);
      if (isActive) {
        return point.activeText ?? l10n.active;
      } else {
        return point.inactiveText ?? l10n.inactive;
      }
    }

    if (value is num) {
      return DisplayPreferences.formatAnalog(value, point.units);
    }

    return value.toString();
  }

  Widget _buildInfoCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return DcCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcInfoRow(label: l10n.name, value: point.objectName),
          _buildDescriptionRow(context, point, l10n),
          DcInfoRow(label: l10n.identifier, value: point.objectId, mono: true),
          DcInfoRow(label: l10n.type, value: BacnetTypeUtils.getTypeDisplayName(l10n, point.type)),
          DcInfoRow(label: l10n.instance, value: point.instance.toString(), mono: true),
          if (point.units != null && point.units!.isNotEmpty)
            DcInfoRow(label: l10n.unit, value: point.units!),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final dc = context.dc;
    final hasDescription = point.description != null && point.description!.isNotEmpty;

    return DcInfoRow(
      label: l10n.description,
      value: hasDescription ? point.description! : l10n.noDescription,
      valueColor: hasDescription ? null : dc.textMuted,
      trailing: IconButton(
        onPressed: () => _showEditDescriptionDialog(context, point, l10n),
        tooltip: l10n.editDescription,
        icon: Icon(Icons.edit_outlined, size: 17, color: dc.link),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 26),
      ),
    );
  }

  Future<void> _showEditDescriptionDialog(BuildContext context, BacnetObject point, AppLocalizations l10n) async {
    final controller = TextEditingController(text: point.description ?? '');
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editDescription),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.descriptionHint,
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final success = await ref.read(pointsProvider.notifier).writeDescription(point, result);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          dcSnackBar(
            success ? l10n.descriptionUpdated : _withFailureDetail(l10n.descriptionUpdateError),
            color: success ? AppSnackColors.success : AppSnackColors.danger,
            icon: success ? Icons.check_circle_rounded : Icons.error_rounded,
          ),
        );
      }
    }
  }

  Widget _buildPropertiesCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final props = point.rawProperties;
    if (props == null || props.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filtrer les propriétés déjà affichées
    final displayedKeys = {'object-name', 'objectName', 'description', 'present-value',
                           'presentValue', 'units', 'out-of-service', 'outOfService', 'reliability'};
    final filteredProps = Map.fromEntries(
      props.entries.where((e) => !displayedKeys.contains(e.key)),
    );

    if (filteredProps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DcSectionHeader(
          l10n.properties,
          icon: Icons.tune_rounded,
          count: filteredProps.length,
          padding: _sectionPadding,
        ),
        DcCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in filteredProps.entries)
                DcInfoRow(
                  label: _formatPropertyName(e.key),
                  value: _formatPropertyValue(e.value),
                  mono: true,
                  labelWidth: 180,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPropertyName(String key) {
    // Convertir kebab-case ou camelCase en titre
    return key
        .replaceAllMapped(RegExp(r'[-_](\w)'), (m) => ' ${m.group(1)!.toUpperCase()}')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatPropertyValue(dynamic value) {
    if (value == null) return '-';
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  bool _canWrite(BacnetObjectType type) {
    // Tous les types peuvent être modifiés:
    // - Values: écriture simple ou forçage via priority-array
    // - Outputs: forçage via priority-array
    // - Inputs: forçage via out-of-service + present-value
    return true;
  }
}
