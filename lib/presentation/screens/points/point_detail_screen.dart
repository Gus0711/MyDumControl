import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/trend_log_viewer.dart';
import '../../widgets/favorite_button.dart';

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

class _PointDetailScreenState extends ConsumerState<PointDetailScreen> {
  bool _isEditing = false;
  WriteMode _writeMode = WriteMode.regler;
  final _formKey = GlobalKey<FormState>();
  dynamic _editValue;
  bool _isWriting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Parser l'ID du point (format: "type:instance")
    final parts = widget.pointId.split(':');
    if (parts.length != 2) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.invalidPointId)),
      );
    }

    final typeName = parts[0];
    final instance = int.tryParse(parts[1]);
    if (instance == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.invalidInstance)),
      );
    }

    // Trouver le type correspondant
    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.name == typeName,
          orElse: () => null,
        );

    if (type == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.unknownType(typeName))),
      );
    }

    // Récupérer le point depuis le provider
    final point = ref.watch(pointDetailProvider((type, instance)));

    if (point == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pointNotFound)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.pointNotFoundMessage(type.shortName, instance.toString()),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.reloadPoints),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(point.objectName),
        actions: [
          // Bouton favori
          FavoriteButton(point: point, size: 24),
          if (_canWrite(point.type))
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (_isEditing) {
                    _editValue = point.presentValue;
                  }
                });
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte principale avec la valeur
          _buildValueCard(context, point, l10n),
          const SizedBox(height: 16),

          // Carte d'alarme (si point en alarme)
          if (point.inAlarm) ...[
            _buildAlarmCard(context, point, l10n),
            const SizedBox(height: 16),
          ],

          // Carte de forçage (si point forcé via priority-array)
          if (point.isOverridden) ...[
            _buildOverrideCard(context, point, l10n),
            const SizedBox(height: 16),
          ],

          // Carte de forçage pour les entrées (si out-of-service = true)
          if (point.type.isInput && point.outOfService == true) ...[
            _buildInputForcedCard(context, point, l10n),
            const SizedBox(height: 16),
          ],

          // Informations générales
          _buildInfoCard(context, point, l10n),
          const SizedBox(height: 16),

          // Historique (si disponible)
          _buildTrendLogSection(context, point),

          // Propriétés techniques
          _buildPropertiesCard(context, point, l10n),
        ],
      ),
    );
  }

  Widget _buildTrendLogSection(BuildContext context, BacnetObject point) {
    // Clé pour le mapping : "objectType:objectInstance"
    final pointKey = '${point.type.apiName}:${point.instance}';

    return Consumer(
      builder: (context, ref, child) {
        final trendLogInstance = ref.watch(trendLogInstanceProvider(pointKey));

        if (trendLogInstance == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            TrendLogViewer(
              trendLogInstance: trendLogInstance,
              pointName: point.objectName,
              units: point.units,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicators(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Indicateur d'alarme
        if (point.inAlarm)
          Chip(
            avatar: Icon(Icons.warning_amber, color: Colors.red.shade700, size: 18),
            label: Text(l10n.alarm),
            backgroundColor: Colors.red.shade100,
            labelStyle: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
          ),
        // Indicateur de forçage
        if (point.isOverridden)
          Chip(
            avatar: Icon(Icons.lock, color: Colors.red.shade700, size: 18),
            label: Text(l10n.forcedP(point.overridePriority?.toString() ?? '?')),
            backgroundColor: Colors.red.shade100,
            labelStyle: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
          ),
        if (point.outOfService == true)
          Chip(
            label: Text(l10n.outOfService),
            backgroundColor: Colors.orange.shade100,
            labelStyle: TextStyle(color: Colors.orange.shade800),
          ),
        if (point.reliability != null && point.reliability != 'no-fault-detected')
          Chip(
            label: Text(point.reliability!),
            backgroundColor: Colors.red.shade100,
            labelStyle: TextStyle(color: Colors.red.shade800),
          ),
      ],
    );
  }

  Widget _buildValueCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    final valueColor = _getValueColor(point);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icône du type
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BacnetTypeUtils.getTypeColor(point.type).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                BacnetTypeUtils.getTypeIcon(point.type),
                size: 32,
                color: BacnetTypeUtils.getTypeColor(point.type),
              ),
            ),
            const SizedBox(height: 16),

            // Type et instance
            Text(
              '${point.type.displayName} #${point.instance}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),

            // Valeur actuelle ou édition
            if (_isEditing)
              _buildEditWidget(context, point, l10n)
            else
              _buildValueDisplay(context, point, valueColor),

            // Indicateurs d'état
            const SizedBox(height: 16),
            _buildStatusIndicators(context, point, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildValueDisplay(BuildContext context, BacnetObject point, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: valueColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: valueColor.withAlpha(50)),
      ),
      child: Text(
        point.formattedValue,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
      ),
    );
  }

  Widget _buildEditWidget(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Column(
      children: [
        // Sélecteur de mode d'écriture selon le type
        if (point.type.canWriteSimple)
          // Values: peuvent régler, forcer ou auto
          _buildWriteModeSelector(point, l10n)
        else if (point.type.isInput)
          // Entrées: forçage via out-of-service
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.power_settings_new, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  l10n.forcingOutOfService,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          )
        else
          // Outputs: forçage via priority-array
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  l10n.forcingPriority1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Éditeur selon le type
        if (point.type.isBinary)
          _buildBinaryEditor(context, point, l10n)
        else if (point.type.isAnalog)
          _buildAnalogEditor(context, point, l10n)
        else if (point.type.isMultiState)
          _buildMultiStateEditor(context, point, l10n)
        else
          Text(l10n.typeNotEditable),
      ],
    );
  }

  Widget _buildWriteModeSelector(BacnetObject point, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Régler
          _buildModeButton(
            icon: Icons.edit,
            label: l10n.set,
            isSelected: _writeMode == WriteMode.regler,
            onTap: () => setState(() => _writeMode = WriteMode.regler),
            color: Colors.blue,
          ),
          // Séparateur
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          // Bouton Forçage
          _buildModeButton(
            icon: Icons.lock,
            label: l10n.force,
            isSelected: _writeMode == WriteMode.forcage,
            onTap: () => setState(() => _writeMode = WriteMode.forcage),
            color: Colors.purple,
          ),
          // Séparateur
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          // Bouton Auto
          _buildModeButton(
            icon: Icons.autorenew,
            label: l10n.auto,
            isSelected: _writeMode == WriteMode.auto,
            onTap: () => setState(() => _writeMode = WriteMode.auto),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
            const SizedBox(width: 16),
            _buildBinaryButton(activeLabel, true, isActive),
          ],
        ),
        const SizedBox(height: 16),
        _buildApplyButton(point, l10n),
      ],
    );
  }

  /// Bouton Appliquer avec état de chargement
  Widget _buildApplyButton(BacnetObject point, AppLocalizations l10n) {
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;

    // Les entrées ont un traitement spécial
    if (point.type.isInput) {
      buttonText = l10n.force;
      buttonColor = Colors.orange;
      buttonIcon = Icons.power_settings_new;
    } else {
      // Texte du bouton selon le mode
      final effectiveMode = point.type.canWriteSimple ? _writeMode : WriteMode.forcage;

      switch (effectiveMode) {
        case WriteMode.regler:
          buttonText = l10n.set;
          buttonColor = Colors.blue;
          buttonIcon = Icons.save;
          break;
        case WriteMode.forcage:
          buttonText = l10n.force;
          buttonColor = Colors.purple;
          buttonIcon = Icons.lock;
          break;
        case WriteMode.auto:
          buttonText = l10n.auto;
          buttonColor = Colors.green;
          buttonIcon = Icons.autorenew;
          break;
      }
    }

    return ElevatedButton.icon(
      onPressed: _isWriting ? null : () => _writeValue(point, _editValue, l10n),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      icon: _isWriting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(buttonIcon),
      label: Text(_isWriting ? l10n.inProgress : buttonText),
    );
  }

  Widget _buildBinaryButton(String label, bool value, bool isSelected) {
    final color = value ? Colors.green : Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _editValue = value ? 'active' : 'inactive';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : Colors.grey.shade600,
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
            width: 200,
            child: TextFormField(
              initialValue: point.presentValue?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.value,
                suffixText: point.units,
                border: const OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
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
            width: 200,
            child: TextFormField(
              initialValue: point.presentValue?.toString() ?? '',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.state,
                border: const OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          _buildApplyButtonWithValidation(point, l10n),
        ],
      ),
    );
  }

  Widget _buildMultiStateDropdown(BuildContext context, BacnetObject point, AppLocalizations l10n) {
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
          constraints: const BoxConstraints(minWidth: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: currentValue,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              items: List.generate(stateText.length, (index) {
                final stateValue = index + 1; // BACnet indexé à partir de 1
                final label = stateText[index];
                return DropdownMenuItem<int>(
                  value: stateValue,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: stateValue == currentValue
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            stateValue.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: stateValue == currentValue
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: stateValue == currentValue
                                ? FontWeight.bold
                                : FontWeight.normal,
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
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildApplyButton(point, l10n),
      ],
    );
  }

  /// Bouton Appliquer avec validation de formulaire
  Widget _buildApplyButtonWithValidation(BacnetObject point, AppLocalizations l10n) {
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;

    // Les entrées ont un traitement spécial
    if (point.type.isInput) {
      buttonText = l10n.force;
      buttonColor = Colors.orange;
      buttonIcon = Icons.power_settings_new;
    } else {
      final effectiveMode = point.type.canWriteSimple ? _writeMode : WriteMode.forcage;

      switch (effectiveMode) {
        case WriteMode.regler:
          buttonText = l10n.set;
          buttonColor = Colors.blue;
          buttonIcon = Icons.save;
          break;
        case WriteMode.forcage:
          buttonText = l10n.force;
          buttonColor = Colors.purple;
          buttonIcon = Icons.lock;
          break;
        case WriteMode.auto:
          buttonText = l10n.auto;
          buttonColor = Colors.green;
          buttonIcon = Icons.autorenew;
          break;
      }
    }

    return ElevatedButton.icon(
      onPressed: _isWriting
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                _writeValue(point, _editValue, l10n);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      icon: _isWriting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(buttonIcon),
      label: Text(_isWriting ? l10n.inProgress : buttonText),
    );
  }

  Future<void> _writeValue(BacnetObject point, dynamic value, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    bool success;
    String successMessage;

    // Les entrées utilisent une méthode différente (out-of-service)
    if (point.type.isInput) {
      success = await ref.read(pointsProvider.notifier).forceInput(point, value);
      successMessage = l10n.inputForced;
    } else {
      // Déterminer le mode d'écriture effectif
      // Pour les Outputs, on force toujours (pas de choix)
      final effectiveMode = point.type.canWriteSimple ? _writeMode : WriteMode.forcage;

      switch (effectiveMode) {
        case WriteMode.regler:
          // Écriture simple (sans priorité)
          success = await ref.read(pointsProvider.notifier).writeValue(point, value);
          successMessage = l10n.valueSet;
          break;

        case WriteMode.forcage:
          // Forçage avec priorité 1
          success = await ref.read(pointsProvider.notifier).writeOverride(point, value, priority: 1);
          successMessage = l10n.valueForcedPriority1;
          break;

        case WriteMode.auto:
          // Mode Auto: libération normale puis urgence en succession
          // D'abord, libération normale à la priorité détectée (ou 1 par défaut)
          final priority = point.overridePriority ?? 1;
          success = await ref.read(pointsProvider.notifier).releaseOverride(point, priority: priority);

          // Ensuite, libération d'urgence (toutes les priorités)
          if (success) {
            success = await ref.read(pointsProvider.notifier).emergencyRelease(point);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.writeError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAlarmCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.pointInAlarm,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.alarmTriggeredMessage,
              style: TextStyle(color: Colors.red.shade800),
            ),
            if (point.alarmTimestamp != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatAlarmTimestamp(point.alarmTimestamp!),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (point.alarmMessage != null && point.alarmMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                point.alarmMessage!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAlarmTimestamp(DateTime timestamp) {
    final d = timestamp.day.toString().padLeft(2, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final y = timestamp.year;
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Widget _buildOverrideCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.pointForced,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(l10n.priority, l10n.level(point.overridePriority ?? 0)),
            _buildInfoRow(l10n.forcedValue, _formatOverrideValue(point, l10n)),
            const SizedBox(height: 16),
            // Boutons de libération
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isWriting ? null : () => _releaseOverride(point, l10n),
                    icon: const Icon(Icons.lock_open),
                    label: Text(l10n.release),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade400),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isWriting ? null : () => _emergencyRelease(point, l10n),
                    icon: const Icon(Icons.warning_amber),
                    label: Text(l10n.emergency),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade400),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Carte affichée quand une entrée est forcée via out-of-service
  Widget _buildInputForcedCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.inputForcedTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inputForcedMessage,
              style: TextStyle(color: Colors.orange.shade800),
            ),
            const SizedBox(height: 16),
            // Bouton pour libérer l'entrée
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isWriting ? null : () => _releaseInput(point, l10n),
                icon: const Icon(Icons.lock_open),
                label: Text(l10n.releaseInput),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _releaseInput(BacnetObject point, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    final success = await ref.read(pointsProvider.notifier).releaseInput(point);

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inputReleased),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inputReleaseError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _releaseOverride(BacnetObject point, AppLocalizations l10n) async {
    setState(() => _isWriting = true);

    final success = await ref.read(pointsProvider.notifier).releaseOverride(
      point,
      priority: point.overridePriority ?? 8,
    );

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.overrideReleased),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.releaseError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _emergencyRelease(BacnetObject point, AppLocalizations l10n) async {
    // Confirmation avant libération d'urgence
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(l10n.emergencyRelease),
          ],
        ),
        content: Text(l10n.emergencyReleaseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.releaseAll),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isWriting = true);

    final success = await ref.read(pointsProvider.notifier).emergencyRelease(point);

    if (mounted) {
      setState(() => _isWriting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allPrioritiesReleased),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.emergencyReleaseError),
            backgroundColor: Colors.red,
          ),
        );
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
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
    }

    return value.toString();
  }

  Widget _buildInfoCard(BuildContext context, BacnetObject point, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.information,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(l10n.name, point.objectName),
            if (point.description != null && point.description!.isNotEmpty)
              _buildInfoRow(l10n.description, point.description!),
            _buildInfoRow(l10n.identifier, point.objectId),
            _buildInfoRow(l10n.type, point.type.displayName),
            _buildInfoRow(l10n.instance, point.instance.toString()),
            if (point.units != null && point.units!.isNotEmpty)
              _buildInfoRow(l10n.unit, point.units!),
          ],
        ),
      ),
    );
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  l10n.properties,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...filteredProps.entries.map((e) =>
              _buildInfoRow(_formatPropertyName(e.key), _formatPropertyValue(e.value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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

  Color _getValueColor(BacnetObject point) {
    if (point.outOfService == true) return Colors.orange;

    final value = point.presentValue;
    if (value == null) return Colors.grey;

    if (point.type.isBinary) {
      if (BacnetTypeUtils.isBinaryActive(value)) return Colors.green;
      return Colors.grey;
    }

    return Colors.blue;
  }
}
