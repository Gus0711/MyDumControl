import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Réponse HTTP minimale utilisée par la sonde.
class ProbeHttpResponse {
  final int statusCode;

  /// En-têtes, noms en minuscules (valeurs multiples jointes par ', ').
  final Map<String, String> headers;
  final String body;

  const ProbeHttpResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = '',
  });
}

/// GET sans identifiants, injectable pour les tests.
typedef ProbeHttpGet = Future<ProbeHttpResponse> Function(Uri uri, Duration timeout);

/// Résultat de la sonde d'un ECLYPSE découvert.
class EclypseProbeResult {
  /// L'automate a répondu en HTTP(S) sur le port testé.
  final bool reachable;

  /// 'V1' / 'V2' si la version a pu être déterminée sans identifiants,
  /// sinon null.
  final String? apiVersion;

  /// Code HTTP reçu sur la route V2 (null si injoignable).
  final int? statusCode;

  /// Pile serveur reconnue : 'karaf' (nouvelle génération, API V2) ou
  /// 'jetty' (ECLYPSE historique, V1 ou V2 impossible à distinguer sans
  /// identifiants).
  final String? serverStack;

  final String? error;

  const EclypseProbeResult({
    required this.reachable,
    this.apiVersion,
    this.statusCode,
    this.serverStack,
    this.error,
  });

  @override
  String toString() =>
      'EclypseProbeResult(reachable: $reachable, api: $apiVersion, status: $statusCode, stack: $serverStack, error: $error)';
}

/// Sonde non authentifiée d'un ECLYPSE : une seule requête GET, sans
/// identifiants, sur la route V2 `/api/rest/v2/services/platform`.
///
/// Comportement relevé sur le parc de test (sans identifiants) :
/// - ECLYPSE historiques (nginx + Jetty, `WWW-Authenticate: basic
///   realm="Radius"`) : 401 sur TOUTES les routes, y compris inexistantes
///   et y compris la route V2 d'un automate V1 seul (firmware 1.19). Le 401
///   ne prouve donc pas l'existence de la route : version indéterminée.
/// - ECLYPSE nouvelle génération (Karaf, `realm="karaf", bearer
///   realm="karaf"`, erreur JSON) : API V2.
/// Aucune information modèle/firmware n'est exposée sans identifiants.
class EclypseProbe {
  static const String v2ProbePath = '/api/rest/v2/services/platform';

  final ProbeHttpGet _httpGet;
  final Duration timeout;

  EclypseProbe({ProbeHttpGet? httpGet, this.timeout = const Duration(seconds: 4)})
      : _httpGet = httpGet ?? defaultHttpGet;

  Future<EclypseProbeResult> probe({
    required String host,
    required int port,
    required bool useHttps,
  }) async {
    final uri = Uri(
      scheme: useHttps ? 'https' : 'http',
      host: host,
      port: port,
      path: v2ProbePath,
    );
    try {
      final response = await _httpGet(uri, timeout).timeout(timeout + const Duration(seconds: 1));
      return EclypseProbeResult(
        reachable: true,
        statusCode: response.statusCode,
        apiVersion: apiVersionFromResponse(response),
        serverStack: serverStackOf(response),
      );
    } catch (e) {
      return EclypseProbeResult(reachable: false, error: e.toString());
    }
  }

  /// Déduit la version d'API de la réponse non authentifiée à la route V2.
  ///
  /// - 2xx : la route V2 existe -> V2.
  /// - 404 : la route V2 n'existe pas -> V1.
  /// - 401/403 : la route existe si la pile vérifie l'authentification
  ///   après le routage. C'est le cas de la pile Karaf (V2) ; la pile
  ///   Jetty « Radius » répond 401 avant routage, même sur un V1 seul :
  ///   indéterminé (null).
  /// - autre : indéterminé.
  static String? apiVersionFromResponse(ProbeHttpResponse response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return 'V2';
    if (status == 404) return 'V1';
    if (status == 401 || status == 403) {
      return serverStackOf(response) == 'karaf' ? 'V2' : null;
    }
    return null;
  }

  /// Identifie la pile serveur à partir des en-têtes / du corps.
  static String? serverStackOf(ProbeHttpResponse response) {
    final auth = (response.headers['www-authenticate'] ?? '').toLowerCase();
    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    if (auth.contains('karaf') || auth.contains('bearer')) return 'karaf';
    if (auth.contains('radius') || response.body.contains('Jetty')) return 'jetty';
    if (contentType.contains('application/json') && response.body.contains('HttpErrorStatus')) {
      return 'karaf';
    }
    return null;
  }

  /// GET via dart:io, sans identifiants ni redirection, certificat
  /// auto-signé accepté (rien de sensible n'est envoyé ni stocké).
  static Future<ProbeHttpResponse> defaultHttpGet(Uri uri, Duration timeout) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..badCertificateCallback = (cert, host, port) => true;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final headers = <String, String>{};
      response.headers.forEach((name, values) => headers[name.toLowerCase()] = values.join(', '));
      // Corps limité : seul le début sert à reconnaître la pile serveur
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= 4096) break;
      }
      return ProbeHttpResponse(
        statusCode: response.statusCode,
        headers: headers,
        body: utf8.decode(bytes, allowMalformed: true),
      );
    } finally {
      client.close(force: true);
    }
  }
}

/// Exécute des tâches asynchrones avec un nombre maximal en parallèle.
class BoundedTaskRunner {
  final int maxConcurrent;
  final Queue<Future<void> Function()> _pending = Queue();
  int _running = 0;

  BoundedTaskRunner({this.maxConcurrent = 4}) : assert(maxConcurrent > 0);

  int get running => _running;
  int get pending => _pending.length;

  /// Ajoute une tâche ; ses erreurs sont ignorées (elles doivent être
  /// gérées par la tâche elle-même).
  void add(Future<void> Function() task) {
    _pending.add(task);
    _pump();
  }

  /// Abandonne les tâches pas encore démarrées.
  void clear() => _pending.clear();

  void _pump() {
    while (_running < maxConcurrent && _pending.isNotEmpty) {
      final task = _pending.removeFirst();
      _running++;
      Future<void>.sync(task).catchError((Object _) {}).whenComplete(() {
        _running--;
        _pump();
      });
    }
  }
}
