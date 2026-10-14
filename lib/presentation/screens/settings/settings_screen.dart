import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/confirm_dialog.dart';

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
        children: [
          // === APPARENCE ===
          _buildSectionHeader(context, l10n.appearance, Icons.palette),
          _buildThemeSelector(context, settings, l10n),
          _buildLanguageSelector(context, settings, l10n),
          const Divider(),

          // === CONNEXION ===
          _buildSectionHeader(context, l10n.connection, Icons.wifi),
          _buildTimeoutSelector(context, settings, l10n),
          _buildRefreshIntervalSelector(context, settings, l10n),
          _buildBacnetPortSelector(context, settings, l10n),
          const Divider(),

          // === AFFICHAGE ===
          _buildSectionHeader(context, l10n.display, Icons.visibility),
          _buildTemperatureUnitSelector(context, settings, l10n),
          _buildTimeFormatSwitch(context, settings, l10n),
          _buildDecimalPlacesSelector(context, settings, l10n),
          const Divider(),

          // === DONNÉES ===
          _buildSectionHeader(context, l10n.data, Icons.storage),
          _buildClearCacheButton(context, l10n),
          _buildExportButton(context, l10n),
          _buildImportButton(context, l10n),
          const Divider(),

          // === À PROPOS ===
          _buildSectionHeader(context, l10n.about, Icons.info_outline),
          _buildAboutTile(context, l10n),
          _buildLicensesTile(context, l10n),
          _buildResetButton(context, l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // En mode sombre, utiliser une couleur plus claire pour les titres de section
    final sectionColor = isDark
        ? Colors.blue.shade300
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: sectionColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: sectionColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // === APPARENCE ===

  Widget _buildThemeSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: Text(l10n.theme),
      subtitle: Text(_getThemeLabel(settings.themeMode, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, settings, l10n),
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

  void _showThemeDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_getThemeLabel(mode, l10n)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(settings.locale == 'fr' ? 'Français' : 'English'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, settings, l10n),
    );
  }

  void _showLanguageDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: RadioGroup<String>(
          groupValue: settings.locale,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setLocale(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Français'),
                value: 'fr',
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CONNEXION ===

  Widget _buildTimeoutSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: Text(l10n.connectionTimeout),
      subtitle: Text(l10n.secondsValue(settings.connectionTimeoutSeconds)),
      trailing: const Icon(Icons.chevron_right),
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

    return ListTile(
      leading: const Icon(Icons.refresh),
      title: Text(l10n.autoRefresh),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
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
    return ListTile(
      leading: const Icon(Icons.settings_ethernet),
      title: Text(l10n.defaultBacnetPort),
      subtitle: Text('${settings.defaultBacnetPort}'),
      trailing: const Icon(Icons.chevron_right),
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
          TextButton(
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
    return ListTile(
      leading: const Icon(Icons.thermostat),
      title: Text(l10n.temperatureUnit),
      subtitle: Text(settings.temperatureUnit == 'celsius' ? l10n.celsius : l10n.fahrenheit),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showTemperatureDialog(context, settings, l10n),
    );
  }

  void _showTemperatureDialog(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.temperatureUnit),
        content: RadioGroup<String>(
          groupValue: settings.temperatureUnit,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setTemperatureUnit(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(l10n.celsius),
                value: 'celsius',
              ),
              RadioListTile<String>(
                title: Text(l10n.fahrenheit),
                value: 'fahrenheit',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFormatSwitch(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return SwitchListTile(
      secondary: const Icon(Icons.access_time),
      title: Text(l10n.format24Hour),
      subtitle: Text(settings.use24HourFormat ? '14:30' : '2:30 PM'),
      value: settings.use24HourFormat,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setUse24HourFormat(value);
      },
    );
  }

  Widget _buildDecimalPlacesSelector(BuildContext context, AppSettings settings, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.numbers),
      title: Text(l10n.decimalPlaces),
      subtitle: Text(l10n.decimalPlacesValue(settings.decimalPlaces)),
      trailing: const Icon(Icons.chevron_right),
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
    return ListTile(
      leading: _isClearing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cleaning_services),
      title: Text(l10n.clearCache),
      subtitle: Text(l10n.clearCacheSubtitle),
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
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text(l10n.cacheCleared)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage('$e'))),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Widget _buildExportButton(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: _isExporting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload),
      title: Text(l10n.exportConnections),
      subtitle: Text(l10n.exportConnectionsSubtitle),
      onTap: _isExporting ? null : () => _exportConnections(context, l10n),
    );
  }

  Future<void> _exportConnections(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isExporting = true);
    try {
      await ref.read(dataExportProvider).exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(l10n.exportError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildImportButton(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: _isImporting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      title: Text(l10n.importConnections),
      subtitle: Text(l10n.importConnectionsSubtitle),
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
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text(importResult.summary)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(l10n.importError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  // === À PROPOS ===

  Widget _buildAboutTile(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('MyDumControl'),
      subtitle: Text('${l10n.version} 1.0.0'),
      onTap: () => _showAboutDialog(context, l10n),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: 'MyDumControl',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.settings_remote, size: 48),
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
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(l10n.openSourceLicenses),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'MyDumControl',
        applicationVersion: '1.0.0',
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: Icon(Icons.restore, color: Colors.orange.shade700),
      title: Text(l10n.resetSettings, style: TextStyle(color: Colors.orange.shade700)),
      subtitle: Text(l10n.resetSettingsSubtitle),
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
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(l10n.settingsReset)),
        );
      }
    }
  }
}
