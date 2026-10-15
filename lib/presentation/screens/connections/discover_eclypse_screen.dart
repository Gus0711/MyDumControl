import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/eclypse_probe.dart';
import '../../../data/services/mdns_discovery_service.dart';
import '../../widgets/discovery_widgets.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';

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
    final dc = context.dc;

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.discoverEclypse,
        actions: [
          if (!_isDiscovering)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _startDiscovery,
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
                // En-tete explicatif + progression
                DiscoveryHeader(
                  icon: Icons.wifi_find_rounded,
                  tone: dc.accentTone,
                  title: _isDiscovering ? l10n.discovering : l10n.discoverEclypse,
                  subtitle: _isDiscovering ? l10n.discoverSearchingEclypse : l10n.discoverEclypseSubtitle,
                  scanning: _isDiscovering,
                  countLabel: _discoveredDevices.isNotEmpty ? l10n.eclypseFound(_discoveredDevices.length) : null,
                ),
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

  Widget _buildContent(AppLocalizations l10n) {
    // Erreur
    if (_errorMessage != null) {
      return DcEmptyState.error(
        context,
        title: l10n.discoverMdnsError,
        message: _errorMessage,
        action: FilledButton.icon(
          onPressed: _startDiscovery,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    // En cours de recherche sans resultat
    if (_isDiscovering && _discoveredDevices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: DcLoading(message: l10n.discoverSearchingEclypse),
      );
    }

    // Aucun appareil trouve
    if (!_isDiscovering && _discoveredDevices.isEmpty) {
      return DcEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.noDeviceFound,
        message: l10n.discoverNoEclypseFoundMessage,
        action: FilledButton.icon(
          onPressed: _startDiscovery,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    // Grille des appareils trouves
    return DiscoveryGrid(
      children: [
        for (final device in _discoveredDevices)
          _DeviceCard(
            device: device,
            probeResult: _probeResults[device.name],
            onTap: () => _selectDevice(device),
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
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;
    final model = device.model;
    final firmware = device.firmwareVersion;
    final mac = device.macAddress;
    final unreachable = probeResult != null && !probeResult!.reachable;

    return DcCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcIconBox(
                icon: Icons.memory_rounded,
                tone: unreachable ? dc.neutral : dc.accentTone,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.address}:${device.connectionPort}',
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 12, color: dc.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Modele, firmware, MAC
          if (model != null) _line(context, Icons.developer_board_outlined, model),
          _line(
            context,
            Icons.system_update_alt_rounded,
            firmware != null ? l10n.discoverFirmware(firmware) : l10n.discoverFirmwareAfterLogin,
            muted: firmware == null,
          ),
          if (mac != null) _line(context, Icons.fingerprint_rounded, 'MAC $mac', mono: true),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    DcTag(
                      device.prefersHttps ? 'HTTPS' : 'HTTP',
                      icon: device.prefersHttps ? Icons.lock_rounded : Icons.lock_open_rounded,
                      tone: device.prefersHttps ? dc.success : dc.warning,
                      dense: true,
                    ),
                    _buildApiTag(context, l10n),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Creer la connexion (champs pre-remplis)
              FilledButton.tonalIcon(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text, {bool mono = false, bool muted = false}) {
    final dc = context.dc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: dc.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (mono
                      ? AppTextStyles.monospacedValue.copyWith(fontSize: 11.5)
                      : context.text.bodySmall)
                  ?.copyWith(color: muted ? dc.textMuted : dc.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiTag(BuildContext context, AppLocalizations l10n) {
    final dc = context.dc;
    final probe = probeResult;
    if (probe == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: dc.textMuted),
          ),
          const SizedBox(width: 6),
          Text(l10n.discoverProbing, style: context.text.bodySmall?.copyWith(color: dc.textMuted)),
        ],
      );
    }
    if (probe.apiVersion != null) {
      return DcTag('API ${probe.apiVersion}', icon: Icons.api_rounded, tone: dc.accentTone, dense: true);
    }
    if (!probe.reachable) {
      return DcTag(l10n.discoverUnreachable, icon: Icons.cloud_off_rounded, tone: dc.danger, dense: true);
    }
    // Joignable mais version indeterminable sans identifiants
    final advertised = device.advertisedApiVersion;
    return DcTag(
      advertised != null ? l10n.discoverApiAdvertised(advertised) : l10n.discoverApiUnknown,
      icon: Icons.help_outline_rounded,
      dense: true,
    );
  }
}
