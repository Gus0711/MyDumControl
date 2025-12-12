import 'dart:io';

/// Représente une interface réseau disponible pour la communication BACnet
class NetworkInterfaceChoice {
  final String name;
  final String address;
  final String broadcastAddress;
  final String? subnetMask;
  final bool isWireless;
  final bool isLoopback;

  const NetworkInterfaceChoice({
    required this.name,
    required this.address,
    required this.broadcastAddress,
    this.subnetMask,
    this.isWireless = false,
    this.isLoopback = false,
  });

  /// Liste toutes les interfaces réseau IPv4 disponibles
  static Future<List<NetworkInterfaceChoice>> listAvailable({
    bool includeLoopback = false,
  }) async {
    final result = <NetworkInterfaceChoice>[];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: includeLoopback,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type != InternetAddressType.IPv4) continue;
          if (!includeLoopback && addr.isLoopback) continue;

          final parts = addr.address.split('.');
          if (parts.length != 4) continue;

          // Calculer l'adresse broadcast (simplification /24)
          final broadcastAddress = '${parts[0]}.${parts[1]}.${parts[2]}.255';

          // Détecter si c'est une interface WiFi
          final nameLower = iface.name.toLowerCase();
          final isWireless = nameLower.contains('wi-fi') ||
              nameLower.contains('wifi') ||
              nameLower.contains('wlan') ||
              nameLower.contains('wireless');

          result.add(NetworkInterfaceChoice(
            name: iface.name,
            address: addr.address,
            broadcastAddress: broadcastAddress,
            isWireless: isWireless,
            isLoopback: addr.isLoopback,
          ));
        }
      }
    } catch (e) {
      // En cas d'erreur, retourner une liste vide
      // L'appelant utilisera le fallback sur toutes les interfaces
    }

    return result;
  }

  /// Icône suggérée pour cette interface
  String get iconName {
    if (isLoopback) return 'loop';
    if (isWireless) return 'wifi';
    return 'cable';
  }

  /// Label formaté pour affichage
  String get displayLabel => '$name ($address)';

  @override
  String toString() => displayLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkInterfaceChoice &&
        other.name == name &&
        other.address == address;
  }

  @override
  int get hashCode => name.hashCode ^ address.hashCode;
}
