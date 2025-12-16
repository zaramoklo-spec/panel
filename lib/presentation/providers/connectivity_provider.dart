import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _internetCheckTimer;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity status
    await _checkInternetConnection();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final hasNetwork = _hasNetworkConnection(results);
        if (!hasNetwork) {
          _isOnline = false;
          notifyListeners();
        } else {
          // If network is connected, verify actual internet access
          await _checkInternetConnection();
        }
      },
    );

    // Periodic internet check every 10 seconds
    _internetCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkInternetConnection(),
    );
  }

  bool _hasNetworkConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result != ConnectivityResult.none
    );
  }

  Future<void> _checkInternetConnection() async {
    try {
      // First check if we have network connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      if (!_hasNetworkConnection(connectivityResults)) {
        _isOnline = false;
        notifyListeners();
        return;
      }

      // Verify actual internet access
      // For web: use HTTP request (checkHealth)
      // For mobile/desktop: use DNS lookup
      bool isConnected = false;
      
      if (kIsWeb) {
        // Web: Use HTTP request to check server health
        try {
          isConnected = await ApiService().checkHealth();
        } catch (e) {
          // If health check fails, we're offline
          isConnected = false;
        }
      } else {
        // Mobile/Desktop: Use DNS lookup (faster and doesn't require server)
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw TimeoutException('Connection timeout'),
              );
          isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (e) {
          isConnected = false;
        }
      }

      final wasOnline = _isOnline;
      _isOnline = isConnected;
      
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    } catch (e) {
      // If check fails, assume offline
      final wasOnline = _isOnline;
      _isOnline = false;
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetCheckTimer?.cancel();
    super.dispose();
  }
}

