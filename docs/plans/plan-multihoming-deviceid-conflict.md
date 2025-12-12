# Plan : Multi-Homing et Détection de Conflits Device ID

## Objectifs

1. **Multi-Homing** : Permettre à l'utilisateur de sélectionner l'interface réseau à utiliser pour la communication BACnet
2. **Conflits Device ID** : Détecter et alerter quand plusieurs devices répondent avec le même Device ID

---

## 1. Multi-Homing (Sélection d'interface réseau)

### 1.1 Problème actuel

```dart
// bacnet_service.dart:69-70
_socket = await RawDatagramSocket.bind(
  InternetAddress.anyIPv4,  // Bind sur TOUTES les interfaces
  47808,
);
```

**Risques** :
- L'OS peut choisir la mauvaise interface pour envoyer les paquets
- Sur Windows, le broadcast peut ne pas fonctionner correctement avec 0.0.0.0
- Réponses perdues si envoyées sur une interface différente

### 1.2 Solution proposée

#### A. Nouveau modèle `NetworkInterfaceChoice`

**Fichier** : `lib/domain/models/network_interface_choice.dart`

```dart
/// Représente une interface réseau disponible pour BACnet
class NetworkInterfaceChoice {
  final String name;              // "Ethernet", "Wi-Fi", "eth0"
  final String address;           // "192.168.1.100"
  final String broadcastAddress;  // "192.168.1.255"
  final String? subnetMask;       // "255.255.255.0"
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

  /// Crée depuis une NetworkInterface Dart
  static Future<List<NetworkInterfaceChoice>> listAvailable() async {
    final result = <NetworkInterfaceChoice>[];
    final interfaces = await NetworkInterface.list();

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          // Ignorer loopback sauf si explicitement demandé
          if (addr.isLoopback) continue;

          final parts = addr.address.split('.');
          if (parts.length == 4) {
            result.add(NetworkInterfaceChoice(
              name: iface.name,
              address: addr.address,
              broadcastAddress: '${parts[0]}.${parts[1]}.${parts[2]}.255',
              isWireless: iface.name.toLowerCase().contains('wi') ||
                          iface.name.toLowerCase().contains('wlan'),
              isLoopback: addr.isLoopback,
            ));
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() => '$name ($address)';
}
```

#### B. Modification de `BacnetService`

**Fichier** : `lib/data/services/bacnet_service.dart`

```dart
class BacnetService {
  RawDatagramSocket? _socket;
  NetworkInterfaceChoice? _boundInterface;  // NOUVEAU
  // ...

  /// Initialise le socket UDP sur une interface spécifique
  /// [bindInterface] : Si null, utilise 0.0.0.0 (toutes les interfaces)
  Future<void> init({NetworkInterfaceChoice? bindInterface}) async {
    if (_isInitialized) return;
    // ...

    final bindAddress = bindInterface != null
        ? InternetAddress(bindInterface.address)
        : InternetAddress.anyIPv4;

    try {
      _socket = await RawDatagramSocket.bind(
        bindAddress,
        47808,
        reuseAddress: true,
      );
      _boundInterface = bindInterface;
      _logger.i('BACnet service bound to ${bindInterface?.address ?? "0.0.0.0"}:47808');
    } catch (e) {
      // Fallback port dynamique
      _socket = await RawDatagramSocket.bind(bindAddress, 0);
      _boundInterface = bindInterface;
      _logger.w('Could not bind to port 47808, using port ${_socket!.port}');
    }
    // ...
  }

  /// Interface actuellement utilisée
  NetworkInterfaceChoice? get boundInterface => _boundInterface;

  /// Réinitialise le service sur une nouvelle interface
  Future<void> rebindToInterface(NetworkInterfaceChoice? newInterface) async {
    dispose();
    _isInitialized = false;
    await init(bindInterface: newInterface);
  }

  /// Modifie _getLocalBroadcastAddresses pour utiliser l'interface bound
  Future<List<String>> _getLocalBroadcastAddresses() async {
    // Si une interface spécifique est sélectionnée, utiliser uniquement son broadcast
    if (_boundInterface != null) {
      return [_boundInterface!.broadcastAddress];
    }

    // Sinon, comportement actuel (toutes les interfaces)
    final broadcastAddresses = <String>[];
    // ... code existant ...
    return broadcastAddresses;
  }
}
```

#### C. Nouveau Provider pour les interfaces

**Fichier** : `lib/application/providers/network_interface_provider.dart`

