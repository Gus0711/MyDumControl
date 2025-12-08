import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../application/providers/bacnet_provider.dart';
import '../../../data/services/bacnet_service.dart';

/// Resultat de decouverte BACnet
class DiscoveredBacnetDevice {
  final String host;
  final int deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;

  DiscoveredBacnetDevice({
    required this.host,
    required this.deviceId,
    this.deviceName,
    this.vendorName,
    this.modelName,
  });
}

/// Ecran de decouverte des appareils BACnet
class DiscoverBacnetScreen extends ConsumerStatefulWidget {
  const DiscoverBacnetScreen({super.key});

  @override
  ConsumerState<DiscoverBacnetScreen> createState() => _DiscoverBacnetScreenState();
}

class _DiscoverBacnetScreenState extends ConsumerState<DiscoverBacnetScreen> {
  bool _isDiscovering = false;
  List<DiscoveredBacnetDevice> _discoveredDevices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Lancer la decouverte automatiquement
    _startBroadcastDiscovery();
  }

  /// Decouverte broadcast
  Future<void> _startBroadcastDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _errorMessage = null;
    });

    try {
      final bacnetService = ref.read(bacnetServiceProvider);

      final devices = await bacnetService.discoverLocalDevices(
        port: 47808,
        timeout: const Duration(seconds: 3),
      );

      if (mounted) {
        setState(() {
          _discoveredDevices = devices.map((device) => DiscoveredBacnetDevice(
            host: device.address.address,
            deviceId: device.deviceId,
          )).toList();
          _isDiscovering = false;
        });
      }

      // Recuperer les details en arriere-plan
      for (final device in devices) {
        _fetchDeviceDetails(bacnetService, device.address.address, 47808, device.deviceId);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Recupere les details d'un device
  Future<void> _fetchDeviceDetails(BacnetService bacnetService, String host, int port, int deviceId) async {
    try {
      final result = await bacnetService.testConnection(
        host: host,
        port: port,
        deviceId: deviceId,
      );

      if (result.success && mounted) {
        setState(() {
          final index = _discoveredDevices.indexWhere((d) => d.deviceId == deviceId);
          if (index != -1) {
            _discoveredDevices[index] = DiscoveredBacnetDevice(
              host: host,
              deviceId: deviceId,
              deviceName: result.deviceName,
              vendorName: result.vendorName,
              modelName: result.modelName,
            );
          }
        });
      }
    } catch (e) {
      // Ignorer les erreurs - le device reste avec les infos de base
    }
  }

  void _selectDevice(DiscoveredBacnetDevice device) {
    // Retourner les donnees a la page precedente
    context.pop({
      'name': device.deviceName ?? 'BACnet ${device.deviceId}',
      'host': device.host,
      'port': 47808,
      'deviceId': device.deviceId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BACnet/IP'),
        actions: [
          if (!_isDiscovering)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startBroadcastDiscovery,
              tooltip: l10n.refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          // Alerte reseau local
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.tertiaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bacnetLocalNetworkOnly,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bacnetLocalNetworkInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Indicateur de progression
          if (_isDiscovering)
            const LinearProgressIndicator(),

          // Contenu principal
          Expanded(
            child: _buildContent(l10n, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, ThemeData theme) {
    // Erreur
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.error,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startBroadcastDiscovery,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    // En cours de recherche sans resultat
    if (_isDiscovering && _discoveredDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.discovering,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Recherche des appareils BACnet...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Aucun appareil trouve
    if (!_isDiscovering && _discoveredDevices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noDeviceFound,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noDeviceFoundMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startBroadcastDiscovery,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    // Liste des appareils trouves
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compteur
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.devicesFound(_discoveredDevices.length),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isDiscovering)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _discoveredDevices.length,
            itemBuilder: (context, index) {
              final device = _discoveredDevices[index];
              return _BacnetDeviceCard(
                device: device,
                onTap: () => _selectDevice(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BacnetDeviceCard extends StatelessWidget {
  final DiscoveredBacnetDevice device;
  final VoidCallback onTap;

  const _BacnetDeviceCard({
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Couleur selon le fabricant
    Color avatarColor;
    if (device.vendorName?.toLowerCase().contains('distech') == true) {
      avatarColor = Colors.blue;
    } else if (device.vendorName?.toLowerCase().contains('trend') == true) {
      avatarColor = Colors.green;
    } else {
      avatarColor = theme.colorScheme.primaryContainer;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icone
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.device_hub,
                  color: avatarColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName ?? 'Device ${device.deviceId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.host}: ${device.host}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${l10n.deviceId}: ${device.deviceId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (device.vendorName != null)
                      Text(
                        '${l10n.vendor}: ${device.vendorName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (device.modelName != null)
                      Text(
                        '${l10n.model}: ${device.modelName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Fleche
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
