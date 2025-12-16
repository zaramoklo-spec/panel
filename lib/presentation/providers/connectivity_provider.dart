import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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

      // Then verify actual internet access with a quick HTTP request
      final result = await InternetAddress.lookup('google.com')
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    } catch (e) {
      // If lookup fails, we're offline
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

