import 'package:crypto/crypto.dart';

/// TOFU (trust on first use) pinning of controller TLS certificates.
///
/// Distech controllers use self-signed certificates: the SHA-256 fingerprint
/// seen on the first successful connection is stored with the connection,
/// later connections are refused if the controller presents another one.
///
/// Note: only certificates rejected by the platform trust store (self-signed,
/// unknown CA, wrong host name) go through the pinning check; a certificate
/// signed by a trusted CA is accepted by the platform as usual.

/// SHA-256 fingerprint of a DER-encoded certificate, formatted `AA:BB:...`.
String certificateFingerprintOfDer(List<int> der) {
  return sha256
      .convert(der)
      .bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(':')
      .toUpperCase();
}

/// Normalizes a fingerprint for comparison (case, separators, spaces).
String normalizeFingerprint(String fingerprint) =>
    fingerprint.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();

/// Outcome of the comparison between a stored and a presented certificate.
enum CertificateCheck {
  /// No fingerprint stored yet: accept and store the presented one.
  trustOnFirstUse,

  /// Presented certificate matches the stored fingerprint.
  match,

  /// Presented certificate differs from the stored fingerprint: refuse.
  mismatch,
}

/// Compares the [stored] fingerprint (null/empty = none yet) with the
/// [presented] one.
CertificateCheck checkCertificate(String? stored, String presented) {
  if (stored == null || stored.trim().isEmpty) return CertificateCheck.trustOnFirstUse;
  return normalizeFingerprint(stored) == normalizeFingerprint(presented)
      ? CertificateCheck.match
      : CertificateCheck.mismatch;
}
