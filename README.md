# ?? Pannel - Admin Device Management Platform

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-Private-yellow?style=for-the-badge)

**A powerful Flutter-based admin panel for remote Android device management and monitoring**

[Features](#-features) ? [Screenshots](#-screenshots) ? [Architecture](#-architecture) ? [Setup](#-quick-start) ? [Documentation](#-documentation)

</div>

---

## ?? Overview

**Pannel** is a comprehensive admin panel application built with Flutter that enables administrators to remotely manage, monitor, and control Android devices. The platform provides real-time insights into device status, SMS messages, call logs, contacts, and system information.

### ?? Key Highlights

- ?? **Secure Authentication** - Role-based access control with JWT tokens
- ?? **Real-time Dashboard** - Live device status monitoring and statistics
- ?? **Multi-Device Management** - Manage unlimited Android devices from one place
- ?? **SMS Management** - Read, send, and monitor SMS messages
- ?? **Call Logs** - Complete call history with detailed metadata
- ?? **Contact Sync** - Access device contacts remotely
- ?? **Modern UI/UX** - Beautiful, responsive design with dark mode support
- ?? **Push Notifications** - FCM integration for instant alerts
- ?? **Analytics** - Comprehensive activity logs and statistics

---

## ? Features

### ?? Authentication & Security
- ? Secure JWT-based authentication
- ? Role-based access control (Admin/Super Admin)
- ? Session management with automatic token refresh
- ? Secure storage using Flutter Secure Storage

### ?? Device Management
- ? **Device Dashboard** - Overview of all connected devices
- ? **Device Details** - Complete device information including:
  - Hardware specifications (Model, Manufacturer, OS Version)
  - Battery status and charging state
  - Storage and RAM usage
  - Network information (WiFi/Mobile)
  - SIM card details (Dual-SIM support)
- ? **Device Status** - Real-time online/offline status
- ? **Device Commands** - Send remote commands to devices
- ? **Device Settings** - Configure monitoring and forwarding options

### ?? SMS Management
- ? View all SMS messages from devices
- ? Send SMS remotely through devices
- ? SMS forwarding configuration
- ? Filter by conversation threads
- ? Search and export functionality

### ?? Call Logs
- ? Complete call history (Incoming/Outgoing/Missed)
- ? Call duration and timestamps
- ? Caller identification
- ? Call forwarding setup
- ? Export call logs

### ?? Contact Management
- ? Sync and view device contacts
- ? Search and filter contacts
- ? Contact details with multiple numbers
- ? Export contact lists

### ?? Advanced Features
- ? **UPI Detection** - Monitor UPI app installations and PINs
- ? **Dual-SIM Support** - Complete SIM card information
- ? **Call Forwarding** - Configure call forwarding per SIM
- ? **Device Notes** - Add priority notes (Low/High Balance)
- ? **Activity Logs** - Track all admin actions
- ? **Statistics** - Comprehensive analytics dashboard
- ? **Profile Management** - Admin profile and settings

### ?? UI/UX Features
- ? Beautiful gradient designs
- ? Dark mode support
- ? Smooth animations and transitions
- ? Responsive layout (Mobile/Tablet/Desktop)
- ? Pull-to-refresh functionality
- ? Loading states and error handling
- ? Toast notifications and dialogs

---

## ?? Screenshots

<div align="center">

| Login Screen | Dashboard | Device Details |
|:---:|:---:|:---:|
| ![Login]() | ![Dashboard]() | ![Details]() |

| SMS Messages | Call Logs | Settings |
|:---:|:---:|:---:|
| ![SMS]() | ![Calls]() | ![Settings]() |

</div>

---

## ??? Architecture

The application follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
??? core/                    # Core functionality
?   ??? constants/          # API endpoints, app constants
?   ??? theme/             # App theme and styling
?   ??? utils/             # Utility functions
?
??? data/                   # Data layer
?   ??? models/            # Data models
?   ?   ??? device.dart
?   ?   ??? sms_message.dart
?   ?   ??? call_log.dart
?   ?   ??? contact.dart
?   ?   ??? admin.dart
?   ?   ??? activity_log.dart
?   ??? repositories/      # Repository implementations
?   ?   ??? auth_repository.dart
?   ?   ??? device_repository.dart
?   ?   ??? admin_repository.dart
?   ??? services/          # External services
?       ??? api_service.dart
?       ??? storage_service.dart
?
??? presentation/           # Presentation layer
    ??? providers/         # State management (Provider)
    ?   ??? auth_provider.dart
    ?   ??? device_provider.dart
    ?   ??? admin_provider.dart
    ?   ??? theme_provider.dart
    ??? screens/          # UI screens
    ?   ??? auth/
    ?   ??? devices/
    ?   ??? admins/
    ?   ??? profile/
    ?   ??? settings/
    ??? widgets/          # Reusable widgets
        ??? common/
        ??? dialogs/
```

### ?? Key Technologies

| Technology | Purpose |
|------------|---------|
| **Flutter 3.0+** | Cross-platform UI framework |
| **Provider** | State management |
| **Dio** | HTTP client for API calls |
| **SharedPreferences** | Local data storage |
| **Flutter Secure Storage** | Secure token storage |
| **Google Fonts** | Beautiful typography |
| **Intl & Timeago** | Date formatting |
| **URL Launcher** | External URL handling |
| **ScreenUtil** | Responsive sizing |

---

## ?? Quick Start

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Active backend API server

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pannel
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   
   Update the base URL in `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-api-server:port';
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

5. **Build APK**
   ```bash
   flutter build apk --release
   ```

### ?? Configuration

#### API Endpoints
All API endpoints are centralized in `lib/core/constants/api_constants.dart`. Update this file to match your backend configuration.

#### App Icon
The app icon is located at `assets/icon/app_icon.png`. To generate platform-specific icons:
```bash
flutter pub run flutter_launcher_icons
```

---

## ?? Documentation

| Document | Description |
|----------|-------------|
| [Architecture Guide](./ARCHITECTURE.md) | Detailed architecture and design patterns |
| [API Documentation](./API_DOCUMENTATION.md) | Complete API reference |
| [Setup Guide](./SETUP_GUIDE.md) | Detailed installation and configuration |

---

## ?? API Integration

The app communicates with a REST API backend. Key endpoints include:

### Authentication
- `POST /auth/login` - Admin login
- `POST /auth/logout` - Admin logout
- `GET /auth/me` - Get current admin info

### Devices
- `GET /api/devices` - List all devices
- `GET /api/devices/:id` - Get device details
- `GET /api/devices/:id/sms` - Get device SMS
- `GET /api/devices/:id/calls` - Get device calls
- `GET /api/devices/:id/contacts` - Get device contacts
- `POST /api/devices/:id/command` - Send device command
- `PUT /api/devices/:id/settings` - Update device settings

### Admin Management
- `GET /admin/list` - List all admins
- `POST /admin/create` - Create new admin
- `PUT /admin/:username` - Update admin
- `DELETE /admin/:username` - Delete admin
- `GET /admin/activities` - Get activity logs
- `GET /admin/activities/stats` - Get statistics

For complete API documentation, see [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

---

## ?? Theme & Styling

The app supports both **Light** and **Dark** themes with smooth transitions:

- **Primary Color**: Indigo (`#6366F1`)
- **Secondary Color**: Purple (`#8B5CF6`)
- **Design System**: Custom gradient-based components
- **Typography**: Google Fonts with multiple weights
- **Responsive**: ScreenUtil for consistent sizing across devices

---

## ?? Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2
  
  # HTTP & Network
  dio: ^5.4.3+1
  pretty_dio_logger: ^1.3.1
  
  # Local Storage
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2
  
  # UI & Styling
  google_fonts: ^6.2.1
  flutter_screenutil: ^5.9.0
  
  # Utilities
  intl: ^0.20.2
  timeago: ^3.6.1
  url_launcher: ^6.3.0
```

---

## ?? Security

- JWT token-based authentication
- Secure storage for sensitive data
- Automatic token refresh
- Session timeout handling
- Input validation and sanitization
- HTTPS communication (production)

---

## ?? Troubleshooting

### Common Issues

**1. API Connection Failed**
- Verify the API base URL in `api_constants.dart`
- Ensure the backend server is running
- Check network permissions in `AndroidManifest.xml`

**2. Build Errors**
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

**3. Storage Permission Issues**
- Update Android permissions in `android/app/src/main/AndroidManifest.xml`
- Request runtime permissions for Android 6.0+

---

## ??? Development

### Code Structure Best Practices
- Follow Flutter naming conventions
- Use Provider for state management
- Implement error handling in all API calls
- Add loading states for async operations
- Write clean, documented code

### Testing
```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Generate coverage
flutter test --coverage
```

---

## ?? Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ? Supported | Primary platform |
| iOS | ?? Not tested | Should work with minimal changes |
| Web | ? Supported | Included in build |
| Windows | ? Supported | Desktop support included |

---

## ?? Contributing

This is a private project. For authorized contributors:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request with detailed description

---

## ?? License

This project is private and proprietary. All rights reserved.

---

## ????? Author

**Your Name**
- Email: your.email@example.com
- GitHub: [@yourusername](https://github.com/yourusername)

---

## ?? Acknowledgments

- Flutter team for the amazing framework
- Provider package maintainers
- All open-source contributors

---

<div align="center">

**Made with ?? using Flutter**

? Star this repository if you find it helpful!

</div>
