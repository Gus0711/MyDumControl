import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/eclypse_probe.dart';
import '../../../data/services/mdns_discovery_service.dart';

/// Ecran de decouverte des ECLYPSE via mDNS
class DiscoverEclypseScreen extends ConsumerStatefulWidget {
  const DiscoverEclypseScreen({super.key});

  @override
  ConsumerState<DiscoverEclypseScreen> createState() => _DiscoverEclypseScreenState();
}

class _DiscoverEclypseScreenState extends ConsumerState<DiscoverEclypseScreen> {
  final _mdnsService = MdnsDiscoveryService();
  final _probe = EclypseProbe();
  final _probeRunner = BoundedTaskRunner(maxConcurrent: 4);
  bool _isDiscovering = false;
  List<EclypseDevice> _discoveredDevices = [];

  /// Résultats de sonde par nom d'appareil (absent = sonde en cours).
  final Map<String, EclypseProbeResult> _probeResults = {};

  /// Incrémenté à chaque recherche : ignore les sondes d'une recherche
  /// précédente.
  int _generation = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Lancer la decouverte automatiquement
    _startDiscovery();
  }

  @override
  void dispose() {
    _probeRunner.clear();
    _mdnsService.stop();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    _probeRunner.clear();
    final generation = ++_generation;
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _probeResults.clear();
      _errorMessage = null;
    });

    try {
      await _mdnsService.discoverEclypseDevices(
        timeout: const Duration(seconds: 5),
        onDeviceFound: (device) {
          if (mounted && generation == _generation) {
            final index = _discoveredDevices.indexWhere((d) => d.name == device.name);
            if (index == -1) {
              setState(() => _discoveredDevices.add(device));
              _scheduleProbe(device, generation);
            } else {
              // Réponse plus complète (TXT) du même appareil
              final previous = _discoveredDevices[index];
              setState(() => _discoveredDevices[index] = device);
              if (previous.connectionPort != device.connectionPort ||
                  previous.prefersHttps != device.prefersHttps) {
                _scheduleProbe(device, generation);
              }
            }
          }
        },
      );

      if (mounted && generation == _generation) {
        setState(() => _isDiscovering = false);
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Sonde non authentifiée (4 en parallèle au plus) ; un échec n'efface
  /// pas l'appareil de la liste.
  void _scheduleProbe(EclypseDevice device, int generation) {
    _probeRunner.add(() async {
      if (!mounted || generation != _generation) return;
      final result = await _probe.probe(
        host: device.address,
        port: device.connectionPort,
        useHttps: device.prefersHttps,
      );
      if (mounted && generation == _generation) {
        setState(() => _probeResults[device.name] = result);
      }
    });
  }

  void _selectDevice(EclypseDevice device) {
    final probe = _probeResults[device.name];
    // Retourner les donnees a la page precedente
    context.pop({
      'name': device.name,
      'host': device.address,
      'port': device.connectionPort,
      'useHttps': device.prefersHttps,
      // Version confirmée sans identifiants uniquement
      'apiVersion': probe?.apiVersion,
      'model': device.model,
      'firmwareVersion': device.firmwareVersion,
      'mac': device.macAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverEclypse),
        actions: [
          if (!_isDiscovering)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startDiscovery,
              tooltip: l10n.refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tete explicatif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_find,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.discoverEclypseSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
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
                l10n.discoverMdnsError,
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
                onPressed: _startDiscovery,
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
              l10n.discoverSearchingEclypse,
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
                l10n.discoverNoEclypseFoundMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startDiscovery,
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
                l10n.eclypseFound(_discoveredDevices.length),
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
              return _DeviceCard(
                device: device,
                probeResult: _probeResults[device.name],
                onTap: () => _selectDevice(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final EclypseDevice device;
  final EclypseProbeResult? probeResult;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.probeResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final model = device.model;
    final firmware = device.firmwareVersion;
    final mac = device.macAddress;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.memory,
                  color: Colors.blue.shade700,
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
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.address}:${device.connectionPort}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (model != null)
                      Text(l10n.discoverModel(model), style: secondaryStyle),
                    Text(
                      firmware != null
                          ? l10n.discoverFirmware(firmware)
                          : l10n.discoverFirmwareAfterLogin,
                      style: secondaryStyle,
                    ),
                    if (mac != null) Text('MAC $mac', style: secondaryStyle),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag(
                          icon: device.prefersHttps ? Icons.lock : Icons.lock_open,
                          label: device.prefersHttps ? 'HTTPS' : 'HTTP',
                          color: device.prefersHttps
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        _buildApiTag(l10n, theme),
                      ],
                    ),
                  ],
                ),
              ),

              // Creer la connexion (champs pre-remplis)
              Tooltip(
                message: l10n.discoverCreateConnection,
                child: Icon(
                  Icons.add_link,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiTag(AppLocalizations l10n, ThemeData theme) {
    final probe = probeResult;
    if (probe == null) {
      return _Tag(
        label: l10n.discoverProbing,
        color: theme.colorScheme.onSurfaceVariant,
        loading: true,
      );
    }
    if (probe.apiVersion != null) {
      return _Tag(
        icon: Icons.api,
        label: 'API ${probe.apiVersion}',
        color: theme.colorScheme.primary,
      );
    }
    if (!probe.reachable) {
      return _Tag(
        icon: Icons.cloud_off,
        label: l10n.discoverUnreachable,
        color: theme.colorScheme.error,
      );
    }
    // Joignable mais version indeterminable sans identifiants
    final advertised = device.advertisedApiVersion;
    return _Tag(
      icon: Icons.help_outline,
      label: advertised != null
          ? l10n.discoverApiAdvertised(advertised)
          : l10n.discoverApiUnknown,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool loading;

  const _Tag({
    this.icon,
    required this.label,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else if (icon != null)
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
