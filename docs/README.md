# Admin Panel Documentation

Complete documentation for the Flutter Admin Panel application.

## Table of Contents

- [Architecture Overview](./architecture.md)
- [Core Components](./core/README.md)
- [Data Layer](./data/README.md)
- [Presentation Layer](./presentation/README.md)
- [API Reference](./api/README.md)
- [Deployment Guide](./deployment.md)

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── core/                        # Core utilities and constants
│   ├── constants/              # API constants and configuration
│   ├── theme/                  # App theme configuration
│   └── utils/                  # Utility functions
├── data/                       # Data layer
│   ├── models/                 # Data models
│   ├── repositories/           # Data repositories
│   └── services/               # Service layer (API, WebSocket, etc.)
└── presentation/               # UI layer
    ├── providers/              # State management providers
    ├── screens/                # Screen widgets
    └── widgets/                # Reusable widgets
```

## Getting Started

See [Architecture Overview](./architecture.md) for a detailed introduction to the codebase structure and design patterns.







