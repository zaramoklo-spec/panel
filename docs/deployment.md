# Deployment Guide

## Build Configuration

### Flutter Version
Ensure Flutter SDK version matches `pubspec.yaml` requirements:
```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
```

### Dependencies
Install dependencies:
```bash
flutter pub get
```

## Platform-Specific Builds

### Web

#### Development
```bash
flutter run -d chrome
```

#### Production Build
```bash
flutter build web --release
```

Output: `build/web/`

#### Deployment
Deploy the `build/web/` directory to your web server:
- Static file hosting (Nginx, Apache)
- CDN (Cloudflare, AWS CloudFront)
- Hosting services (Firebase Hosting, Netlify, Vercel)

**Important Configuration:**
- Configure server to handle hash routing (`#/route`)
- Set proper CORS headers
- Configure HTTPS

### Android

#### Build APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

**Requirements:**
- Valid `android/app/google-services.json`
- Keystore for signing
- Configure signing in `android/app/build.gradle.kts`

### iOS

#### Build
```bash
flutter build ios --release
```

**Requirements:**
- macOS with Xcode
- Valid provisioning profile
- Apple Developer account

### Windows

#### Build
```bash
flutter build windows --release
```

Output: `build/windows/runner/Release/`

## Environment Configuration

### API Endpoint
Configure API base URL in `lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  // ...
}
```

### Firebase Configuration

#### Android
Place `google-services.json` in `android/app/`

#### iOS
Place `GoogleService-Info.plist` in `ios/Runner/`

#### Web
Configure Firebase in web app initialization (see Firebase console)

## Build Variants

### Development
Uses debug build configuration with:
- Verbose logging
- Debug mode enabled
- Development API endpoints

### Production
Uses release build configuration with:
- Optimized builds
- Minified code
- Production API endpoints
- Error reporting enabled

## Security Considerations

1. **API Keys**: Never commit API keys or secrets to version control
2. **Authentication**: Use secure token storage
3. **HTTPS**: Always use HTTPS in production
4. **CORS**: Configure proper CORS headers on backend
5. **Firebase**: Use environment-specific Firebase projects

## CI/CD

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

## Monitoring and Analytics

### Error Reporting
- Firebase Crashlytics (Android/iOS)
- Console logging for web

### Analytics
- Firebase Analytics (configured per platform)

## Troubleshooting

### Common Issues

1. **Build failures**: Check Flutter version and dependencies
2. **API connection errors**: Verify base URL and network configuration
3. **Firebase errors**: Verify configuration files are in correct locations
4. **Web routing issues**: Configure server for hash routing

## Performance Optimization

### Web
- Enable tree-shaking
- Use code splitting
- Optimize assets
- Enable compression

### Mobile
- Enable ProGuard/R8 (Android)
- Enable code obfuscation
- Optimize assets




