import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/mdns_discovery_service.dart';

/// Ecran de decouverte des ECLYPSE via mDNS
class DiscoverEclypseScreen extends ConsumerStatefulWidget {
  const DiscoverEclypseScreen({super.key});

  @override
  ConsumerState<DiscoverEclypseScreen> createState() => _DiscoverEclypseScreenState();
}

class _DiscoverEclypseScreenState extends ConsumerState<DiscoverEclypseScreen> {
  final _mdnsService = MdnsDiscoveryService();
  bool _isDiscovering = false;
  List<EclypseDevice> _discoveredDevices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Lancer la decouverte automatiquement
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _errorMessage = null;
    });

    try {
      await _mdnsService.discoverEclypseDevices(
        timeout: const Duration(seconds: 5),
        onDeviceFound: (device) {
          if (mounted) {
            setState(() {
              if (!_discoveredDevices.any((d) => d.name == device.name)) {
                _discoveredDevices.add(device);
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isDiscovering = false);
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

  void _selectDevice(EclypseDevice device) {
    // Retourner les donnees a la page precedente
    context.pop({
      'name': device.name,
      'host': device.ipAddress ?? device.host,
      'port': device.port,
      'useHttps': device.port == 443,
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
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      '${device.ipAddress ?? device.host}:${device.port}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (device.port == 443)
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'HTTPS',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
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
