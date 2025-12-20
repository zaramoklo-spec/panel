# Admin Panel

A comprehensive Flutter-based admin panel for device management, monitoring, and control.

## Features

- **Device Management**: View and manage connected devices
- **Real-time Monitoring**: Live updates via WebSocket
- **SMS & Call Management**: View and manage SMS messages and call logs
- **Contact Management**: Access device contacts
- **Admin Management**: User and permission management
- **Security Tools**: Leak lookup and security intelligence
- **Multi-platform**: Web, Android, iOS, and Windows support

## Documentation

Complete documentation is available in the [`docs/`](./docs/) directory:

- [Architecture Overview](./docs/architecture.md)
- [Core Components](./docs/core/README.md)
- [Data Layer](./docs/data/README.md)
- [Presentation Layer](./docs/presentation/README.md)
- [API Reference](./docs/api/README.md)
- [Deployment Guide](./docs/deployment.md)

## Getting Started

### Prerequisites

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0
- Android Studio / Xcode (for mobile builds)
- Web server (for web deployment)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API endpoint in `lib/core/constants/api_constants.dart`

4. Configure Firebase (for mobile):
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/                     # Core utilities and constants
│   ├── constants/           # API constants
│   ├── theme/               # Theme configuration
│   └── utils/               # Utility functions
├── data/                    # Data layer
│   ├── models/              # Data models
│   ├── repositories/        # Data repositories
│   └── services/            # Service layer
└── presentation/            # UI layer
    ├── providers/           # State management
    ├── screens/             # Screen widgets
    └── widgets/             # Reusable widgets
```

## Build

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

## License

Proprietary - All rights reserved
