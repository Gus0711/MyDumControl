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
import '../../../data/services/certificate_pinning.dart';
import '../../../data/services/api_service.dart' show ConnectionTestResult;
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';

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

  /// Endpoint (scheme/host/port) on which [_detectedApiVersion] was detected:
  /// a version detected on another endpoint must not be saved.
  String? _detectedEndpoint;
  ConnectionType _connectionType = ConnectionType.distechApi;

  /// Result of the last connection test, shown under the form.
  bool _testSuccess = false;
  String? _testMessage;

  /// Certificate fingerprint seen by the last successful HTTPS test, and the
  /// endpoint (scheme/host/port) it was seen on.
  String? _testedFingerprint;
  String? _testedEndpoint;

  /// Fingerprint pinned for the edited connection, and its endpoint.
  String? _storedFingerprint;
  String? _storedEndpoint;

  String get _currentEndpoint =>
      '${_useHttps ? 'https' : 'http'}://${_hostController.text.trim()}:${_portController.text.trim()}';

  /// Fingerprint of the last test, if it was made on the current endpoint.
  String? get _currentTestedFingerprint =>
      _testedEndpoint == _currentEndpoint ? _testedFingerprint : null;

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
        _detectedEndpoint =
            '${connection.useHttps ? 'https' : 'http'}://${connection.host}:${connection.port}';
        _storedFingerprint = connection.certificateFingerprint;
        _storedEndpoint =
            '${connection.useHttps ? 'https' : 'http'}://${connection.host}:${connection.port}';
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
      // Version API / modele detectes sans identifiants : information
      // seulement, la version enregistree reste celle du test authentifie.
      final details = [
        if (result['apiVersion'] != null) 'API ${result['apiVersion']}',
        if (result['model'] != null) '${result['model']}',
      ].join(', ');
      final label = '${result['name'] ?? result['host']}${details.isNotEmpty ? ' ($details)' : ''}';
      ScaffoldMessenger.of(context).showSnackBar(
        dcSnackBar(
          AppLocalizations.of(context)!.addConnSelected(label),
          color: AppSnackColors.success,
          icon: Icons.check_circle_rounded,
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
        dcSnackBar(
          AppLocalizations.of(context)!.addConnSelected('${result['name'] ?? result['host']}'),
          color: AppSnackColors.success,
          icon: Icons.check_circle_rounded,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final isApi = _connectionType == ConnectionType.distechApi;
    final manualLabel = l10n.orManualEntry.replaceAll(RegExp(r'\s*:\s*$'), '');

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.isEditing ? l10n.editConnection : l10n.addConnection,
        subtitle: widget.isEditing && _nameController.text.isNotEmpty ? _nameController.text : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            DcContent(
              maxWidth: 720,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selecteur de type de connexion
                  _buildConnectionTypeSelector(l10n),
                  const SizedBox(height: 16),

                  // Bouton de decouverte (en premier!)
                  _buildDiscoverButton(l10n),
                  const SizedBox(height: 20),

                  // Separateur "ou saisie manuelle"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          manualLabel.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(color: dc.textMuted),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // === Adresse ===
                  _FormSection(
                    title: l10n.frmSectionAddress,
                    icon: Icons.lan_outlined,
                    children: [
                      // Nom de la connexion
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.connectionName,
                          prefixIcon: const Icon(Icons.label_outline_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!Validators.isNotEmpty(value)) {
                            return l10n.fieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final host = _buildHostField(l10n);
                          final port = _buildPortField(l10n);
                          if (constraints.maxWidth < 460) {
                            return Column(children: [host, const SizedBox(height: 14), port]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: host),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: port),
                            ],
                          );
                        },
                      ),
                      if (isApi) ...[
                        const SizedBox(height: 8),
                        // HTTPS Switch (API Distech uniquement)
                        _buildHttpsSwitch(l10n),
                        if (!_useHttps) ...[
                          const SizedBox(height: 4),
                          DcBanner(
                            tone: dc.warning,
                            icon: Icons.warning_amber_rounded,
                            message: l10n.httpCleartextWarning,
                            dense: true,
                          ),
                        ],
                      ],
                    ],
                  ),

                  // Champs specifiques selon le type de connexion
                  if (isApi) ...[
                    // === Authentification ===
                    _FormSection(
                      title: l10n.frmSectionAuth,
                      icon: Icons.key_rounded,
                      children: [
                        // Nom d'utilisateur
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (!Validators.isNotEmpty(value)) {
                              return l10n.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
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
                      ],
                    ),

                    // === Synoptique Envysion (optionnel) ===
                    _FormSection(
                      title: l10n.envysionDesignerSection,
                      icon: Icons.web_rounded,
                      children: [
                        TextFormField(
                          controller: _designerUrlController,
                          style: AppTextStyles.monospacedValue.copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: l10n.designerUrl,
                            hintText: '/eclypse/envysion/viewer.html?proj=MON_PROJET',
                            prefixIcon: const Icon(Icons.link_rounded),
                            helperText: l10n.designerUrlHelper,
                            helperMaxLines: 2,
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ] else ...[
                    // === Identification BACnet ===
                    _FormSection(
                      title: l10n.frmSectionBacnet,
                      icon: Icons.memory_rounded,
                      children: [
                        // Device ID BACnet (optionnel en local)
                        TextFormField(
                          controller: _bacnetDeviceIdController,
                          style: AppTextStyles.monospacedValue.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: l10n.bacnetDeviceIdOptional,
                            prefixIcon: const Icon(Icons.tag_rounded),
                            helperText: l10n.bacnetDeviceIdHelper,
                            helperMaxLines: 2,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ],

                  // Resultat du dernier test
                  if (_testMessage != null) ...[
                    const SizedBox(height: 16),
                    DcBanner(
                      tone: _testSuccess ? dc.success : dc.danger,
                      icon: _testSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      title: _testSuccess ? l10n.connectionSuccess : l10n.connectionFailed,
                      message: _testMessage,
                    ),
                  ],
                  if (isApi && _currentTestedFingerprint != null) ...[
                    const SizedBox(height: 12),
                    _buildFingerprintCard(l10n, _currentTestedFingerprint!),
                  ],
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check_rounded),
                        label: Text(l10n.testConnection),
                      ),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveConnection,
                        icon: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostField(AppLocalizations l10n) {
    return TextFormField(
      controller: _hostController,
      style: AppTextStyles.monospacedValue.copyWith(fontSize: 14),
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
    );
  }

  Widget _buildPortField(AppLocalizations l10n) {
    return TextFormField(
      controller: _portController,
      style: AppTextStyles.monospacedValue.copyWith(fontSize: 14),
      decoration: InputDecoration(
        labelText: l10n.port,
        prefixIcon: const Icon(Icons.numbers_rounded),
        helperText: _connectionType == ConnectionType.bacnet ? l10n.bacnetPortHelper : null,
        helperMaxLines: 2,
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
    );
  }

  Widget _buildHttpsSwitch(AppLocalizations l10n) {
    final dc = context.dc;
    final tone = _useHttps ? dc.success : dc.warning;
    void toggle(bool value) {
      setState(() {
        _useHttps = value;
        if (value) {
          _portController.text = ApiConstants.defaultHttpsPort.toString();
        } else {
          _portController.text = ApiConstants.defaultHttpPort.toString();
        }
      });
    }

    return InkWell(
      borderRadius: BorderRadius.circular(DcRadius.md),
      onTap: () => toggle(!_useHttps),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            DcIconBox(
              icon: _useHttps ? Icons.lock_rounded : Icons.lock_open_rounded,
              tone: tone,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HTTPS', style: context.text.titleSmall),
                  Text(l10n.addConnUseSecure, style: context.text.bodySmall?.copyWith(color: dc.textSecondary)),
                ],
              ),
            ),
            Switch(value: _useHttps, onChanged: toggle),
          ],
        ),
      ),
    );
  }

  /// Shows the certificate fingerprint seen by the connection test.
  Widget _buildFingerprintCard(AppLocalizations l10n, String fingerprint) {
    final dc = context.dc;
    final stored = _storedEndpoint == _currentEndpoint ? _storedFingerprint : null;
    final differs = stored != null &&
        checkCertificate(stored, fingerprint) == CertificateCheck.mismatch;
    final tone = differs ? dc.warning : dc.success;
    return DcBanner(
      tone: tone,
      icon: differs ? Icons.gpp_maybe_outlined : Icons.verified_user_outlined,
      title: l10n.certificateFingerprintLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          SelectableText(
            fingerprint,
            style: AppTextStyles.monospacedValue.copyWith(fontSize: 11.5, color: dc.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            differs ? l10n.certificateFingerprintDiffers : l10n.certificateFingerprintPinnedInfo,
            style: context.text.bodySmall?.copyWith(color: differs ? tone.fg : dc.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTypeSelector(AppLocalizations l10n) {
    final dc = context.dc;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.addConnConnectionType.toUpperCase(),
            style: AppTextStyles.overline.copyWith(color: dc.textMuted),
          ),
        ),
        SegmentedButton<ConnectionType>(
          segments: const [
            ButtonSegment<ConnectionType>(
              value: ConnectionType.distechApi,
              label: Text('API Distech'),
              icon: Icon(Icons.memory_rounded, size: 18),
            ),
            ButtonSegment<ConnectionType>(
              value: ConnectionType.bacnet,
              label: Text('BACnet/IP'),
              icon: Icon(Icons.lan_outlined, size: 18),
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
    final dc = context.dc;
    final isApi = _connectionType == ConnectionType.distechApi;
    // Decouverte ECLYPSE (mDNS) ou BACnet (Who-Is)
    final tone = isApi ? dc.accentTone : dc.violet;
    return _DiscoverCard(
      tone: tone,
      icon: isApi ? Icons.wifi_find_rounded : Icons.radar_rounded,
      title: isApi ? l10n.discoverEclypse : l10n.discoverDevices,
      subtitle: isApi ? l10n.discoverEclypseSubtitle : l10n.broadcastDiscoverySubtitle,
      onTap: isApi ? _openDiscoverEclypse : _openDiscoverBacnet,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    try {
      if (_connectionType == ConnectionType.distechApi) {
        await _testDistechConnection();
      } else {
        await _testBacnetConnection();
      }
    } catch (e) {
      if (mounted) {
        _showTestResult(false, AppLocalizations.of(context)!.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _testDistechConnection() async {
    final result = await _runDistechTest();

    if (mounted) {
      if (result.success) {
        _showTestResult(true, 'API ${result.apiVersion}');
      } else {
        _showTestResult(false, result.errorMessage ?? AppLocalizations.of(context)!.connectionFailed);
      }
    }
  }

  /// Shows the result of a connection test under the form.
  void _showTestResult(bool success, String message) {
    setState(() {
      _testSuccess = success;
      _testMessage = message;
    });
  }

  /// Tests the Distech connection with the form values and, on success,
  /// records the API version and certificate for the current endpoint.
  Future<ConnectionTestResult> _runDistechTest() async {
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

    if (mounted && result.success) {
      setState(() {
        _detectedApiVersion = result.apiVersion;
        _detectedEndpoint = _currentEndpoint;
        _testedFingerprint = result.certificateFingerprint;
        _testedEndpoint = _currentEndpoint;
      });
    }
    return result;
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
        _showTestResult(
          true,
          AppLocalizations.of(context)!.addConnBacnetSuccess(
            result.deviceId?.toString() ?? AppLocalizations.of(context)!.addConnNotDiscovered,
          ),
        );
      } else {
        _showTestResult(false, result.errorMessage ?? AppLocalizations.of(context)!.addConnBacnetFailed);
      }
    }
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(connectionRepositoryProvider);

      // Version API : jamais enregistrer une version absente ou detectee sur
      // un autre endpoint, sinon un automate V1 serait interroge en V2 (404).
      if (_connectionType == ConnectionType.distechApi &&
          (_detectedApiVersion == null || _detectedEndpoint != _currentEndpoint)) {
        try {
          final result = await _runDistechTest();
          if (!result.success && mounted) {
            setState(() {
              _detectedApiVersion = null;
              _detectedEndpoint = null;
            });
          }
        } catch (_) {
          // Automate injoignable : la version sera detectee a la connexion
        }
        if (!mounted) return;
      }
      final apiVersion = _connectionType == ConnectionType.distechApi &&
              _detectedEndpoint == _currentEndpoint
          ? _detectedApiVersion
          : null;

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
      // Certificate seen by a successful test on this endpoint (TOFU)
      final certificateFingerprint =
          _connectionType == ConnectionType.distechApi && _useHttps
              ? _currentTestedFingerprint
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
          apiVersion: apiVersion,
          connectionType: _connectionType.value,
          bacnetDeviceId: bacnetDeviceId,
          designerUrl: designerUrl,
          certificateFingerprint: certificateFingerprint,
        );
      } else {
        await repository.createConnection(
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text),
          useHttps: _useHttps,
          username: username,
          password: password,
          apiVersion: apiVersion,
          connectionType: _connectionType.value,
          bacnetDeviceId: bacnetDeviceId,
          designerUrl: designerUrl,
          certificateFingerprint: certificateFingerprint,
        );
      }

      // Password may have been entered again: refresh the list badges
      ref.invalidate(connectionHasPasswordProvider);

      if (mounted) {
        context.showSuccess(widget.isEditing
            ? AppLocalizations.of(context)!.addConnUpdated
            : AppLocalizations.of(context)!.addConnSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showError(AppLocalizations.of(context)!.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Section titrée du formulaire (carte).
class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DcSectionHeader(title, icon: icon, padding: const EdgeInsets.fromLTRB(4, 18, 4, 8)),
        DcCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          color: dc.surface,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ],
    );
  }
}

/// Carte d'accès à la découverte réseau (ECLYPSE ou BACnet).
class _DiscoverCard extends StatefulWidget {
  final DcTone tone;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DiscoverCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<_DiscoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final t = widget.tone;
    final radius = BorderRadius.circular(DcRadius.lg);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _hover ? t.fg.withValues(alpha: 0.6) : t.border),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [t.bg, dc.surface],
        ),
        boxShadow: _hover ? dc.raisedShadow : dc.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (h) => setState(() => _hover = h),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                DcIconBox(icon: widget.icon, tone: t, size: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: context.text.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 160),
                  offset: Offset(_hover ? 0.15 : 0, 0),
                  child: Icon(Icons.arrow_forward_rounded, color: _hover ? t.fg : dc.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
