import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../application/providers/bacnet_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../data/services/bacnet_service.dart';
import '../../widgets/discovery_widgets.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';

/// Lecture du nom / fabricant / modèle d'un device découvert
enum DeviceDetailsStatus { loading, done, failed }

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
  final DeviceDetailsStatus detailsStatus;

  DiscoveredBacnetDevice({
    required this.host,
    this.port = 47808,
    required this.deviceId,
    this.deviceName,
    this.vendorName,
    this.modelName,
    this.hasConflict = false,
    this.conflictingHosts = const [],
    this.detailsStatus = DeviceDetailsStatus.loading,
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
    DeviceDetailsStatus? detailsStatus,
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
      detailsStatus: detailsStatus ?? this.detailsStatus,
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

  /// Essais de lecture des détails d'un device avant d'abandonner
  static const int _detailsAttempts = 3;
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
          // Envois étalés : un device qui a manqué un Who-Is répond au suivant
          sendCount: 4,
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
      dcSnackBar(
        l10n.discoverDeviceIdConflictWithId(conflict.deviceId.toString()),
        color: AppSnackColors.warning,
        icon: Icons.warning_amber_rounded,
        action: SnackBarAction(
          label: l10n.details,
          onPressed: _showConflictsDialog,
        ),
      ),
    );
  }

  void _showConflictsDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        final dc = context.dc;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: dc.warning.fg),
          title: Text(l10n.deviceIdConflict),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deviceIdConflictMessage,
                    style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ..._conflicts.map((conflict) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DcBanner(
                          tone: dc.warning,
                          icon: Icons.tag_rounded,
                          title: 'Device ID : ${conflict.deviceId}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                l10n.conflictingAddresses,
                                style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                              ),
                              ...conflict.allAddresses.map((addr) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        DcStatusDot(color: dc.warning.fg, size: 7, glow: false),
                                        const SizedBox(width: 8),
                                        Text(
                                          addr.address,
                                          style: AppTextStyles.monospacedValue.copyWith(color: dc.textPrimary),
                                        ),
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
                    style: context.text.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: dc.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.understood),
            ),
          ],
        );
      },
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

  /// Récupère nom, fabricant et modèle d'un device, avec relances
  /// automatiques : au premier échange avec le PC, un device perd souvent
  /// la requête (résolution d'adresse) ; l'utilisateur n'a pas à actualiser.
  Future<void> _fetchDeviceDetails(BacnetService bacnetService, String host, int port, int deviceId) async {
    _setDetailsStatus(deviceId, DeviceDetailsStatus.loading);
    for (var attempt = 1; attempt <= _detailsAttempts; attempt++) {
      if (!mounted) return;
      try {
        final result = await bacnetService.testConnection(
          host: host,
          port: port,
          deviceId: deviceId,
          // Relance rapide de la 1re requête, souvent perdue au premier contact
          firstAttemptTimeout: const Duration(seconds: 1),
        );
        if (result.success) {
          if (!mounted) return;
          setState(() {
            final index = _discoveredDevices.indexWhere((d) => d.deviceId == deviceId);
            if (index != -1) {
              _discoveredDevices[index] = _discoveredDevices[index].copyWith(
                deviceName: result.deviceName,
                vendorName: result.vendorName,
                modelName: result.modelName,
                detailsStatus: DeviceDetailsStatus.done,
              );
            }
          });
          return;
        }
      } catch (e) {
        // Nouvel essai ci-dessous
      }
      if (attempt < _detailsAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _setDetailsStatus(deviceId, DeviceDetailsStatus.failed);
  }

  void _setDetailsStatus(int deviceId, DeviceDetailsStatus status) {
    if (!mounted) return;
    final index = _discoveredDevices.indexWhere((d) => d.deviceId == deviceId);
    if (index == -1 || _discoveredDevices[index].detailsStatus == status) return;
    setState(() => _discoveredDevices[index] = _discoveredDevices[index].copyWith(detailsStatus: status));
  }

  /// Nouvelle lecture des détails à la demande (après un échec)
  void _retryDetails(DiscoveredBacnetDevice device) {
    _detailsRequested.remove('${device.deviceId}@${device.host}');
    _queueDeviceDetails(ref.read(bacnetServiceProvider), device.host, device.port, device.deviceId);
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
    final dc = context.dc;

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.discoverDevices,
        subtitle: 'BACnet/IP · Who-Is',
        actions: [
          if (!_isDiscovering)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _startBroadcastDiscovery,
              tooltip: l10n.refresh,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DcContent(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tete : recherche, interface reseau, compteur
                DiscoveryHeader(
                  icon: Icons.radar_rounded,
                  tone: dc.violet,
                  title: _isDiscovering ? l10n.discovering : l10n.discoverDevices,
                  subtitle: _isDiscovering ? l10n.searchingBacnetDevices : l10n.broadcastDiscoverySubtitle,
                  scanning: _isDiscovering,
                  countLabel: _discoveredDevices.isNotEmpty ? l10n.devicesFound(_discoveredDevices.length) : null,
                  child: _buildInterfaceSelector(l10n),
                ),
                const SizedBox(height: 12),

                // Alerte reseau local
                DcBanner(
                  tone: dc.info,
                  icon: Icons.wifi_rounded,
                  title: l10n.bacnetLocalNetworkOnly,
                  message: l10n.bacnetLocalNetworkInfo,
                  dense: true,
                ),

                // Conflits de Device ID
                if (_conflicts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DcBanner(
                    tone: dc.warning,
                    icon: Icons.warning_amber_rounded,
                    title: l10n.deviceIdConflict,
                    message: '${_conflicts.length} ${l10n.conflicts}',
                    dense: true,
                    action: TextButton(
                      onPressed: _showConflictsDialog,
                      style: TextButton.styleFrom(foregroundColor: dc.warning.fg),
                      child: Text(l10n.details),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Contenu principal
                _buildContent(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceSelector(AppLocalizations l10n) {
    final interfacesAsync = ref.watch(availableNetworkInterfacesProvider);
    final selectedInterface = ref.watch(selectedBacnetInterfaceProvider);
    final dc = context.dc;

    return interfacesAsync.when(
      data: (interfaces) {
        // Une seule interface ou moins, pas besoin de sélecteur
        if (interfaces.length <= 1) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: DropdownButtonFormField<NetworkInterfaceChoice?>(
            key: ValueKey(selectedInterface),
            initialValue: selectedInterface,
            decoration: InputDecoration(
              labelText: l10n.networkInterface,
              prefixIcon: const Icon(Icons.lan_outlined, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          iface.isWireless ? Icons.wifi_rounded : Icons.cable_rounded,
                          size: 16,
                          color: dc.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(iface.name, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          iface.address,
                          style: AppTextStyles.monospacedValue.copyWith(fontSize: 12, color: dc.textSecondary),
                        ),
                      ],
                    ),
                  )),
            ],
            onChanged: _isDiscovering ? null : _onInterfaceChanged,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    // Erreur
    if (_errorMessage != null) {
      return DcEmptyState.error(
        context,
        title: l10n.error,
        message: _errorMessage,
        action: FilledButton.icon(
          onPressed: _startBroadcastDiscovery,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    // En cours de recherche sans resultat
    if (_isDiscovering && _discoveredDevices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: DcLoading(message: l10n.searchingBacnetDevices),
      );
    }

    // Aucun appareil trouve
    if (!_isDiscovering && _discoveredDevices.isEmpty) {
      return DcEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.noDeviceFound,
        message: l10n.noDeviceFoundMessage,
        action: FilledButton.icon(
          onPressed: _startBroadcastDiscovery,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    // Grille des appareils trouves
    return DiscoveryGrid(
      children: [
        for (final device in _discoveredDevices)
          _BacnetDeviceCard(
            device: device,
            onTap: () => _selectDevice(device),
            onRetryDetails: () => _retryDetails(device),
          ),
      ],
    );
  }
}

class _BacnetDeviceCard extends StatelessWidget {
  final DiscoveredBacnetDevice device;
  final VoidCallback onTap;
  final VoidCallback onRetryDetails;

  const _BacnetDeviceCard({
    required this.device,
    required this.onTap,
    required this.onRetryDetails,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;

    // Couleur selon le fabricant
    final vendor = device.vendorName?.toLowerCase() ?? '';
    final DcTone tone;
    if (vendor.contains('distech')) {
      tone = dc.accentTone;
    } else if (vendor.contains('trend')) {
      tone = dc.success;
    } else {
      tone = dc.violet;
    }

    return DcCard(
      onTap: onTap,
      borderColor: device.hasConflict ? dc.warning.border : null,
      accentColor: device.hasConflict ? dc.warning.fg : null,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icone
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DcIconBox(icon: Icons.lan_outlined, tone: tone, size: 44),
                  if (device.hasConflict)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: dc.warning.fg,
                          shape: BoxShape.circle,
                          border: Border.all(color: dc.surface, width: 2),
                        ),
                        child: Icon(Icons.priority_high_rounded, size: 11, color: dc.surface),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Nom + adresse
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName ?? 'Device ${device.deviceId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        color: device.deviceName == null ? dc.textSecondary : dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.host}:${device.port}',
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 12, color: dc.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DcTag('ID ${device.deviceId}', tone: tone, mono: true, dense: true),
            ],
          ),

          // Lecture du nom / echec avec relance
          if (device.detailsStatus == DeviceDetailsStatus.loading)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: dc.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.bacnetReadingDeviceName,
                    style: context.text.bodySmall?.copyWith(color: dc.textMuted),
                  ),
                ],
              ),
            )
          else if (device.detailsStatus == DeviceDetailsStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DcBanner(
                tone: dc.warning,
                icon: Icons.info_outline_rounded,
                message: l10n.bacnetDeviceNameUnavailable,
                dense: true,
                action: TextButton(
                  onPressed: onRetryDetails,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: dc.warning.fg,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                  ),
                  child: Text(l10n.retry),
                ),
              ),
            ),

          // Fabricant, modele
          if (device.vendorName != null || device.modelName != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (device.vendorName != null) DcTag(device.vendorName!, icon: Icons.factory_outlined, dense: true),
                if (device.modelName != null) DcTag(device.modelName!, icon: Icons.memory_rounded, dense: true),
              ],
            ),
          ],

          // Conflit d'ID : autres adresses
          if (device.hasConflict) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DcTag(l10n.idConflict, icon: Icons.warning_amber_rounded, tone: dc.warning, dense: true),
                if (device.conflictingHosts.length > 1)
                  Text(
                    '${l10n.alsoAt}: ${device.conflictingHosts.where((h) => h != device.host).join(", ")}',
                    style: AppTextStyles.monospacedValue.copyWith(fontSize: 11.5, color: dc.warning.fg),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: dc.accentTone.bg,
                foregroundColor: dc.accentTone.fg,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: Text(l10n.discoverCreateConnection),
            ),
          ),
        ],
      ),
    );
  }
}
