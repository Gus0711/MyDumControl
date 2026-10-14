import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/connection_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/services/certificate_pinning.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';

/// Ecran d'affichage du synoptique Envysion via WebView
class EnvysionViewerScreen extends ConsumerStatefulWidget {
  final int connectionId;

  const EnvysionViewerScreen({
    super.key,
    required this.connectionId,
  });

  @override
  ConsumerState<EnvysionViewerScreen> createState() => _EnvysionViewerScreenState();
}

class _EnvysionViewerScreenState extends ConsumerState<EnvysionViewerScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  double _progress = 0;
  Connection? _connection;
  String? _password;

  @override
  void initState() {
    super.initState();
    _loadConnectionData();
  }

  Future<void> _loadConnectionData() async {
    final repository = ref.read(connectionRepositoryProvider);
    final connection = await repository.getConnectionById(widget.connectionId);

    if (connection != null) {
      final password = await repository.getPassword(connection.passwordKey);
      if (mounted) {
        setState(() {
          _connection = connection;
          _password = password;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.envysionConnectionNotFound;
          _isLoading = false;
        });
      }
    }
  }

  String _buildFullUrl() {
    if (_connection == null) return '';

    final protocol = _connection!.useHttps ? 'https' : 'http';
    final host = _connection!.host;
    final port = _connection!.port;
    final designerPath = _connection!.designerUrl ?? '';

    // Construire l'URL complete
    String url = '$protocol://$host';
    if ((protocol == 'https' && port != 443) || (protocol == 'http' && port != 80)) {
      url += ':$port';
    }
    url += designerPath;

    // Debug: afficher l'URL construite
    debugPrint('EnvysionViewer URL: $url (port configuré: $port)');

    return url;
  }

  /// True only if the HTTP auth challenge targets the configured controller
  /// (same host, and same port when the challenge reports one).
  bool _isChallengeFromController(URLProtectionSpace space) {
    final connection = _connection;
    if (connection == null) return false;
    if (space.host.toLowerCase() != connection.host.toLowerCase()) return false;
    final port = space.port;
    if (port != null && port > 0 && port != connection.port) return false;
    return true;
  }

  /// TOFU check of an untrusted (self-signed) certificate: without a pinned
  /// fingerprint, keep the historical behaviour (accept); otherwise accept
  /// only the controller itself presenting the pinned certificate.
  ServerTrustAuthResponseAction _serverTrustAction(URLProtectionSpace space) {
    final pinned = _connection?.certificateFingerprint;
    if (pinned == null || pinned.trim().isEmpty) {
      return ServerTrustAuthResponseAction.PROCEED;
    }
    if (!_isChallengeFromController(space)) {
      debugPrint('SSL Trust refused: ${space.host} is not the controller');
      return ServerTrustAuthResponseAction.CANCEL;
    }
    final der = space.sslCertificate?.x509Certificate?.encoded;
    if (der == null) {
      debugPrint('SSL Trust refused: no certificate data');
      return ServerTrustAuthResponseAction.CANCEL;
    }
    final presented = certificateFingerprintOfDer(der);
    if (checkCertificate(pinned, presented) != CertificateCheck.match) {
      debugPrint('SSL Trust refused: certificate fingerprint mismatch ($presented)');
      return ServerTrustAuthResponseAction.CANCEL;
    }
    return ServerTrustAuthResponseAction.PROCEED;
  }

  String _getBasicAuthHeader() {
    if (_connection == null || _password == null) return '';
    final credentials = '${_connection!.username}:$_password';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  /// Verifie si la plateforme supporte WebView integree
  bool _isWebViewSupported() {
    if (kIsWeb) return false; // Web : CORS bloque
    if (Platform.isAndroid || Platform.isIOS) return true;
    // Windows/Linux/macOS : ouvrir dans navigateur externe
    // (flutter_inappwebview_windows necessite NuGet)
    return false;
  }

  Future<void> _openInExternalBrowser() async {
    final url = _buildFullUrl();
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUnsupportedPlatformDialog() {
    final l10n = AppLocalizations.of(context)!;
    String platformName = 'Unknown';
    if (kIsWeb) {
      platformName = 'Web';
    } else if (Platform.isLinux) {
      platformName = 'Linux';
    } else if (Platform.isMacOS) {
      platformName = 'macOS';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.webViewNotSupported),
        content: Text(l10n.webViewNotSupportedMessage(platformName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openInExternalBrowser();
            },
            child: Text(l10n.openInBrowser),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Attendre le chargement des donnees de connexion
    if (_connection == null && _errorMessage == null) {
      return Scaffold(
        appBar: GradientAppBar(title: l10n.synopticEnvysion),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Erreur de chargement
    if (_errorMessage != null) {
      return Scaffold(
        appBar: GradientAppBar(title: l10n.synopticEnvysion),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(l10n.envysionLoadError, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openInExternalBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: Text(l10n.openInBrowser),
              ),
            ],
          ),
        ),
      );
    }

    // Plateforme non supportee
    if (!_isWebViewSupported()) {
      return Scaffold(
        appBar: GradientAppBar(title: l10n.synopticEnvysion),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.web_asset_off, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(l10n.webViewNotSupported, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.webViewNotSupportedMessage(//
                  kIsWeb ? 'Web' : Platform.operatingSystem,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openInExternalBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: Text(l10n.openInBrowser),
              ),
            ],
          ),
        ),
      );
    }

    // WebView supportee - afficher le contenu
    final url = _buildFullUrl();
    final authHeader = _getBasicAuthHeader();

    return Scaffold(
      appBar: GradientAppBar(
        title: _connection?.name ?? l10n.synopticEnvysion,
        actions: [
          // Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
            tooltip: l10n.refresh,
          ),
          // Bouton ouvrir dans navigateur
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInExternalBrowser,
            tooltip: l10n.openInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(url),
              headers: {
                'Authorization': authHeader,
              },
            ),
            initialSettings: InAppWebViewSettings(
              // Activer JavaScript
              javaScriptEnabled: true,
              // Desactiver le zoom
              supportZoom: true,
              // Mode desktop pour meilleur rendu
              preferredContentMode: UserPreferredContentMode.DESKTOP,
              // Autoriser le contenu mixte (HTTP dans HTTPS)
              mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
              // Cache
              cacheEnabled: true,
              // Aucun contenu file:// n'est charge : acces fichiers desactive
              allowFileAccessFromFileURLs: false,
              allowUniversalAccessFromFileURLs: false,
              // Permettre le stockage local (cookies, localStorage)
              domStorageEnabled: true,
              databaseEnabled: true,
              // Cookies tiers pour OIDC
              thirdPartyCookiesEnabled: true,
              saveFormData: false,
              // Garder les donnees entre sessions
              clearCache: false,
              clearSessionCache: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Permettre toutes les navigations vers le meme host
              final url = navigationAction.request.url?.toString() ?? '';
              debugPrint('Navigation to: $url');
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onLoadStop: (controller, url) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
              });
            },
            onProgressChanged: (controller, progress) {
              if (!mounted) return;
              setState(() {
                _progress = progress / 100;
              });
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // Certificats auto-signes : verifies contre l'empreinte TOFU
              debugPrint('SSL Trust Request for: ${challenge.protectionSpace.host}');
              return ServerTrustAuthResponse(
                action: _serverTrustAction(challenge.protectionSpace),
              );
            },
            onReceivedHttpAuthRequest: (controller, challenge) async {
              // Fournir les credentials pour l'authentification HTTP Basic
              debugPrint('HTTP Auth Request for: ${challenge.protectionSpace.host} (realm: ${challenge.protectionSpace.realm})');
              // Only answer challenges coming from the configured controller
              if (!_isChallengeFromController(challenge.protectionSpace)) {
                return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
              }
              return HttpAuthResponse(
                username: _connection!.username,
                password: _password ?? '',
                action: HttpAuthResponseAction.PROCEED,
                permanentPersistence: false,
              );
            },
            onReceivedError: (controller, request, error) {
              debugPrint('WebView Error: ${error.type} - ${error.description} for ${request.url}');
              // Ne pas afficher d'erreur pour les sous-ressources, seulement la page principale
              if (mounted && request.url.toString() == _buildFullUrl()) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = '${error.type}: ${error.description}';
                });
              }
            },
            onReceivedHttpError: (controller, request, response) {
              // Ignore sub-resources (favicon, assets...): main frame only
              if (!mounted || request.isForMainFrame != true) return;
              if (response.statusCode == 401) {
                setState(() {
                  _errorMessage = AppLocalizations.of(context)!.envysionAuthFailed;
                });
              } else if (response.statusCode == 404) {
                setState(() {
                  _errorMessage = AppLocalizations.of(context)!.envysionPageNotFound;
                });
              }
            },
          ),
          // Indicateur de progression
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.transparent,
              ),
            ),
          // Message de chargement
          if (_isLoading && _progress == 0)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.loadingEnvysion),
                    ],
                  ),
                ),
              ),
            ),
          // Message d'erreur overlay
          if (_errorMessage != null && !_isLoading)
            Center(
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.envysionLoadError,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isLoading = true;
                              });
                              _webViewController?.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _openInExternalBrowser,
                            icon: const Icon(Icons.open_in_browser),
                            label: Text(l10n.openInBrowser),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
