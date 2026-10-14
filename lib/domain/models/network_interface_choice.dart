import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/services/bacnet/bacnet_network.dart';

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

    // Real broadcast / prefix per address (netmask from `ip` on Linux,
    // /24 assumption elsewhere)
    final realByAddress = <String, LocalIpv4Interface>{};
    try {
      for (final i in await BacnetNetwork.listIpv4Interfaces()) {
        realByAddress[i.address] = i;
      }
    } catch (_) {
      // Fall back to /24 below
    }

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

          // Adresse broadcast réelle si connue, sinon simplification /24
          final real = realByAddress[addr.address];
          final broadcastAddress = real?.broadcast ?? '${parts[0]}.${parts[1]}.${parts[2]}.255';

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
            subnetMask: real != null ? prefixToSubnetMask(real.prefixLength) : null,
            isWireless: isWireless,
            isLoopback: addr.isLoopback,
          ));
        }
      }
    } catch (e) {
      // En cas d'erreur, retourner une liste vide
      // L'appelant utilisera le fallback sur toutes les interfaces
      debugPrint('NetworkInterfaceChoice.listAvailable failed: $e');
    }

    return result;
  }

  /// Dotted subnet mask of a /[prefixLength] network (e.g. 23 -> 255.255.254.0)
  static String prefixToSubnetMask(int prefixLength) {
    final p = prefixLength.clamp(0, 32);
    final mask = p == 0 ? 0 : (0xFFFFFFFF << (32 - p)) & 0xFFFFFFFF;
    return '${(mask >> 24) & 0xFF}.${(mask >> 16) & 0xFF}.${(mask >> 8) & 0xFF}.${mask & 0xFF}';
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
