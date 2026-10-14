import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../application/providers/bacnet_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../data/services/bacnet_service.dart';

/// Resultat de decouverte BACnet
class DiscoveredBacnetDevice {
  final String host;
  final int port;
  final int deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;
  final bool hasConflict;
  final List<String> conflictingHosts;

  DiscoveredBacnetDevice({
    required this.host,
    this.port = 47808,
    required this.deviceId,
    this.deviceName,
    this.vendorName,
    this.modelName,
    this.hasConflict = false,
    this.conflictingHosts = const [],
  });

  DiscoveredBacnetDevice copyWith({
    String? host,
    int? port,
    int? deviceId,
    String? deviceName,
    String? vendorName,
    String? modelName,
    bool? hasConflict,
    List<String>? conflictingHosts,
  }) {
    return DiscoveredBacnetDevice(
      host: host ?? this.host,
      port: port ?? this.port,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      vendorName: vendorName ?? this.vendorName,
      modelName: modelName ?? this.modelName,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictingHosts: conflictingHosts ?? this.conflictingHosts,
    );
  }
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
  List<DeviceIdConflict> _conflicts = [];
  String? _errorMessage;
  StreamSubscription<DeviceIdConflict>? _conflictSubscription;

  /// Device details requests: one per (deviceId, address), at most
  /// [_maxConcurrentDetails] in flight, the others wait in [_detailsQueue]
  static const int _maxConcurrentDetails = 4;
  final Set<String> _detailsRequested = {};
  final List<({String host, int port, int deviceId})> _detailsQueue = [];
  int _detailsInFlight = 0;

