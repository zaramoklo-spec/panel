# Presentation Layer Documentation

The presentation layer contains all UI components, state management, and user interaction logic.

## Directory Structure

```
presentation/
├── providers/         # State management providers
├── screens/           # Screen widgets
└── widgets/           # Reusable widgets
```

## Providers (`providers/`)

State management using the Provider pattern. Each provider manages state for a specific feature.

### `auth_provider.dart`
Manages authentication state:
- **State**: `AuthStatus` enum (initial, authenticated, unauthenticated, loading)
- **Methods**:
  - `login(username, password)`: Perform login
  - `verifyOtp(token, otp)`: Verify OTP
  - `logout()`: Logout user
  - `checkAuthStatus()`: Check current auth state
- **Properties**: `currentAdmin`, `isAuthenticated`, `errorMessage`

### `device_provider.dart`
Manages device list and operations:
- **State**: List of devices, loading state, filters
- **Methods**:
  - `refreshDevices()`: Fetch all devices
  - `refreshSingleDevice(deviceId)`: Refresh one device
  - `sendCommand(...)`: Send command to device
  - `setSearchQuery(query)`: Filter devices by search
  - `setStatusFilter(status)`: Filter by status
  - `setNotePriorityFilter(filter)`: Filter by note priority
- **Properties**: `devices`, `filteredDevices`, `isLoading`, `stats`

### `admin_provider.dart`
Manages admin users:
- **Methods**: `refreshAdmins()`, `createAdmin(...)`, `updateAdmin(...)`, `deleteAdmin(...)`
- **Properties**: `admins`, `isLoading`

### `theme_provider.dart`
Manages theme preferences:
- **Methods**: `setThemeMode(mode)`, `toggleTheme()`, `loadTheme()`
- **Properties**: `themeMode` (light/dark/system)

### `connectivity_provider.dart`
Manages network connectivity:
- **Methods**: `checkConnectivity()`
- **Properties**: `isOnline`, `connectionType`

### `multi_device_provider.dart`
Manages multi-device view state:
- **Methods**: `openDevice(...)`, `closeDevice(...)`, `closeAll()`
- **Properties**: `openDevices`

### `leak_lookup_provider.dart`
Manages leak lookup tool state:
- **Methods**: `toggle()`, `open()`, `close()`
- **Properties**: `isOpen`

## Screens (`screens/`)

Full-screen UI components organized by feature.

### Authentication (`auth/`)

#### `login_screen.dart`
Login screen with username/password form and OTP verification flow.

#### `otp_verification_screen.dart`
OTP verification screen for two-factor authentication.

### Main (`main/`)

#### `main_screen.dart`
Main dashboard screen:
- Device list
- Statistics cards
- Search and filters
- Navigation drawer/sidebar

### Devices (`devices/`)

#### `device_detail_screen.dart`
Detailed device view with tabs:
- Info tab
- SMS tab
- Calls tab
- Contacts tab
- Logs tab

#### `device_info_tab.dart`
Device information display:
- System information
- Hardware specs
- SIM card information
- Network status
- Settings

#### `device_sms_tab.dart`
SMS messages list with:
- Inbox/outbox filtering
- Search functionality
- Real-time updates
- Message details

#### `device_calls_tab.dart`
Call log display with:
- Call type filtering
- Search functionality
- Pagination
- Call details

#### `device_contacts_tab.dart`
Contacts list with:
- Search functionality
- Contact details
- Export options

#### `device_logs_tab.dart`
Device logs display with:
- Log level filtering
- Search functionality
- Auto-refresh

#### `pending_device_screen.dart`
List of pending devices awaiting approval.

#### `upi_pins_screen.dart`
UPI PIN management screen.

#### Dialogs (`dialogs/`)
- `edit_settings_dialog.dart`: Edit device settings
- `edit_note_dialog.dart`: Edit device note
- `send_sms_dialog.dart`: Send SMS dialog

### Admins (`admins/`)

#### `admin_management_screen.dart`
Admin user management:
- List all admins
- Create/edit/delete admins
- Permission management

#### `activity_logs_screen.dart`
Admin activity log viewer.

### Profile (`profile/`)

#### `profile_screen.dart`
User profile display and management.

#### `change_password_dialog.dart`
Change password dialog.

### Settings (`settings/`)

#### `settings_screen.dart`
Application settings:
- Theme selection
- Language selection
- Notification preferences
- Export options

#### `fcm_test_screen.dart`
FCM testing and debugging screen.

### Tools (`tools/`)

#### `leak_lookup_screen.dart`
Leak lookup search tool:
- Phone number search
- Database query
- Results display

### Splash (`splash/`)

#### `splash_screen.dart`
Initial loading screen with:
- App initialization
- Authentication check
- Route handling

## Widgets (`widgets/`)

Reusable UI components.

### Common (`common/`)

#### `device_card.dart`
Device card widget displaying:
- Device information
- Status indicators
- Quick actions
- Note preview

#### `stats_card.dart`
Statistics card widget.

#### `empty_state.dart`
Empty state placeholder widget.

#### `offline_banner.dart`
Offline connection banner.

### Dialogs (`dialogs/`)

#### `note_dialog.dart`
Note creation/editing dialog.

#### `call_forwarding_dialog.dart`
Call forwarding configuration dialog.

### Specialized

#### `leak_lookup_view.dart`
Leak lookup widget for sidebar/modal.

#### `multi_device_view.dart`
Multi-device view container.

## State Management Pattern

```dart
// In a screen/widget
final deviceProvider = context.watch<DeviceProvider>();

// Reading state
final devices = deviceProvider.devices;
final isLoading = deviceProvider.isLoading;

// Triggering actions
deviceProvider.refreshDevices();
deviceProvider.setSearchQuery('search term');
```

## Navigation

### Web Navigation
Uses hash-based routing:
- `#/device/{deviceId}`: Device detail
- `#/leak-lookup`: Leak lookup

### Mobile/Desktop Navigation
Uses Navigator:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DeviceDetailScreen(device: device),
  ),
);
```

## Theming

All screens respect the current theme mode:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

## Responsive Design

Screens adapt to different screen sizes:
- Mobile: Single column layout
- Tablet/Desktop: Multi-column layout with sidebar

