import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/services/storage_service.dart';
import 'data/services/api_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/device_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/multi_device_provider.dart';
import 'presentation/providers/leak_lookup_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/widgets/common/offline_banner.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/devices/device_detail_screen.dart';
import 'presentation/screens/tools/leak_lookup_screen.dart';
import 'core/theme/app_theme.dart';

import 'package:firebase_core/firebase_core.dart'
    if (dart.library.html) 'core/utils/firebase_stub.dart' as firebase_import;
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'core/utils/firebase_stub.dart' as messaging_import;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'core/utils/firebase_crashlytics_stub.dart' as crashlytics_import;
import 'data/services/fcm_service.dart'
    if (dart.library.html) 'core/utils/fcm_service_stub.dart' as fcm_import;

bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  if (_isMobilePlatform) {
    await firebase_import.Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runZonedGuarded(() async {
    if (_isMobilePlatform) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    await StorageService().init();

    if (_isMobilePlatform) {
      try {
        await firebase_import.Firebase.initializeApp();

        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          crashlytics_import.FirebaseCrashlytics.instance
              .recordFlutterFatalError(details);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          crashlytics_import.FirebaseCrashlytics.instance
              .recordError(error, stack, fatal: true);
          return true;
        };

        messaging_import.FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        await fcm_import.FCMService().initialize();
      } catch (e, stack) {
        debugPrint('Firebase initialization failed: $e');
        try {
          await crashlytics_import.FirebaseCrashlytics.instance
              .recordError(e, stack, fatal: true);
        } catch (_) {}
      }
    } else {
      debugPrint('Firebase skipped for platform: $defaultTargetPlatform');
    }

    runApp(const MyApp());
  }, (error, stack) async {
    if (_isMobilePlatform) {
      try {
        await crashlytics_import.FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true);
      } catch (_) {}
    } else {
      debugPrint('Uncaught zone error: $error');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<bool>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    
    _sessionExpiredSubscription = ApiService().sessionExpiredStream.listen((_) {
      _handleSessionExpired();
    });
  }

  void _handleSessionExpired() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Session expired! You were logged in from another device.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => MultiDeviceProvider()),
        ChangeNotifierProvider(create: (_) => LeakLookupProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            title: 'Admin Panel',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            onGenerateRoute: (settings) {
              if (settings.name?.startsWith('/device/') == true) {
                final deviceId = settings.name!.substring('/device/'.length);
                return MaterialPageRoute(
                  builder: (_) => DeviceDetailScreen.fromDeviceId(deviceId),
                  settings: settings,
                );
              }
              if (settings.name == '/leak-lookup' || settings.name?.startsWith('/leak-lookup') == true) {
                // Extract query parameter from route name if present
                String? query;
                if (settings.name != null && settings.name!.contains('?')) {
                  try {
                    final uri = Uri.parse('http://example.com${settings.name}');
                    query = uri.queryParameters['query'];
                  } catch (e) {
                    // Ignore parsing errors
                  }
                }
                return MaterialPageRoute(
                  builder: (_) => LeakLookupScreen(initialQuery: query),
                  settings: settings,
                );
              }
              return null;
            },

            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;

              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

                  systemNavigationBarColor: isDark
                      ? const Color(0xFF0B0F19)
                      : const Color(0xFFF8FAFC),
                  systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                  systemNavigationBarDividerColor: isDark
                      ? const Color(0xFF0B0F19)
                      : const Color(0xFFF8FAFC),
                  systemNavigationBarContrastEnforced: false,
                ),
              );

              return OfflineBanner(child: child!);
            },

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}