  @override
  void initState() {
    super.initState();
    // Lancer la decouverte automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBroadcastDiscovery();
    });
  }

  @override
  void dispose() {
    _conflictSubscription?.cancel();
    super.dispose();
  }

  /// Change l'interface réseau et relance la découverte
  Future<void> _onInterfaceChanged(NetworkInterfaceChoice? newInterface) async {
    final bacnetService = ref.read(bacnetServiceProvider);

    // Rebind le service sur la nouvelle interface
    await bacnetService.rebindToInterface(newInterface);
    if (!mounted) return;

    // Mettre à jour le provider
    ref.read(selectedBacnetInterfaceProvider.notifier).state = newInterface;

    // Relancer la découverte
    _startBroadcastDiscovery();
  }

  /// Decouverte broadcast
  Future<void> _startBroadcastDiscovery() async {
    // Une seule découverte à la fois (sinon deux abonnements au flux I-Am)
    if (_isDiscovering || !mounted) return;
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _conflicts = [];
      _errorMessage = null;
    });
    _detailsRequested.clear();
    _detailsQueue.clear();

    try {
      final bacnetService = ref.read(bacnetServiceProvider);

      // Écouter les conflits
      _conflictSubscription?.cancel();
      _conflictSubscription = bacnetService.conflictStream.listen((conflict) {
        if (mounted) {
          // Une seule entrée (et une seule alerte) par Device ID
          final known = _conflicts.indexWhere((c) => c.deviceId == conflict.deviceId);
          setState(() {
            if (known != -1) {
              _conflicts[known] = conflict;
            } else {
              _conflicts.add(conflict);
            }
            // Mettre à jour le device concerné
            final index = _discoveredDevices.indexWhere((d) => d.deviceId == conflict.deviceId);
            if (index != -1) {
              _discoveredDevices[index] = _discoveredDevices[index].copyWith(
                hasConflict: true,
                conflictingHosts: conflict.allAddresses.map((a) => a.address).toList(),
              );
            }
          });
          if (known == -1) _showConflictSnackbar(conflict);
        }
      });

      // Écouter les devices au fur et à mesure qu'ils sont découverts
      final subscription = bacnetService.iAmStream.listen((device) {
        if (mounted) {
          setState(() {
            // Mettre à jour ou ajouter
            final existingIndex = _discoveredDevices.indexWhere((d) => d.deviceId == device.deviceId);
            if (existingIndex != -1) {
              _discoveredDevices[existingIndex] = _discoveredDevices[existingIndex].copyWith(
                host: device.address.address,
                port: device.port,
                hasConflict: device.hasConflict,
                conflictingHosts: device.hasConflict
                    ? [device.address.address, ...device.conflictingAddresses.map((a) => a.address)]
                    : [],
              );
            } else {
              _discoveredDevices.add(DiscoveredBacnetDevice(
                host: device.address.address,
                port: device.port,
                deviceId: device.deviceId,
                hasConflict: device.hasConflict,
                conflictingHosts: device.hasConflict
                    ? [device.address.address, ...device.conflictingAddresses.map((a) => a.address)]
                    : [],
              ));
            }
          });
          // Récupérer les détails (une fois par device, via une file bornée)
          _queueDeviceDetails(bacnetService, device.address.address, device.port, device.deviceId);
        }
      });

      try {
        await bacnetService.discoverLocalDevices(
          port: ref.read(settingsProvider).defaultBacnetPort,
          timeout: const Duration(seconds: 5),
          sendCount: 3,
          sendInterval: const Duration(milliseconds: 800),
        );
      } finally {
        await subscription.cancel();
      }

      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });

        // Afficher le dialog récapitulatif si des conflits ont été détectés
        if (_conflicts.isNotEmpty) {
          _showConflictsDialog();
        }
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

  void _showConflictSnackbar(DeviceIdConflict conflict) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange[700],
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.discoverDeviceIdConflictWithId(conflict.deviceId.toString()),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.details,
          textColor: Colors.white,
          onPressed: _showConflictsDialog,
        ),
      ),
    );
  }

  void _showConflictsDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Text(l10n.deviceIdConflict),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deviceIdConflictMessage,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ..._conflicts.map((conflict) => Card(
                  color: Colors.orange.withValues(alpha: 0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device ID : ${conflict.deviceId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.conflictingAddresses),
                        ...conflict.allAddresses.map((addr) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 10, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(addr.address),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                Text(
                  l10n.conflictRecommendation,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  void _queueDeviceDetails(BacnetService bacnetService, String host, int port, int deviceId) {
    if (!_detailsRequested.add('$deviceId@$host')) return;
    _detailsQueue.add((host: host, port: port, deviceId: deviceId));
    _pumpDetailsQueue(bacnetService);
  }

  void _pumpDetailsQueue(BacnetService bacnetService) {
    while (_detailsInFlight < _maxConcurrentDetails && _detailsQueue.isNotEmpty) {
      final next = _detailsQueue.removeAt(0);
      _detailsInFlight++;
      _fetchDeviceDetails(bacnetService, next.host, next.port, next.deviceId).whenComplete(() {
        _detailsInFlight--;
        if (mounted) _pumpDetailsQueue(bacnetService);
      });
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
            _discoveredDevices[index] = _discoveredDevices[index].copyWith(
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
      'port': device.port,
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
          // Sélecteur d'interface réseau
          _buildInterfaceSelector(theme, l10n),

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

  Widget _buildInterfaceSelector(ThemeData theme, AppLocalizations l10n) {
    final interfacesAsync = ref.watch(availableNetworkInterfacesProvider);
    final selectedInterface = ref.watch(selectedBacnetInterfaceProvider);

    return interfacesAsync.when(
      data: (interfaces) {
        // Une seule interface ou moins, pas besoin de sélecteur
        if (interfaces.length <= 1) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lan, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<NetworkInterfaceChoice?>(
                  value: selectedInterface,
                  decoration: InputDecoration(
                    labelText: l10n.networkInterface,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.allInterfaces),
                    ),
                    ...interfaces.map((iface) => DropdownMenuItem(
                      value: iface,
                      child: Row(
                        children: [
                          Icon(
                            iface.isWireless ? Icons.wifi : Icons.cable,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${iface.name} (${iface.address})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  onChanged: _isDiscovering ? null : _onInterfaceChanged,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
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
              l10n.searchingBacnetDevices,
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
        // Compteur et alerte conflits
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
              Row(
                children: [
                  if (_conflicts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.warning, size: 16, color: Colors.orange),
                        label: Text('${_conflicts.length} ${l10n.conflicts}'),
                        onPressed: _showConflictsDialog,
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
      shape: device.hasConflict
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.orange, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icone
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.device_hub,
                      color: avatarColor,
                      size: 28,
                    ),
                  ),
                  if (device.hasConflict)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.deviceName ?? 'Device ${device.deviceId}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (device.hasConflict)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.idConflict,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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
                    if (device.hasConflict && device.conflictingHosts.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${l10n.alsoAt}: ${device.conflictingHosts.where((h) => h != device.host).join(", ")}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
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
