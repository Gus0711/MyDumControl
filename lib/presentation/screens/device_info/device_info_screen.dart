import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myglobaldc/l10n/app_localizations.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';

/// Écran d'informations détaillées sur l'appareil connecté
class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(activeConnectionProvider);
    final device = connectionState.deviceInfo;
    final connection = connectionState.connection;
    final summary = connectionState.objectsSummary;
    final networkInfo = connectionState.networkInfo;

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.deviceInfo,
        subtitle: device?.objectName ?? connection?.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: connectionState.isLoading
                ? null
                : () => ref.read(activeConnectionProvider.notifier).refresh(),
          ),
        ],
      ),
      body: connectionState.isLoading && device == null
          ? const DcLoading()
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                DcContent(
                  maxWidth: 1100,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 16.0;
                      final twoColumns = constraints.maxWidth >= 820;
                      final half = twoColumns ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Carte principale de l'appareil
                          _buildDeviceCard(context, l10n, connectionState),
                          const SizedBox(height: spacing),

                          // Inventaire des objets BACnet
                          _buildObjectsSummaryCard(context, l10n, summary, connectionState.isLoadingSummary),
                          const SizedBox(height: spacing),

                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              // Informations de connexion
                              if (connection != null)
                                SizedBox(width: half, child: _buildConnectionCard(context, l10n, connection)),
                              // Informations techniques
                              if (device != null)
                                SizedBox(width: half, child: _buildTechnicalCard(context, l10n, device)),
                            ],
                          ),

                          // Informations réseau (API V1 uniquement)
                          if (networkInfo != null) ...[
                            const SizedBox(height: spacing),
                            _buildNetworkCard(context, l10n, networkInfo, twoColumns),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, AppLocalizations l10n, ActiveConnectionState state) {
    final dc = context.dc;
    final device = state.deviceInfo;
    final connection = state.connection;
    final isBacnet = state.isBacnetConnection;
    final description = (device?.description?.trim().isNotEmpty ?? false) ? device!.description!.trim() : null;
    final location = (device?.location?.trim().isNotEmpty ?? false) ? device!.location!.trim() : null;

    return DcCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcIconBox(
            icon: isBacnet ? Icons.lan_outlined : Icons.memory_rounded,
            tone: isBacnet ? dc.violet : dc.accentTone,
            size: 64,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device?.objectName ?? connection?.name ?? 'ECLYPSE Controller',
                  style: context.text.headlineSmall,
                ),
                if (device?.modelName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [device!.modelName!, ?device.vendorName].join(' · '),
                    style: context.text.bodyLarge?.copyWith(color: dc.textSecondary),
                  ),
                ],
                if (description != null || location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (location != null) ...[
                        Icon(Icons.place_outlined, size: 15, color: dc.textMuted),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          [?description, ?location].join(' — '),
                          style: context.text.bodyMedium?.copyWith(color: dc.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (connection != null)
                      DcTag('${connection.host}:${connection.port}', icon: Icons.lan_rounded, mono: true),
                    if (isBacnet)
                      DcTag(
                        state.bacnetDeviceId != null ? 'BACnet · ${state.bacnetDeviceId}' : 'BACnet/IP',
                        tone: dc.violet,
                      )
                    else if (connection?.apiVersion != null)
                      DcTag('API ${connection!.apiVersion}', tone: dc.accentTone),
                    if (device?.softwareVersion != null) DcTag('FW ${device!.softwareVersion}', mono: true),
                    if (device?.deviceInstance != null)
                      DcTag('${l10n.deviceId} ${device!.deviceInstance}', mono: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, AppLocalizations l10n, Connection connection) {
    final isBacnet = connection.connectionType == 'bacnet';
    final protocol = isBacnet ? 'BACnet/IP' : (connection.useHttps ? 'HTTPS' : 'HTTP');

    return _Panel(
      title: l10n.connection,
      icon: Icons.link_rounded,
      children: [
        DcInfoRow(label: l10n.deviceInfoProtocol, value: protocol, labelWidth: 140),
        DcInfoRow(label: l10n.host, value: '${connection.host}:${connection.port}', mono: true, labelWidth: 140),
        if (!isBacnet) DcInfoRow(label: l10n.deviceInfoUser, value: connection.username, labelWidth: 140),
        if (connection.lastConnectedAt != null)
          DcInfoRow(
            label: l10n.deviceInfoLastConnection,
            value: _formatDateTime(connection.lastConnectedAt!),
            mono: true,
            labelWidth: 140,
          ),
      ],
    );
  }

  Widget _buildTechnicalCard(BuildContext context, AppLocalizations l10n, DeviceInfo device) {
    return _Panel(
      title: l10n.deviceInfoTechnical,
      icon: Icons.memory_rounded,
      children: [
        if (device.modelName != null) DcInfoRow(label: l10n.model, value: device.modelName!, labelWidth: 140),
        if (device.modelType != null) DcInfoRow(label: l10n.type, value: device.modelType!, labelWidth: 140),
        if (device.vendorName != null) DcInfoRow(label: l10n.vendor, value: device.vendorName!, labelWidth: 140),
        if (device.softwareVersion != null)
          DcInfoRow(label: l10n.version, value: device.softwareVersion!, mono: true, labelWidth: 140),
        if (device.deviceInstance != null)
          DcInfoRow(label: l10n.deviceId, value: '${device.deviceInstance}', mono: true, labelWidth: 140),
        if (device.hostName != null)
          DcInfoRow(label: l10n.deviceInfoHostName, value: device.hostName!, mono: true, labelWidth: 140),
        if (device.hostId != null) DcInfoRow(label: 'Host ID', value: device.hostId!, mono: true, labelWidth: 140),
      ],
    );
  }

  Widget _buildNetworkCard(BuildContext context, AppLocalizations l10n, NetworkInfo networkInfo, bool twoColumns) {
    final activeInterfaces = networkInfo.activeInterfaces;
    final hasMultipleInterfaces = activeInterfaces.length > 1;
    final dc = context.dc;

    return _Panel(
      title: l10n.deviceInfoNetwork,
      icon: Icons.lan_rounded,
      trailing: activeInterfaces.isNotEmpty
          ? Text(
              l10n.deviceInfoInterfacesCount(activeInterfaces.length),
              style: context.text.labelMedium?.copyWith(color: dc.textMuted),
            )
          : null,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = twoColumns && networkInfo.interfaces.length > 1 ? 2 : 1;
            const spacing = 12.0;
            final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final iface in networkInfo.interfaces)
                  SizedBox(
                    width: width,
                    child: _buildInterfaceSection(context, iface, hasMultipleInterfaces),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInterfaceSection(BuildContext context, NetworkInterfaceInfo iface, bool showTitle) {
    final dc = context.dc;
    final isDisabled = !iface.enabled;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'interface (si plusieurs interfaces)
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6, right: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    iface.isWireless ? Icons.wifi_rounded : Icons.settings_ethernet_rounded,
                    size: 18,
                    color: isDisabled ? dc.textMuted : dc.accentTone.fg,
                  ),
                  Text(
                    iface.displayName,
                    style: context.text.titleSmall?.copyWith(
                      color: isDisabled ? dc.textMuted : dc.textPrimary,
                    ),
                  ),
                  if (iface.dhcpEnabled) DcTag('DHCP', tone: dc.success, dense: true),
                  if (isDisabled) DcTag(l10n.disabled, dense: true),
                  if (iface.isWireless && iface.wifiMode != null)
                    DcTag(iface.wifiMode!, tone: dc.accentTone, dense: true),
                ],
              ),
            ),

          // SSID pour Wi-Fi
          if (iface.isWireless && iface.ssid != null)
            _buildNetworkInfoRow(context, 'SSID', iface.ssid!, mono: false, disabled: isDisabled),

          // Infos IP
          if (iface.ipAddress != null)
            _buildNetworkInfoRow(context, l10n.deviceInfoIpAddress, iface.ipAddress!, disabled: isDisabled),
          if (iface.subnetMask != null)
            _buildNetworkInfoRow(context, l10n.deviceInfoSubnetMask, iface.subnetMask!, disabled: isDisabled),
          if (iface.gateway != null && iface.gateway!.isNotEmpty)
            _buildNetworkInfoRow(context, l10n.deviceInfoGateway, iface.gateway!, disabled: isDisabled),
          if (iface.dnsPrimary != null && iface.dnsPrimary!.isNotEmpty)
            _buildNetworkInfoRow(context, l10n.deviceInfoPrimaryDns, iface.dnsPrimary!, disabled: isDisabled),
          if (iface.macAddress != null)
            _buildNetworkInfoRow(context, l10n.deviceInfoMacAddress, iface.macAddress!, disabled: isDisabled),
        ],
      ),
    );
  }

  Widget _buildNetworkInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool mono = true,
    bool disabled = false,
  }) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;

    return DcInfoRow(
      label: label,
      value: value,
      mono: mono,
      labelWidth: 120,
      valueColor: disabled ? dc.textMuted : null,
      trailing: IconButton(
        icon: Icon(Icons.copy_rounded, size: 16, color: dc.textMuted),
        onPressed: disabled
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  dcSnackBar(l10n.deviceInfoCopied(label), duration: const Duration(seconds: 1)),
                );
              },
        tooltip: l10n.copy,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 22),
      ),
    );
  }

  Widget _buildObjectsSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    ObjectsSummary? summary,
    bool isLoading,
  ) {
    final dc = context.dc;

    return _Panel(
      title: l10n.deviceInfoBacnetObjects,
      icon: Icons.category_outlined,
      trailing: isLoading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : summary != null
              ? DcTag(l10n.deviceInfoTotalObjects(summary.total), tone: dc.accentTone)
              : null,
      children: [
        if (summary != null) ...[
          // Totaux par catégorie
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryTotal(label: l10n.categoryInputs, count: summary.totalInputs, icon: Icons.login_rounded),
              _CategoryTotal(label: l10n.categoryOutputs, count: summary.totalOutputs, icon: Icons.logout_rounded),
              _CategoryTotal(label: l10n.categoryVariables, count: summary.totalValues, icon: Icons.tag_rounded),
              _CategoryTotal(label: l10n.schedules, count: summary.schedules, icon: Icons.calendar_month_rounded),
            ],
          ),
          const SizedBox(height: 14),
          // Détail par type d'objet
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 620
                      ? 3
                      : 2;
              final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final types = <(BacnetObjectType, int)>[
                (BacnetObjectType.analogInput, summary.analogInputs),
                (BacnetObjectType.binaryInput, summary.binaryInputs),
                (BacnetObjectType.multiStateInput, summary.multiStateInputs),
                (BacnetObjectType.analogOutput, summary.analogOutputs),
                (BacnetObjectType.binaryOutput, summary.binaryOutputs),
                (BacnetObjectType.multiStateOutput, summary.multiStateOutputs),
                (BacnetObjectType.analogValue, summary.analogValues),
                (BacnetObjectType.binaryValue, summary.binaryValues),
                (BacnetObjectType.multiStateValue, summary.multiStateValues),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final (type, count) in types)
                    SizedBox(width: width, child: _TypeCountTile(type: type, count: count)),
                ],
              );
            },
          ),
        ] else if (!isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.deviceInfoNoDataAvailable,
                style: context.text.bodyMedium?.copyWith(color: dc.textMuted),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) => DisplayPreferences.formatDateTime(dateTime);
}

