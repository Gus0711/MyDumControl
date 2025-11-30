# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyDumControl is a Flutter cross-platform application for managing ECLYPSE building automation controllers from Distech Controls. It supports both API V1 (legacy controllers) and API V2 (ECLYPSE 400, 600 series, APEX).

**Current State**: Early stage - boilerplate Flutter app with comprehensive architectural planning in `plan_init.md` (French). Implementation not yet started.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run linting/analysis
flutter analyze

# Generate code (Drift, Riverpod, Freezed) - once dependencies added
dart run build_runner build --delete-conflicting-outputs

# Run on platforms
flutter run -d linux
flutter run -d chrome
flutter run -d android
flutter run -d windows

# Build for production
flutter build apk
flutter build web
flutter build windows
flutter build linux
```

## Testing

```bash
# Run all tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## Architecture

The project follows Clean Architecture with 4 layers (planned but not yet implemented):

```
lib/
├── core/           # Network, router, theme, platform detection, utilities
├── data/           # DTOs, repositories impl, datasources (local/remote)
├── domain/         # Entities, repository interfaces, use cases
├── application/    # Riverpod providers and notifiers
└── presentation/   # Screens, widgets, controllers
```

**Key Patterns**:
- State Management: Riverpod 2.x
- Navigation: GoRouter
- Network: Dio with custom certificate handling
- Database: Drift (SQLite ORM)
- Serialization: Freezed + json_serializable

## API Integration

Two Distech API versions must be supported (see `docs_API_Distech/`):

- **API V1**: Legacy controllers, Basic Auth, BACnet object endpoints
- **API V2**: Modern controllers, Token/OAuth2 auth, batch operations

The app auto-detects API version at connection time (try V2 first, fallback to V1).

## Critical Implementation Details

### Self-Signed Certificates
Controllers use self-signed HTTPS certificates. Implement TOFU (Trust On First Use):
- Store certificate fingerprint on first connection
- Validate fingerprint on subsequent connections
- Use `badCertificateCallback` in HttpClient for native platforms

### Web Platform
Flutter Web cannot directly connect to controllers (CORS). Requires Node.js proxy backend in `backend_proxy/` directory (not yet created).

### Authentication
- HTTP Basic Auth (username:password base64 encoded)
- Cloud relay (Atrius) uses OAuth2 Bearer tokens
- Store credentials securely via `flutter_secure_storage`

## Key Files

- `plan_init.md` - Detailed architecture blueprint (French, 1600+ lines)
- `docs_API_Distech/API-V1.postman_collection.json` - Legacy API reference
- `docs_API_Distech/API-V2.postman_collection.json` - Modern API reference
- `pubspec.yaml` - Dependencies (currently minimal, planned deps in plan_init.md)

## Platform Targets

Android, iOS, Linux, macOS, Windows, Web (all configurations initialized)
