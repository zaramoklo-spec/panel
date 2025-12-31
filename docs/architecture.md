# Architecture Overview

## Overview

The Admin Panel is a Flutter application built using a clean architecture pattern with clear separation of concerns between the data, business logic, and presentation layers.

## Architecture Pattern

The application follows a **layered architecture** pattern:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (Screens, Widgets, Providers)      │
├─────────────────────────────────────┤
│      Business Logic Layer           │
│  (Repositories, Providers)          │
├─────────────────────────────────────┤
│      Data Layer                     │
│  (Models, Services, API)            │
└─────────────────────────────────────┘
```

## Key Components

### 1. Data Layer (`lib/data/`)

**Models** (`lib/data/models/`)
- Pure Dart classes representing data structures
- JSON serialization/deserialization
- No business logic

**Repositories** (`lib/data/repositories/`)
- Abstract data operations
- Handle data fetching, caching, and transformation
- Bridge between services and providers

**Services** (`lib/data/services/`)
- API communication (REST, WebSocket)
- Local storage operations
- External service integrations (Firebase, etc.)

### 2. Presentation Layer (`lib/presentation/`)

**Providers** (`lib/presentation/providers/`)
- State management using Provider pattern
- Business logic for UI components
- Handle user interactions

**Screens** (`lib/presentation/screens/`)
- Full-screen UI components
- Compose widgets to create complete views
- Handle navigation

**Widgets** (`lib/presentation/widgets/`)
- Reusable UI components
- Stateless or stateful widgets
- Composed into screens

### 3. Core Layer (`lib/core/`)

**Constants** (`lib/core/constants/`)
- API endpoints
- Configuration values
- App-wide constants

**Theme** (`lib/core/theme/`)
- Color schemes
- Typography
- Theme configuration

**Utils** (`lib/core/utils/`)
- Helper functions
- Utility classes
- Platform-specific implementations

## State Management

The application uses **Provider** for state management:

- `AuthProvider`: Authentication state
- `DeviceProvider`: Device list and management
- `AdminProvider`: Admin management
- `ThemeProvider`: Theme preferences
- `ConnectivityProvider`: Network status
- `MultiDeviceProvider`: Multi-device view state
- `LeakLookupProvider`: Leak lookup tool state

## Data Flow

```
User Action
    ↓
Screen/Widget
    ↓
Provider (Business Logic)
    ↓
Repository
    ↓
Service (API/Storage)
    ↓
Backend/Storage
```

## Platform Support

- **Web**: Full feature support with popup/tab navigation
- **Android**: Mobile app with Firebase integration
- **iOS**: Mobile app (prepared but not fully implemented)
- **Windows**: Desktop app with sidebar navigation

## Navigation

- **Web**: Hash-based routing (`#/device/{id}`, `#/leak-lookup`)
- **Mobile/Desktop**: Navigator-based routing

## Authentication

- Token-based authentication
- Session management
- Auto-logout on token expiration
- OTP verification for login

## Real-time Updates

- WebSocket connection for live device updates
- Firebase Cloud Messaging for push notifications
- Polling fallback for unreliable connections







