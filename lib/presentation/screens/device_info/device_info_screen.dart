import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myglobaldc/l10n/app_localizations.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../widgets/gradient_app_bar.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: connectionState.isLoading
                ? null
                : () => ref.read(activeConnectionProvider.notifier).refresh(),
          ),
        ],
      ),
      body: connectionState.isLoading && device == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Carte principale de l'appareil
                _buildDeviceCard(context, device, connection),
                const SizedBox(height: 16),

                // Informations de connexion
                _buildConnectionCard(context, l10n, connection),
                const SizedBox(height: 16),

                // Informations réseau (API V1 uniquement)
                if (networkInfo != null) ...[
                  _buildNetworkCard(context, networkInfo),
                  const SizedBox(height: 16),
                ],

                // Résumé des objets BACnet
                _buildObjectsSummaryCard(context, l10n, summary, connectionState.isLoadingSummary),
                const SizedBox(height: 16),

                // Informations techniques
                if (device != null) _buildTechnicalCard(context, device),
              ],
            ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, dynamic device, dynamic connection) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_remote,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              device?.objectName ?? connection?.name ?? 'ECLYPSE Controller',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (device?.modelName != null) ...[
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    device!.modelName!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                  );
                },
              ),
            ],
            if (connection?.apiVersion != null) ...[
              const SizedBox(height: 12),
              Chip(
                label: Text('API ${connection!.apiVersion}'),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, AppLocalizations l10n, dynamic connection) {
    if (connection == null) return const SizedBox.shrink();

    final protocol = connection.useHttps ? 'HTTPS' : 'HTTP';
    final url = '${connection.host}:${connection.port}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.connection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, l10n.deviceInfoProtocol, protocol),
            _buildInfoRow(context, l10n.host, url),
            _buildInfoRow(context, l10n.deviceInfoUser, connection.username),
            if (connection.lastConnectedAt != null)
              _buildInfoRow(
                context,
                l10n.deviceInfoLastConnection,
                _formatDateTime(connection.lastConnectedAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(BuildContext context, NetworkInfo networkInfo) {
    final activeInterfaces = networkInfo.activeInterfaces;
    final hasMultipleInterfaces = activeInterfaces.length > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lan, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.deviceInfoNetwork,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (activeInterfaces.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        AppLocalizations.of(context)!.deviceInfoInterfacesCount(activeInterfaces.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Afficher chaque interface
            for (int i = 0; i < networkInfo.interfaces.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _buildInterfaceSection(context, networkInfo.interfaces[i], hasMultipleInterfaces),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceSection(BuildContext context, NetworkInterfaceInfo iface, bool showTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = !iface.enabled;
    final textColor = isDisabled ? Colors.grey.shade400 : null;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de l'interface (si plusieurs interfaces)
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  iface.isWireless ? Icons.wifi : Icons.settings_ethernet,
                  size: 18,
                  color: isDisabled ? Colors.grey.shade400 : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  iface.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (iface.dhcpEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DHCP',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.disabled,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (iface.isWireless && iface.wifiMode != null)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      iface.wifiMode!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // SSID pour Wi-Fi
        if (iface.isWireless && iface.ssid != null)
          _buildNetworkInfoRow(context, 'SSID', iface.ssid!, disabled: isDisabled),

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
          _buildNetworkInfoRow(context, l10n.deviceInfoMacAddress, iface.macAddress!, isMac: true, disabled: isDisabled),
      ],
    );
  }

  Widget _buildNetworkInfoRow(BuildContext context, String label, String value, {bool isMac = false, bool disabled = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = disabled ? Colors.grey.shade400 : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.grey.shade400 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: isMac ? 'monospace' : null,
                color: textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: disabled ? Colors.grey.shade300 : (isDark ? Colors.grey.shade400 : null)),
            onPressed: disabled
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.deviceInfoCopied(label)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
            tooltip: AppLocalizations.of(context)!.copy,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectsSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    dynamic summary,
    bool isLoading,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.deviceInfoBacnetObjects,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary != null) ...[
              Row(
                children: [
                  Expanded(child: _buildSummaryTile(context, l10n.categoryInputs, summary.totalInputs, Icons.input, Colors.blue)),
                  Expanded(child: _buildSummaryTile(context, l10n.categoryOutputs, summary.totalOutputs, Icons.output, Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSummaryTile(context, l10n.categoryVariables, summary.totalValues, Icons.tag, Colors.green)),
                  Expanded(child: _buildSummaryTile(context, l10n.schedules, summary.schedules, Icons.schedule, Colors.purple)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.deviceInfoTotalObjects(summary.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ] else if (!isLoading)
              Center(
                child: Text(l10n.deviceInfoNoDataAvailable),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BuildContext context, String label, int count, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalCard(BuildContext context, dynamic device) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.deviceInfoTechnical,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (device.modelName != null) _buildInfoRow(context, l10n.model, device.modelName!),
            if (device.modelType != null) _buildInfoRow(context, l10n.type, device.modelType!),
            if (device.softwareVersion != null) _buildInfoRow(context, l10n.version, device.softwareVersion!),
            if (device.hostName != null) _buildInfoRow(context, l10n.deviceInfoHostName, device.hostName!),
            if (device.hostId != null) _buildInfoRow(context, 'Host ID', device.hostId!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
