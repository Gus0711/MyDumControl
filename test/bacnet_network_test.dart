import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_network.dart';

void main() {
  test('broadcast address uses the real prefix length (A16)', () {
    expect(BacnetNetwork.broadcastFor('192.168.1.10', 24), '192.168.1.255');
    expect(BacnetNetwork.broadcastFor('192.168.1.10', 23), '192.168.1.255');
    expect(BacnetNetwork.broadcastFor('192.168.0.10', 23), '192.168.1.255');
    expect(BacnetNetwork.broadcastFor('10.0.5.3', 16), '10.0.255.255');
    expect(BacnetNetwork.broadcastFor('172.16.4.130', 25), '172.16.4.255');
    expect(BacnetNetwork.broadcastFor('172.16.4.10', 25), '172.16.4.127');
  });

  test('parses `ip -o -4 addr show` output', () {
    const output = '''
1: lo    inet 127.0.0.1/8 scope host lo\\       valid_lft forever preferred_lft forever
2: enp1s0    inet 192.168.122.50/24 brd 192.168.122.255 scope global dynamic noprefixroute enp1s0\\       valid_lft 3000sec
3: eth1    inet 10.20.0.7/16 scope global eth1\\       valid_lft forever
4: docker0    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0\\       valid_lft forever
5: wg0    inet 10.8.0.2/32 scope global wg0\\       valid_lft forever
6: eth0.10@eth0    inet 192.168.10.2/24 brd 192.168.10.255 scope global eth0.10
''';
    final list = BacnetNetwork.parseIpAddrOutput(output);
    expect(list.map((i) => '${i.name} ${i.address} ${i.broadcast}').toList(), [
      'lo 127.0.0.1 127.255.255.255',
      'enp1s0 192.168.122.50 192.168.122.255',
      'eth1 10.20.0.7 10.20.255.255',
      'docker0 172.17.0.1 172.17.255.255',
      'eth0.10 192.168.10.2 192.168.10.255',
    ]);
  });

  test('loopback and container/VM bridges are excluded', () {
    for (final name in ['lo', 'docker0', 'br-1a2b3c', 'veth12ab', 'virbr0', 'vboxnet0', 'vmnet8']) {
      expect(BacnetNetwork.isVirtualInterface(name), isTrue, reason: name);
    }
    for (final name in ['enp1s0', 'eth0', 'wlan0', 'wlp2s0', 'Ethernet']) {
      expect(BacnetNetwork.isVirtualInterface(name), isFalse, reason: name);
    }
  });
}
