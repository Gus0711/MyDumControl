
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyGlobalDC is a Flutter cross-platform application for managing ECLYPSE building automation controllers from Distech Controls. It supports both API V1 (legacy controllers) and API V2 (ECLYPSE 400, 600 series, APEX).

**Current State**: Active development - core features implemented including connections, points browsing, trend logs, schedules, favorites, and dashboards.

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

Two Distech API versions must be supported. Reference: start with `docs/docs_API_Distech/INDEX.md` (conventions + one Markdown file per API domain in `v1/` and `v2/`); do not read the Postman JSON files directly (V2 is ~850k tokens). Regenerate the Markdown with `python3 docs/docs_API_Distech/postman_to_md.py`.

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
- `docs/docs_API_Distech/INDEX.md` - Distech API reference (Markdown, generated from the Postman collections)
- `docs/docs_API_Distech/API-V{1,2}.postman_collection.json` - Source Postman collections
- `pubspec.yaml` - Dependencies (currently minimal, planned deps in plan_init.md)

## Platform Targets

Android, iOS, Linux, macOS, Windows, Web (all configurations initialized)

## Dashboard & Multi-Curves Feature

### Overview
The dashboard feature allows users to create customizable dashboards with widgets displaying trend log data.

### Key Files
- `lib/presentation/screens/dashboard/dashboard_list_screen.dart` - List of dashboards
- `lib/presentation/screens/dashboard/dashboard_screen.dart` - Dashboard view with grid
- `lib/presentation/screens/dashboard/widgets/dashboard_widget_card.dart` - Widget card with title bar
- `lib/presentation/widgets/multi_curve_chart.dart` - Multi-curve chart widget
- `lib/presentation/widgets/curve_selection_dialog.dart` - Dialog to select trend logs
- `lib/application/providers/dashboard_provider.dart` - State management + widget configs
- `lib/application/providers/multi_curve_provider.dart` - Multi-curve data loading
- `lib/data/database/tables/dashboard_tables.dart` - Database tables (Dashboards, DashboardWidgets)

### Widget Types
- `singleTrendChart` - Single trend log history graph
- `multiCurveChart` - Compare 2-8 trend logs on same chart
- `statsCard` - Min/max/average statistics card

### Widget Configuration Classes
Located in `dashboard_provider.dart`:
- `SingleChartWidgetConfig` - trendLogInstance, title, pointName, units, colorTheme
- `MultiCurveWidgetConfig` - trendLogInstances[], title, curveNames{}, curveUnits{}
- `StatsWidgetConfig` - trendLogInstance, title, pointName, units, showMin/Max/Avg

Each config has:
- `toJson()` / `fromJson()` for serialization
- `displayTitle` getter for fallback title logic

### Database Schema (v11)
```sql
Dashboards: id, name, connectionId (nullable), columns, rows, sortOrder, createdAt, updatedAt
DashboardWidgets: id, dashboardId (FK), position, widgetType (enum), configJson, createdAt
```

### Key Patterns
- **Title bar on widgets**: `_WidgetHeader` in dashboard_widget_card.dart displays title + edit/delete buttons
- **Editable titles**: Click on title to edit, stored in config's `title` field
- **showHeader parameter**: `MultiCurveChart` has `showHeader: false` when embedded in dashboard to avoid duplicate title
- **Point name lookup**: Use `point.type.apiName` (dash format like `analog-input`) not `.name` (camelCase) when matching against `trendLogMappingProvider` keys

### Provider Flow for Multi-Curves
1. `MultiCurveChart` initializes `multiCurveViewerProvider(chartId)` with instances
2. Provider calls `trendLogViewerProvider(instance)` for each curve to load data
3. Data combined in `MultiCurveViewerState.data` with curve colors from `curveColorThemes`
