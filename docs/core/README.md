# Core Layer Documentation

The core layer contains shared utilities, constants, and configurations used throughout the application.

## Directory Structure

```
core/
├── constants/          # API constants and configuration
├── theme/             # Theme configuration
└── utils/             # Utility functions
```

## Constants (`constants/`)

### `api_constants.dart`

Contains API endpoint definitions and configuration:

- **Base URL**: Server base URL configuration
- **API Endpoints**: All REST API endpoints
- **WebSocket URLs**: WebSocket connection endpoints
- **Timeouts**: Request timeout configurations

## Theme (`theme/`)

### `app_theme.dart`

Defines the application's visual theme:

- **Light Theme**: Light mode color scheme
- **Dark Theme**: Dark mode color scheme
- **Color Palette**: Primary, secondary, error, success colors
- **Typography**: Text styles and font configurations
- **Component Themes**: Custom theme for specific components

**Key Colors:**
- Primary: `0xFF6366F1` (Indigo)
- Success: `0xFF10B981` (Green)
- Error: `0xFFEF4444` (Red)
- Warning: `0xFFF59E0B` (Amber)

## Utils (`utils/`)

### Platform-Specific Utilities

- **`popup_helper.dart`**: Platform-agnostic interface for popup/tab operations
- **`popup_helper_web.dart`**: Web implementation using JavaScript interop
- **`popup_helper_web_stub.dart`**: Stub for non-web platforms
- **`popup_helper_stub.dart`**: Stub for non-web platforms

### Firebase Stubs

- **`firebase_stub.dart`**: Stub for Firebase on web
- **`firebase_crashlytics_stub.dart`**: Stub for Crashlytics on web
- **`fcm_service_stub.dart`**: Stub for FCM on web
- **`flutter_local_notifications_stub.dart`**: Stub for local notifications on web

### Other Utilities

- **`date_utils.dart`**: Date formatting and manipulation utilities
- **`locale_service.dart`**: Internationalization service
- **`dns_lookup.dart`**: DNS lookup functionality (mobile only)
- **`dns_lookup_stub.dart`**: Stub for DNS lookup on web

## Usage Examples

### Using API Constants

```dart
import 'package:app/core/constants/api_constants.dart';

final url = '${ApiConstants.baseUrl}${ApiConstants.devicesEndpoint}';
```

### Using Theme

```dart
import 'package:app/core/theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
);
```

### Using Date Utils

```dart
import 'package:app/core/utils/date_utils.dart' as date_utils;

final formatted = date_utils.DateUtils.formatForDisplay(dateTime);
```

### Opening Popup/Tab (Web)

```dart
import 'package:app/core/utils/popup_helper.dart';

// Open device in new tab
openDeviceInNewTab(deviceId);

// Open leak lookup in popup
openLeakLookupPopup(query: phoneNumber);
```







