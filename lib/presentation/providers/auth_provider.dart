import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../data/models/admin.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/fcm_service.dart'
    if (dart.library.html) '../../core/utils/fcm_service_stub.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  StreamSubscription<bool>? _sessionExpiredSubscription;

  AuthStatus _status = AuthStatus.initial;
  Admin? _currentAdmin;
  String? _errorMessage;

  String? _tempToken;
  String? _pendingUsername;
  int? _otpExpiresIn;

  AuthStatus get status => _status;
  Admin? get currentAdmin => _currentAdmin;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  String? get tempToken => _tempToken;
  String? get pendingUsername => _pendingUsername;
  int? get otpExpiresIn => _otpExpiresIn;

  void initialize() {
    _sessionExpiredSubscription = ApiService().sessionExpiredStream.listen((_) {
      debugPrint('AuthProvider: Session expired detected, resetting auth state');
      _currentAdmin = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      _tempToken = null;
      _pendingUsername = null;
      _otpExpiresIn = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final admin = await _authRepository.getCurrentAdmin();

        if (admin != null) {
          _currentAdmin = admin;
          _status = AuthStatus.authenticated;
        } else {
          final storedAdmin = await _authRepository.getStoredAdmin();
          if (storedAdmin != null) {
            _currentAdmin = storedAdmin;
            _status = AuthStatus.authenticated;
          } else {
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error checking authentication status';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.login(username, password);

      if (result['requires_2fa'] == true) {

        _tempToken = result['temp_token'];
        _pendingUsername = username;
        _otpExpiresIn = result['expires_in'];
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        
        return {
          'success': true,
          'requires_2fa': true,
          'message': result['message'],
        };
      } else if (result['admin'] != null) {

        _currentAdmin = result['admin'];
        _status = AuthStatus.authenticated;
        _tempToken = null;
        _pendingUsername = null;
        notifyListeners();
        
        return {
          'success': true,
          'requires_2fa': false,
        };
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Login failed';
      notifyListeners();
      
      return {
        'success': false,
        'requires_2fa': false,
      };
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      
      return {
        'success': false,
        'requires_2fa': false,
        'error': _errorMessage,
      };
    }
  }

  Future<bool> verify2FA(String otpCode) async {
    if (_tempToken == null || _pendingUsername == null) {
      _errorMessage = 'No pending OTP verification';
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final fcmToken = await FCMService().getToken();
      debugPrint('Sending FCM token with 2FA: $fcmToken');

      final admin = await _authRepository.verify2FA(
        _pendingUsername!,
        otpCode,
        _tempToken!,
        fcmToken: fcmToken,
      );

      if (admin != null) {
        _currentAdmin = admin;
        _status = AuthStatus.authenticated;
        _tempToken = null;
        _pendingUsername = null;
        _otpExpiresIn = null;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Invalid OTP code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void cancel2FA() {
    _tempToken = null;
    _pendingUsername = null;
    _otpExpiresIn = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentAdmin = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error logging out';
      notifyListeners();
    }
  }

  Future<void> refreshAdminInfo() async {
    try {
      final admin = await _authRepository.getCurrentAdmin();
      if (admin != null) {
        _currentAdmin = admin;
        notifyListeners();
      }
    } catch (e) {

    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}