```dart
/// Liste des interfaces réseau disponibles
final availableNetworkInterfacesProvider = FutureProvider<List<NetworkInterfaceChoice>>((ref) async {
  return NetworkInterfaceChoice.listAvailable();
});

/// Interface réseau sélectionnée pour BACnet (null = toutes)
final selectedBacnetInterfaceProvider = StateProvider<NetworkInterfaceChoice?>((ref) {
  return null;  // Par défaut : toutes les interfaces
});

/// Initialise le BacnetService avec l'interface sélectionnée
final bacnetServiceProvider = Provider<BacnetService>((ref) {
  final service = BacnetService();
  final selectedInterface = ref.watch(selectedBacnetInterfaceProvider);

  ref.keepAlive();

  // Réinitialiser si l'interface change
  ref.listen(selectedBacnetInterfaceProvider, (previous, next) {
    if (previous != next) {
      service.rebindToInterface(next);
    }
  });

  ref.onDispose(() => service.dispose());

  return service;
});
```

#### D. UI de sélection d'interface

**Fichier** : `lib/presentation/screens/connections/discover_bacnet_screen.dart`

Ajouter un sélecteur en haut de l'écran de découverte :

```dart
class _DiscoverBacnetScreenState extends ConsumerState<DiscoverBacnetScreen> {
  // ...

  Widget _buildInterfaceSelector(ThemeData theme) {
    final interfacesAsync = ref.watch(availableNetworkInterfacesProvider);
    final selectedInterface = ref.watch(selectedBacnetInterfaceProvider);

    return interfacesAsync.when(
      data: (interfaces) {
        if (interfaces.length <= 1) {
          // Une seule interface, pas besoin de sélecteur
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceVariant,
          child: Row(
            children: [
              Icon(Icons.lan, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<NetworkInterfaceChoice?>(
                  value: selectedInterface,
                  decoration: const InputDecoration(
                    labelText: 'Interface réseau',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toutes les interfaces'),
                    ),
                    ...interfaces.map((iface) => DropdownMenuItem(
                      value: iface,
                      child: Row(
                        children: [
                          Icon(
                            iface.isWireless ? Icons.wifi : Icons.cable,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('${iface.name} (${iface.address})'),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    ref.read(selectedBacnetInterfaceProvider.notifier).state = value;
                    // Relancer la découverte avec la nouvelle interface
                    _startBroadcastDiscovery();
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
```

---

## 2. Détection de Conflits Device ID

### 2.1 Problème actuel

```dart
// bacnet_service.dart:454-458
final deviceSubscription = iAmStream.listen((device) {
  // Éviter les doublons - GARDE LE PREMIER, IGNORE LES SUIVANTS
  if (!devices.any((d) => d.deviceId == device.deviceId)) {
    devices.add(device);
  }
});
```

**Problème** : Si 2 devices différents ont le même ID, seul le premier est gardé sans aucune alerte.

### 2.2 Solution proposée

#### A. Enrichir `IAmInfo` avec détection de conflits

**Fichier** : `lib/data/services/bacnet_service.dart`

```dart
/// Info d'un device répondant à Who-Is
class IAmInfo {
  final InternetAddress address;
  final int deviceId;
  final int? networkNumber;

  // NOUVEAU : Liste des autres adresses ayant répondu avec le même deviceId
  final List<InternetAddress> conflictingAddresses;

  // NOUVEAU : Indique s'il y a un conflit
  bool get hasConflict => conflictingAddresses.isNotEmpty;

  IAmInfo({
    required this.address,
    required this.deviceId,
    this.networkNumber,
    this.conflictingAddresses = const [],
  });

  /// Crée une copie avec une adresse conflictuelle ajoutée
  IAmInfo withConflict(InternetAddress conflictAddress) {
    return IAmInfo(
      address: address,
      deviceId: deviceId,
      networkNumber: networkNumber,
      conflictingAddresses: [...conflictingAddresses, conflictAddress],
    );
  }
}
```

#### B. Nouveau stream pour les conflits

**Fichier** : `lib/data/services/bacnet_service.dart`

