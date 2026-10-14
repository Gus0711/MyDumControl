import 'dart:io';

/// IPv4 address of a local interface with its real broadcast address
class LocalIpv4Interface {
  final String name;
  final String address;
  final int prefixLength;
  final String broadcast;

  const LocalIpv4Interface({
    required this.name,
    required this.address,
    required this.prefixLength,
    required this.broadcast,
  });

  @override
  String toString() => '$name $address/$prefixLength brd $broadcast';
}

/// Network helpers for BACnet/IP broadcasts
class BacnetNetwork {
  /// Interfaces that never carry a BACnet network: loopback, Docker,
  /// libvirt/VirtualBox/VMware bridges, virtual ethernet pairs.
  static bool isVirtualInterface(String name) {
    final n = name.toLowerCase();
    return n == 'lo' ||
        n.startsWith('docker') ||
        n.startsWith('br-') ||
        n.startsWith('veth') ||
        n.startsWith('virbr') ||
        n.startsWith('vboxnet') ||
        n.startsWith('vmnet') ||
        n.startsWith('podman') ||
        n.startsWith('cni') ||
        n.startsWith('flannel');
  }

  /// Directed broadcast address of [ip] with a /[prefixLength] mask
  static String broadcastFor(String ip, int prefixLength) {
    final parts = ip.split('.').map(int.parse).toList();
    final value = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];
    final hostMask = prefixLength >= 32 ? 0 : (0xFFFFFFFF >> prefixLength);
    final b = (value | hostMask) & 0xFFFFFFFF;
    return '${(b >> 24) & 0xFF}.${(b >> 16) & 0xFF}.${(b >> 8) & 0xFF}.${b & 0xFF}';
  }

  /// Parses the output of `ip -o -4 addr show`, e.g.
  /// `2: enp1s0    inet 192.168.1.10/23 brd 192.168.1.255 scope global enp1s0`
  static List<LocalIpv4Interface> parseIpAddrOutput(String output) {
    final result = <LocalIpv4Interface>[];
    final re = RegExp(r'^\d+:\s+(\S+)\s+inet\s+(\d+\.\d+\.\d+\.\d+)/(\d+)(?:\s+brd\s+(\d+\.\d+\.\d+\.\d+))?');
    for (final line in output.split('\n')) {
      final m = re.firstMatch(line.trim());
      if (m == null) continue;
      final name = m.group(1)!.split('@').first;
      final address = m.group(2)!;
      final prefix = int.parse(m.group(3)!);
      if (prefix >= 31) continue; // point-to-point, no broadcast
      result.add(LocalIpv4Interface(
        name: name,
        address: address,
        prefixLength: prefix,
        broadcast: m.group(4) ?? broadcastFor(address, prefix),
      ));
    }
    return result;
  }

  /// Lists the local IPv4 interfaces with their real broadcast address.
  /// Uses `ip` on Linux (Dart does not expose the netmask); elsewhere, or if
  /// `ip` is unavailable, falls back to a /24 assumption.
  static Future<List<LocalIpv4Interface>> listIpv4Interfaces() async {
    if (Platform.isLinux) {
      try {
        final r = await Process.run('ip', ['-o', '-4', 'addr', 'show'])
            .timeout(const Duration(seconds: 2));
        if (r.exitCode == 0) {
          final parsed = parseIpAddrOutput(r.stdout.toString());
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {
        // Fall back below
      }
    }

    final result = <LocalIpv4Interface>[];
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type != InternetAddressType.IPv4 || addr.isLoopback) continue;
          result.add(LocalIpv4Interface(
            name: iface.name,
            address: addr.address,
            prefixLength: 24,
            broadcast: broadcastFor(addr.address, 24),
          ));
        }
      }
    } catch (_) {
      // No interface information available
    }
    return result;
  }
}
