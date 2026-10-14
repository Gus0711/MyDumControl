import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myglobaldc/l10n/app_localizations.dart';
import '../../../application/providers/api_provider.dart';
import '../../../application/providers/connection_providers.dart';
import '../../../application/providers/bacnet_provider.dart';
import '../../../application/providers/settings_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/router/routes.dart';
import '../../widgets/gradient_app_bar.dart';

/// Types de connexion supportes
enum ConnectionType {
  distechApi('distech_api', 'API Distech'),
  bacnet('bacnet', 'BACnet/IP');

  final String value;
  final String label;
  const ConnectionType(this.value, this.label);

  static ConnectionType fromValue(String value) {
    return ConnectionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConnectionType.distechApi,
    );
  }
}

/// Ecran d'ajout/modification d'une connexion
class AddConnectionScreen extends ConsumerStatefulWidget {
  final String? connectionId;

  const AddConnectionScreen({super.key, this.connectionId});

  bool get isEditing => connectionId != null;

  @override
  ConsumerState<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends ConsumerState<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(
    text: ApiConstants.defaultHttpsPort.toString(),
  );
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bacnetDeviceIdController = TextEditingController();
  final _designerUrlController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _useHttps = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _detectedApiVersion;
  ConnectionType _connectionType = ConnectionType.distechApi;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadConnection();
    }
  }

  Future<void> _loadConnection() async {
    final repository = ref.read(connectionRepositoryProvider);
    final connection = await repository.getConnectionById(int.parse(widget.connectionId!));
    if (connection != null && mounted) {
      setState(() {
        _nameController.text = connection.name;
        _hostController.text = connection.host;
        _portController.text = connection.port.toString();
        _usernameController.text = connection.username;
        _useHttps = connection.useHttps;
        _detectedApiVersion = connection.apiVersion;
        _connectionType = ConnectionType.fromValue(connection.connectionType);
        if (connection.bacnetDeviceId != null) {
          _bacnetDeviceIdController.text = connection.bacnetDeviceId.toString();
        }
        if (connection.designerUrl != null) {
          _designerUrlController.text = connection.designerUrl!;
        }
      });
    }
  }

  void _onConnectionTypeChanged(ConnectionType type) {
    setState(() {
      _connectionType = type;
      // Ajuster le port par defaut selon le type
      if (type == ConnectionType.bacnet) {
        _portController.text =
            ref.read(settingsProvider).defaultBacnetPort.toString();
        _useHttps = false;
      } else {
        _portController.text = _useHttps
            ? ApiConstants.defaultHttpsPort.toString()
            : ApiConstants.defaultHttpPort.toString();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _bacnetDeviceIdController.dispose();
    _designerUrlController.dispose();
    super.dispose();
  }

  /// Ouvre la page de decouverte ECLYPSE et recupere le resultat
  Future<void> _openDiscoverEclypse() async {
    final result = await context.push<Map<String, dynamic>>(Routes.discoverEclypse);
    if (result != null && mounted) {
      setState(() {
        if (result['name'] != null && _nameController.text.isEmpty) {
          _nameController.text = result['name'];
        }
        if (result['host'] != null) {
          _hostController.text = result['host'];
        }
        if (result['port'] != null) {
          _portController.text = result['port'].toString();
        }
        if (result['useHttps'] != null) {
          _useHttps = result['useHttps'];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['name'] ?? result['host']} selectionne'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Ouvre la page de decouverte BACnet et recupere le resultat
  Future<void> _openDiscoverBacnet() async {
    final result = await context.push<Map<String, dynamic>>(Routes.discoverBacnet);
    if (result != null && mounted) {
      setState(() {
        if (result['name'] != null && _nameController.text.isEmpty) {
          _nameController.text = result['name'];
        }
        if (result['host'] != null) {
          _hostController.text = result['host'];
        }
        if (result['port'] != null) {
          _portController.text = result['port'].toString();
        }
        if (result['deviceId'] != null) {
          _bacnetDeviceIdController.text = result['deviceId'].toString();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['name'] ?? result['host']} selectionne'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.isEditing ? l10n.editConnection : l10n.addConnection,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selecteur de type de connexion
            _buildConnectionTypeSelector(),
            const SizedBox(height: 24),

            // Bouton de decouverte (en premier!)
            _buildDiscoverButton(l10n),
            const SizedBox(height: 24),

            // Separateur "ou saisie manuelle"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.orManualEntry,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Nom de la connexion
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.connectionName,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (!Validators.isNotEmpty(value)) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hote
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: l10n.host,
                hintText: '192.168.1.100',
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (!Validators.isNotEmpty(value)) {
                  return l10n.fieldRequired;
                }
                if (!Validators.isValidHost(value!.trim())) {
                  return l10n.invalidHost;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Port
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: l10n.port,
                prefixIcon: const Icon(Icons.numbers),
                helperText: _connectionType == ConnectionType.bacnet
                    ? l10n.bacnetPortHelper
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (!Validators.isNotEmpty(value)) {
                  return l10n.fieldRequired;
                }
                if (!Validators.isValidPortString(value!)) {
                  return l10n.invalidPort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champs specifiques selon le type de connexion
            if (_connectionType == ConnectionType.distechApi) ...[
              // HTTPS Switch (API Distech uniquement)
              SwitchListTile(
                title: const Text('HTTPS'),
                subtitle: const Text('Utiliser une connexion securisee'),
                value: _useHttps,
                onChanged: (value) {
                  setState(() {
                    _useHttps = value;
                    if (value) {
                      _portController.text =
                          ApiConstants.defaultHttpsPort.toString();
                    } else {
                      _portController.text =
                          ApiConstants.defaultHttpPort.toString();
                    }
                  });
                },
                secondary: Icon(_useHttps ? Icons.lock : Icons.lock_open),
              ),
              const Divider(height: 32),

              // Nom d'utilisateur
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (!Validators.isNotEmpty(value)) {
                    return l10n.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (!widget.isEditing && !Validators.isNotEmpty(value)) {
                    return l10n.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section Envysion Designer (optionnel)
              Text(
                l10n.envysionDesignerSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _designerUrlController,
                decoration: InputDecoration(
                  labelText: l10n.designerUrl,
                  hintText: '/eclypse/envysion/viewer.html?proj=MON_PROJET',
                  prefixIcon: const Icon(Icons.web),
                  helperText: l10n.designerUrlHelper,
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
            ] else ...[
              // Champs BACnet
              // Device ID BACnet (optionnel en local)
              TextFormField(
                controller: _bacnetDeviceIdController,
                decoration: InputDecoration(
                  labelText: l10n.bacnetDeviceIdOptional,
                  prefixIcon: const Icon(Icons.memory),
                  helperText: l10n.bacnetDeviceIdHelper,
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
              ),
            ],
            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(l10n.testConnection),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveConnection,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de connexion',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ConnectionType>(
          segments: [
            ButtonSegment<ConnectionType>(
              value: ConnectionType.distechApi,
              label: const Text('API Distech'),
              icon: const Icon(Icons.api),
            ),
            ButtonSegment<ConnectionType>(
              value: ConnectionType.bacnet,
              label: const Text('BACnet/IP'),
              icon: const Icon(Icons.device_hub),
            ),
          ],
          selected: {_connectionType},
          onSelectionChanged: (selection) {
            _onConnectionTypeChanged(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildDiscoverButton(AppLocalizations l10n) {
    if (_connectionType == ConnectionType.distechApi) {
      // Bouton decouverte ECLYPSE
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openDiscoverEclypse,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wifi_find,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.discoverEclypse,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.discoverEclypseSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Bouton decouverte BACnet
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openDiscoverBacnet,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.device_hub,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.discoverDevices,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.broadcastDiscoverySubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      if (_connectionType == ConnectionType.distechApi) {
        await _testDistechConnection();
      } else {
        await _testBacnetConnection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _testDistechConnection() async {
    final apiService = ref.read(apiServiceProvider);
    var password = _passwordController.text;
    // Editing: the password field is left empty, reuse the stored secret
    if (password.isEmpty && widget.isEditing) {
      final repository = ref.read(connectionRepositoryProvider);
      final existing =
          await repository.getConnectionById(int.parse(widget.connectionId!));
      if (existing != null) {
        password = await repository.getPassword(existing.passwordKey) ?? '';
      }
    }
    final result = await apiService.testConnection(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text),
      useHttps: _useHttps,
      username: _usernameController.text.trim(),
      password: password,
    );

    if (mounted) {
      if (result.success) {
        setState(() {
          _detectedApiVersion = result.apiVersion;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.connectionSuccess} (API ${result.apiVersion})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Echec de la connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testBacnetConnection() async {
    final bacnetService = ref.read(bacnetServiceProvider);

    final result = await bacnetService.testConnection(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text),
      deviceId: _bacnetDeviceIdController.text.isNotEmpty
          ? int.parse(_bacnetDeviceIdController.text)
          : null,
    );

    if (mounted) {
      if (result.success) {
        // Mettre a jour le Device ID si decouvert
        if (result.deviceId != null && _bacnetDeviceIdController.text.isEmpty) {
          setState(() {
            _bacnetDeviceIdController.text = result.deviceId.toString();
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connexion BACnet reussie! Device ID: ${result.deviceId ?? "non decouvert"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Echec de la connexion BACnet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(connectionRepositoryProvider);

      // Preparer les valeurs selon le type de connexion
      final username = _connectionType == ConnectionType.bacnet
          ? 'bacnet'  // Placeholder pour BACnet
          : _usernameController.text.trim();
      final password = _connectionType == ConnectionType.bacnet
          ? ''  // Pas de mot de passe pour BACnet
          : _passwordController.text;
      final bacnetDeviceId = _bacnetDeviceIdController.text.isNotEmpty
          ? int.parse(_bacnetDeviceIdController.text)
          : null;
      // Designer URL (API Distech uniquement)
      final designerUrl = _connectionType == ConnectionType.distechApi &&
              _designerUrlController.text.trim().isNotEmpty
          ? _designerUrlController.text.trim()
          : null;

      if (widget.isEditing) {
        await repository.updateConnection(
          id: int.parse(widget.connectionId!),
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text),
          useHttps: _useHttps,
          username: username,
          password: password.isNotEmpty ? password : null,
          apiVersion: _detectedApiVersion,
          connectionType: _connectionType.value,
          bacnetDeviceId: bacnetDeviceId,
          designerUrl: designerUrl,
        );
      } else {
        await repository.createConnection(
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text),
          useHttps: _useHttps,
          username: username,
          password: password,
          apiVersion: _detectedApiVersion,
          connectionType: _connectionType.value,
          bacnetDeviceId: bacnetDeviceId,
          designerUrl: designerUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Connexion modifiee'
                : 'Connexion enregistree'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