```dart
class BacnetService {
  // Streams existants
  final _iAmController = StreamController<IAmInfo>.broadcast();
  Stream<IAmInfo> get iAmStream => _iAmController.stream;

  // NOUVEAU : Stream des conflits détectés
  final _conflictController = StreamController<DeviceIdConflict>.broadcast();
  Stream<DeviceIdConflict> get conflictStream => _conflictController.stream;

  // NOUVEAU : Cache des devices vus pour détecter les conflits
  final Map<int, IAmInfo> _seenDevices = {};

  void _handleIAm(BacnetResponse response, InternetAddress address) {
    if (response.objectInstance == null || _iAmController.isClosed) return;

    final deviceId = response.objectInstance!;
    final existingDevice = _seenDevices[deviceId];

    if (existingDevice != null) {
      // Device ID déjà vu
      if (existingDevice.address.address != address.address) {
        // CONFLIT : Même deviceId, adresse IP différente
        _logger.w('CONFLIT Device ID $deviceId: '
            '${existingDevice.address.address} ET ${address.address}');

        // Mettre à jour le device existant avec le conflit
        final updatedDevice = existingDevice.withConflict(address);
        _seenDevices[deviceId] = updatedDevice;

        // Émettre l'alerte de conflit
        if (!_conflictController.isClosed) {
          _conflictController.add(DeviceIdConflict(
            deviceId: deviceId,
            firstAddress: existingDevice.address,
            secondAddress: address,
            allAddresses: [existingDevice.address, ...updatedDevice.conflictingAddresses],
          ));
        }

        // Émettre aussi sur iAmStream pour mise à jour UI
        _iAmController.add(updatedDevice);
      }
      // Même adresse, même deviceId = juste un duplicate I-Am, ignorer
      return;
    }

    // Nouveau device
    final newDevice = IAmInfo(
      address: address,
      deviceId: deviceId,
    );
    _seenDevices[deviceId] = newDevice;
    _iAmController.add(newDevice);
  }

  /// Réinitialise le cache des devices vus (avant une nouvelle découverte)
  void clearSeenDevices() {
    _seenDevices.clear();
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    _seenDevices.clear();  // NOUVEAU
    // ...
    if (!_conflictController.isClosed) {  // NOUVEAU
      _conflictController.close();
    }
  }
}

/// Représente un conflit de Device ID détecté
class DeviceIdConflict {
  final int deviceId;
  final InternetAddress firstAddress;
  final InternetAddress secondAddress;
  final List<InternetAddress> allAddresses;
  final DateTime detectedAt;

  DeviceIdConflict({
    required this.deviceId,
    required this.firstAddress,
    required this.secondAddress,
    required this.allAddresses,
  }) : detectedAt = DateTime.now();

  @override
  String toString() => 'DeviceIdConflict(id=$deviceId, '
      'addresses=${allAddresses.map((a) => a.address).join(", ")})';
}
```

#### C. Modification de `discoverLocalDevices`

```dart
Future<List<IAmInfo>> discoverLocalDevices({
  int port = 47808,
  Duration timeout = const Duration(seconds: 5),
  int sendCount = 3,
  Duration sendInterval = const Duration(milliseconds: 800),
}) async {
  await init();

  // NOUVEAU : Réinitialiser le cache avant découverte
  clearSeenDevices();

  final devices = <IAmInfo>[];
  final conflicts = <DeviceIdConflict>[];

  final deviceSubscription = iAmStream.listen((device) {
    // Mettre à jour ou ajouter le device
    final existingIndex = devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (existingIndex != -1) {
      // Remplacer par la version mise à jour (avec conflits éventuels)
      devices[existingIndex] = device;
    } else {
      devices.add(device);
    }
  });

  // NOUVEAU : Écouter les conflits
  final conflictSubscription = conflictStream.listen((conflict) {
    conflicts.add(conflict);
    _logger.w('Conflict detected: $conflict');
  });

  try {
    // ... code existant d'envoi Who-Is ...

    await Future.delayed(timeout);

    // NOUVEAU : Logger un résumé des conflits
    if (conflicts.isNotEmpty) {
      _logger.w('Discovery completed with ${conflicts.length} Device ID conflicts!');
      for (final conflict in conflicts) {
        _logger.w('  - Device $conflict.deviceId on: '
            '${conflict.allAddresses.map((a) => a.address).join(", ")}');
      }
    }

    return devices;
  } finally {
    await deviceSubscription.cancel();
    await conflictSubscription.cancel();
  }
}
```

#### D. UI d'alerte des conflits

**Fichier** : `lib/presentation/screens/connections/discover_bacnet_screen.dart`