/// Panneau titré (icône + titre + action) contenant des lignes d'information.
class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  const _Panel({required this.title, required this.icon, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return DcCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: dc.accentTone.fg),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: context.text.titleMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: dc.border),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

/// Total d'une catégorie d'objets (entrées, sorties…).
class _CategoryTotal extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CategoryTotal({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: dc.textMuted),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: context.text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 6),
          Text(label, style: context.text.bodySmall?.copyWith(color: dc.textSecondary)),
        ],
      ),
    );
  }
}

/// Nombre d'objets d'un type BACnet, avec la pastille du type.
class _TypeCountTile extends StatelessWidget {
  final BacnetObjectType type;
  final int count;

  const _TypeCountTile({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;
    final tone = BacnetTypeUtils.typeTone(context, type);
    final empty = count == 0;

    return Opacity(
      opacity: empty ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: dc.surface,
          borderRadius: BorderRadius.circular(DcRadius.md),
          border: Border.all(color: empty ? dc.border : tone.border),
        ),
        child: Row(
          children: [
            PointTypeBadge(type: type, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: context.text.titleLarge?.copyWith(
                      color: empty ? dc.textMuted : tone.fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.1,
                    ),
                  ),
                  Text(
                    BacnetTypeUtils.getTypeDisplayName(l10n, type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
