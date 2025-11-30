import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mydumcontrol/l10n/app_localizations.dart';
import '../../../application/providers/api_provider.dart';
import '../../../application/providers/connection_providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/validators.dart';

/// Écran d'ajout/modification d'une connexion
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

  bool _isPasswordVisible = false;
  bool _useHttps = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _detectedApiVersion;

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
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editConnection : l10n.addConnection),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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

            // Hôte
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
                if (!Validators.isValidHost(value!)) {
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

            // HTTPS Switch
            SwitchListTile(
              title: const Text('HTTPS'),
              subtitle: const Text('Utiliser une connexion sécurisée'),
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
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (!Validators.isNotEmpty(value)) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
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

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.testConnection(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text),
        useHttps: _useHttps,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.success) {
          // Stocker la version API détectée
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
              content: Text(result.errorMessage ?? 'Échec de la connexion'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(connectionRepositoryProvider);

      if (widget.isEditing) {
        // Mode édition
        await repository.updateConnection(
          id: int.parse(widget.connectionId!),
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text),
          useHttps: _useHttps,
          username: _usernameController.text.trim(),
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          apiVersion: _detectedApiVersion,
        );
      } else {
        // Mode création
        await repository.createConnection(
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text),
          useHttps: _useHttps,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          apiVersion: _detectedApiVersion,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Connexion modifiée'
                : 'Connexion enregistrée'),
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