```dart
class _DiscoverBacnetScreenState extends ConsumerState<DiscoverBacnetScreen> {
  List<DiscoveredBacnetDevice> _discoveredDevices = [];
  List<DeviceIdConflict> _conflicts = [];  // NOUVEAU

  Future<void> _startBroadcastDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _conflicts = [];  // NOUVEAU
      _errorMessage = null;
    });

    try {
      final bacnetService = ref.read(bacnetServiceProvider);

      // NOUVEAU : Écouter les conflits
      final conflictSubscription = bacnetService.conflictStream.listen((conflict) {
        if (mounted) {
          setState(() {
            _conflicts.add(conflict);
          });
          // Afficher une alerte immédiate
          _showConflictSnackbar(conflict);
        }
      });

      // ... reste du code existant ...

      try {
        await bacnetService.discoverLocalDevices(/* ... */);
      } finally {
        await conflictSubscription.cancel();
      }

      // NOUVEAU : Afficher un dialog récapitulatif si conflits
      if (_conflicts.isNotEmpty && mounted) {
        _showConflictsDialog();
      }
    } catch (e) {
      // ...
    }
  }

  void _showConflictSnackbar(DeviceIdConflict conflict) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conflit Device ID ${conflict.deviceId} : '
                '${conflict.allAddresses.map((a) => a.address).join(" et ")}',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Détails',
          textColor: Colors.white,
          onPressed: _showConflictsDialog,
        ),
      ),
    );
  }

  void _showConflictsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Conflits Device ID'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plusieurs appareils partagent le même Device ID BACnet. '
                'Ceci est interdit par le protocole et peut causer des dysfonctionnements.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ..._conflicts.map((conflict) => Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device ID : ${conflict.deviceId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Adresses IP en conflit :'),
                      ...conflict.allAddresses.map((addr) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(addr.address),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Action recommandée : Reconfigurer les appareils pour avoir des Device ID uniques.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // Dans la liste des devices, marquer ceux en conflit
  Widget _buildDeviceCard(DiscoveredBacnetDevice device, ThemeData theme) {
    final hasConflict = _conflicts.any((c) => c.deviceId == device.deviceId);

    return Card(
      // Bordure orange si conflit
      shape: hasConflict
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.orange, width: 2),
            )
          : null,
      child: Stack(
        children: [
          // Contenu existant...
          _BacnetDeviceCard(device: device, onTap: () => _selectDevice(device)),

          // Badge de conflit
          if (hasConflict)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ID en conflit',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 3. Fichiers à créer/modifier

### Nouveaux fichiers

| Fichier | Description |
|---------|-------------|
| `lib/domain/models/network_interface_choice.dart` | Modèle d'interface réseau |
| `lib/application/providers/network_interface_provider.dart` | Providers pour sélection interface |

### Fichiers à modifier

| Fichier | Modifications |
|---------|---------------|
| `lib/data/services/bacnet_service.dart` | - `init(bindInterface)` paramètre<br>- `IAmInfo.conflictingAddresses`<br>- `DeviceIdConflict` classe<br>- `conflictStream`<br>- `_seenDevices` cache<br>- `clearSeenDevices()` |
| `lib/presentation/screens/connections/discover_bacnet_screen.dart` | - Sélecteur interface UI<br>- Alertes conflits<br>- Dialog récapitulatif<br>- Badge sur cards |
| `lib/l10n/app_fr.arb` | Textes traduits |
| `lib/l10n/app_en.arb` | Textes traduits |
| `lib/application/providers/bacnet_provider.dart` | Mise à jour pour supporter interface |

---

## 4. Plan d'implémentation

### Phase 1 : Multi-Homing (Priorité haute)

1. Créer `NetworkInterfaceChoice` model
2. Modifier `BacnetService.init()` pour accepter une interface
3. Ajouter `rebindToInterface()`
4. Créer les providers
5. Ajouter le sélecteur UI dans discover_bacnet_screen
6. Tests manuels sur machine multi-interface

### Phase 2 : Détection conflits Device ID (Priorité moyenne)

1. Enrichir `IAmInfo` avec `conflictingAddresses`
2. Créer `DeviceIdConflict` classe
3. Ajouter `conflictStream` et `_seenDevices`
4. Modifier `_handleIAm()` pour détecter les conflits
5. Modifier `discoverLocalDevices()` pour réinitialiser le cache
6. Ajouter alertes UI (snackbar + dialog)
7. Marquer visuellement les devices en conflit
8. Tests avec devices simulés ayant même ID

---

## 5. Considérations

### Multi-Homing
- Sur mobile (Android/iOS), généralement une seule interface active
- Utile principalement sur desktop (Windows/Linux/macOS)
- Le sélecteur ne s'affiche que s'il y a > 1 interface

### Conflits Device ID
- Cas rare en production mais très problématique quand ça arrive
- L'utilisateur doit être clairement informé
- Ne pas bloquer la sélection du device, juste alerter
- Logger les conflits pour diagnostic
