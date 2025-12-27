# Data Layer Documentation

The data layer handles all data operations including API communication, local storage, and data models.

## Directory Structure

```
data/
├── models/            # Data models
├── repositories/      # Data repositories
└── services/          # Service layer
```

## Models (`models/`)

Pure Dart classes representing data structures. All models include JSON serialization/deserialization.

### Core Models

#### `device.dart`
Represents a device entity with all its properties:
- Device identification (ID, model, manufacturer)
- System information (OS version, hardware specs)
- Status information (battery, network, storage)
- Settings and configuration
- Statistics (SMS, calls, contacts counts)
- Notes and annotations

#### `admin.dart`
Represents an admin user:
- User credentials and profile
- Permissions and roles
- Activity tracking

#### `sms_message.dart`
Represents an SMS message:
- Sender and recipient
- Message content
- Timestamp and status
- Message type (inbox/outbox)

#### `call_log.dart`
Represents a call log entry:
- Phone numbers
- Call type (incoming/outgoing/missed)
- Duration and timestamp

#### `contact.dart`
Represents a contact:
- Name and phone numbers
- Contact information

#### `stats.dart`
Device statistics aggregation:
- Total counts
- Last sync timestamps

#### `activity_log.dart`
Admin activity log entry:
- Action type
- Timestamp
- Details

#### `device_log.dart`
Device log entry:
- Log level
- Message
- Timestamp

#### `app_type.dart`
Application type enumeration and metadata

## Repositories (`repositories/`)

Repositories abstract data operations and provide a clean interface for data access.

### `device_repository.dart`
Device-related data operations:
- `getDevices()`: Fetch all devices
- `getDevice(String deviceId)`: Fetch single device
- `sendCommand(...)`: Send command to device
- `sendSms(...)`: Send SMS via device
- `updateDeviceSettings(...)`: Update device settings
- `addNote(...)`: Add note to device

### `auth_repository.dart`
Authentication operations:
- `login(...)`: User login
- `verifyOtp(...)`: OTP verification
- `logout()`: User logout
- `checkAuthStatus()`: Check current auth status
- `refreshToken()`: Refresh authentication token

### `admin_repository.dart`
Admin management operations:
- `getAdmins()`: Fetch all admins
- `createAdmin(...)`: Create new admin
- `updateAdmin(...)`: Update admin
- `deleteAdmin(...)`: Delete admin
- `getActivityLogs(...)`: Fetch activity logs

### `tools_repository.dart`
Tool operations:
- `lookupLeak(...)`: Perform leak lookup search

## Services (`services/`)

Services handle low-level data operations and external integrations.

### `api_service.dart`
REST API communication:
- HTTP client configuration
- Request/response handling
- Error handling
- Token management
- Session management

**Key Features:**
- Automatic token refresh
- Request interceptors
- Response interceptors
- Session expiration handling

### `websocket_service.dart`
WebSocket communication for real-time updates:
- Connection management
- Message handling
- Reconnection logic
- Event subscription

**Events:**
- `device_update`: Device status updates
- `sms`: New SMS messages
- `sms_update`: SMS status updates
- `call`: Call log updates

### `storage_service.dart`
Local storage operations:
- SharedPreferences wrapper
- Secure storage for sensitive data
- Preference management

### `fcm_service.dart`
Firebase Cloud Messaging:
- Token management
- Notification handling
- Push notification registration

### `export_service.dart`
Data export functionality:
- CSV export
- JSON export
- File generation

## Data Flow

```
Screen/Widget
    ↓
Provider
    ↓
Repository (Business Logic)
    ↓
Service (API/Storage)
    ↓
Backend/Storage
```

## Error Handling

All repositories and services implement proper error handling:
- Network errors
- Authentication errors
- Validation errors
- Server errors

Errors are caught and converted to user-friendly messages.

## Example Usage

### Fetching Devices

```dart
final repository = DeviceRepository();
final devices = await repository.getDevices();
```

### Sending SMS

```dart
final repository = DeviceRepository();
final success = await repository.sendSms(
  deviceId: 'device123',
  phoneNumber: '+1234567890',
  message: 'Hello',
);
```

### Authentication

```dart
final repository = AuthRepository();
final result = await repository.login(
  username: 'admin',
  password: 'password',
);
if (result.success) {
  // Handle successful login
}
```




