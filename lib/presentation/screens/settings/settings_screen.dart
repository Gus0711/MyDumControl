import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/ui/ui.dart';

/// Écran des paramètres de l'application
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isClearing = false;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.settings,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          DcContent(
            maxWidth: 760,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(context, l10n.appearance, Icons.palette_outlined, [
                  _buildThemeSelector(context, settings, l10n),
                  _buildLanguageSelector(context, settings, l10n),
                ]),
                _buildSection(context, l10n.connection, Icons.wifi_rounded, [
                  _buildTimeoutSelector(context, settings, l10n),
                  _buildRefreshIntervalSelector(context, settings, l10n),
                  _buildBacnetPortSelector(context, settings, l10n),
                ]),
                _buildSection(context, l10n.display, Icons.visibility_outlined, [
                  _buildTemperatureUnitSelector(context, settings, l10n),
                  _buildTimeFormatSwitch(context, settings, l10n),
                  _buildDecimalPlacesSelector(context, settings, l10n),
                ]),
                _buildSection(context, l10n.data, Icons.storage_rounded, [
                  _buildClearCacheButton(context, l10n),
                  _buildExportButton(context, l10n),
                  _buildImportButton(context, l10n),
                ]),
                _buildSection(context, l10n.about, Icons.info_outline_rounded, [
                  _buildAboutTile(context, l10n),
                  _buildLicensesTile(context, l10n),
                  _buildResetButton(context, l10n),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section : sur-titre + carte regroupant les réglages, séparés par un filet.
  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> tiles) {
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DcSectionHeader(title, icon: icon, padding: const EdgeInsets.fromLTRB(4, 24, 4, 8)),
        DcCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) Divider(indent: 64, endIndent: 16, color: dc.border),
                tiles[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // === APPARENCE ===

  Widget _buildThemeSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.brightness_6_outlined,
      title: l10n.theme,
      subtitle: _getThemeLabel(settings.themeMode, l10n),
      trailing: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [
          ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined, size: 18), tooltip: l10n.themeSystem),
          ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined, size: 18), tooltip: l10n.themeLight),
          ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined, size: 18), tooltip: l10n.themeDark),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setThemeMode(s.first),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  Widget _buildLanguageSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.language_rounded,
      title: l10n.language,
      subtitle: settings.locale == 'fr' ? 'Français' : 'English',
      trailing: SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'fr', label: Text('FR')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {settings.locale},
        onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setLocale(s.first),
      ),
    );
  }

  // === CONNEXION ===

  Widget _buildTimeoutSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.timer_outlined,
      title: l10n.connectionTimeout,
      value: l10n.secondsValue(settings.connectionTimeoutSeconds),
      onTap: () => _showTimeoutDialog(context, settings, l10n),
    );
  }

  void _showTimeoutDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    final options = [5, 10, 15, 30, 60];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.connectionTimeout),
        content: RadioGroup<int>(
          groupValue: settings.connectionTimeoutSeconds,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setConnectionTimeout(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((seconds) {
              return RadioListTile<int>(
                title: Text(l10n.secondsValue(seconds)),
                value: seconds,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshIntervalSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    String subtitle;
    if (settings.refreshIntervalSeconds == 0) {
      subtitle = l10n.disabled;
    } else {
      subtitle = l10n.everySeconds(settings.refreshIntervalSeconds);
    }

    return _SettingsTile(
      icon: Icons.sync_rounded,
      title: l10n.autoRefresh,
      value: subtitle,
      onTap: () => _showRefreshDialog(context, settings, l10n),
    );
  }

  void _showRefreshDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    final options = [0, 5, 10, 30, 60];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.autoRefresh),
        content: RadioGroup<int>(
          groupValue: settings.refreshIntervalSeconds,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setRefreshInterval(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((seconds) {
              String label;
              if (seconds == 0) {
                label = l10n.disabled;
              } else {
                label = l10n.everySeconds(seconds);
              }
              return RadioListTile<int>(
                title: Text(label),
                value: seconds,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBacnetPortSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.settings_ethernet_rounded,
      title: l10n.defaultBacnetPort,
      value: '${settings.defaultBacnetPort}',
      monoValue: true,
      onTap: () => _showBacnetPortDialog(context, settings, l10n),
    );
  }

  void _showBacnetPortDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    final controller = TextEditingController(text: settings.defaultBacnetPort.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.defaultBacnetPort),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.port,
            hintText: '47808',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port < 65536) {
                ref.read(settingsProvider.notifier).setDefaultBacnetPort(port);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // === AFFICHAGE ===

  Widget _buildTemperatureUnitSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.thermostat_rounded,
      title: l10n.temperatureUnit,
      subtitle: settings.temperatureUnit == 'celsius' ? l10n.celsius : l10n.fahrenheit,
      trailing: SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'celsius', label: Text('°C')),
          ButtonSegment(value: 'fahrenheit', label: Text('°F')),
        ],
        selected: {settings.temperatureUnit},
        onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setTemperatureUnit(s.first),
      ),
    );
  }

  Widget _buildTimeFormatSwitch(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.schedule_rounded,
      title: l10n.format24Hour,
      subtitle: settings.use24HourFormat ? '14:30' : '2:30 PM',
      onTap: () => ref.read(settingsProvider.notifier).setUse24HourFormat(!settings.use24HourFormat),
      trailing: Switch(
        value: settings.use24HourFormat,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setUse24HourFormat(value);
        },
      ),
    );
  }

  Widget _buildDecimalPlacesSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.pin_outlined,
      title: l10n.decimalPlaces,
      subtitle: l10n.example((23.456789).toStringAsFixed(settings.decimalPlaces)),
      value: l10n.decimalPlacesValue(settings.decimalPlaces),
      onTap: () => _showDecimalDialog(context, settings, l10n),
    );
  }

  void _showDecimalDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.decimalPlaces),
        content: RadioGroup<int>(
          groupValue: settings.decimalPlaces,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setDecimalPlaces(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0, 1, 2, 3].map((places) {
              return RadioListTile<int>(
                title: Text(l10n.decimalPlacesValue(places)),
                subtitle: Text(l10n.example((23.456789).toStringAsFixed(places))),
                value: places,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // === DONNÉES ===

  Widget _buildClearCacheButton(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.cleaning_services_outlined,
      busy: _isClearing,
      title: l10n.clearCache,
      subtitle: l10n.clearCacheSubtitle,
      onTap: _isClearing ? null : () => _clearCache(context, l10n),
    );
  }

  Future<void> _clearCache(BuildContext context, AppLocalizations l10n) async {
    final confirm = await showConfirmDialog(
      context,
      title: l10n.clearCacheConfirm,
      message: l10n.clearCacheMessage,
      confirmLabel: l10n.clear,
    );

    if (confirm == true && mounted) {
      setState(() => _isClearing = true);
      try {
        await ref.read(cacheOperationsProvider).clearAllCache();
        if (mounted) {
          this.context.showSuccess(l10n.cacheCleared);
        }
      } catch (e) {
        if (mounted) {
          this.context.showError(l10n.errorWithMessage('$e'));
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Widget _buildExportButton(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.upload_rounded,
      busy: _isExporting,
      title: l10n.exportConnections,
      subtitle: l10n.exportConnectionsSubtitle,
      onTap: _isExporting ? null : () => _exportConnections(context, l10n),
    );
  }

  Future<void> _exportConnections(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isExporting = true);
    try {
      await ref.read(dataExportProvider).exportAndShare();
    } catch (e) {
      if (mounted) {
        this.context.showError(l10n.exportError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildImportButton(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.download_rounded,
      busy: _isImporting,
      title: l10n.importConnections,
      subtitle: l10n.importConnectionsSubtitle,
      onTap: _isImporting ? null : () => _importConnections(context, l10n),
    );
  }

  Future<void> _importConnections(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isImporting = true);
    try {
      // Utiliser file_picker pour sélectionner le fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      final bytes = result?.files.single.bytes;
      if (bytes != null) {
        final jsonString = utf8.decode(bytes);

        final importResult = await ref.read(dataExportProvider).importConnectionsFromJson(jsonString);

        if (mounted) {
          this.context.showInfo(importResult.summary);
        }
      }
    } catch (e) {
      if (mounted) {
        this.context.showError(l10n.importError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  // === À PROPOS ===

  Widget _buildAboutTile(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      leading: Image.asset('assets/images/logov2_no_back.png', width: 36, height: 36),
      title: 'MyDumControl',
      subtitle: l10n.eclypseManagement,
      value: '${l10n.version} 1.0.0',
      monoValue: true,
      onTap: () => _showAboutDialog(context, l10n),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: 'MyDumControl',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/images/logov2_no_back.png', width: 56, height: 56),
      applicationLegalese: '© 2024 MyDumControl\n${l10n.eclypseManagement}',
      children: [
        const SizedBox(height: 16),
        Text(
          '${l10n.eclypseManagement}.\n\n${l10n.supportsApiBacnet}',
        ),
      ],
    );
  }

  Widget _buildLicensesTile(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.description_outlined,
      title: l10n.openSourceLicenses,
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'MyDumControl',
        applicationVersion: '1.0.0',
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, AppLocalizations l10n) {
    return _SettingsTile(
      icon: Icons.restore_rounded,
      tone: context.dc.warning,
      title: l10n.resetSettings,
      subtitle: l10n.resetSettingsSubtitle,
      onTap: () => _resetSettings(context, l10n),
    );
  }

  Future<void> _resetSettings(BuildContext context, AppLocalizations l10n) async {
    final confirm = await showConfirmDialog(
      context,
      title: l10n.resetConfirm,
      message: l10n.resetMessage,
      confirmLabel: l10n.reset,
    );

    if (confirm == true) {
      await ref.read(settingsProvider.notifier).resetToDefaults();
      if (mounted) {
        this.context.showSuccess(l10n.settingsReset);
      }
    }
  }
}

/// Ligne de réglage : icône teintée, titre, sous-titre, valeur et contrôle.
class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Valeur courante affichée à droite (avec chevron si [onTap]).
  final String? value;
  final bool monoValue;
  final Widget? trailing;
  final VoidCallback? onTap;
  final DcTone? tone;
  final bool busy;

  const _SettingsTile({
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.monoValue = false,
    this.trailing,
    this.onTap,
    this.tone,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = tone ?? dc.accentTone;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : leading ?? DcIconBox(icon: icon ?? Icons.tune_rounded, tone: t, size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: tone != null ? t.fg : dc.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!, style: context.text.bodySmall?.copyWith(color: dc.textSecondary)),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: monoValue
                    ? AppTextStyles.monospacedValue.copyWith(color: dc.textSecondary)
                    : context.text.bodyMedium?.copyWith(color: dc.textSecondary),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (trailing == null && onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: dc.textMuted, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
