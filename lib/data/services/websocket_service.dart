import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../core/constants/api_constants.dart';
import 'storage_service.dart';

class WebSocketService {
  WebSocketService._internal();

  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  final StorageService _storage = StorageService();
  final StreamController<Map<String, dynamic>> _smsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _healthCheckTimer;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _token;
  final Set<String> _subscriptions = {};
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 10;
  DateTime? _lastPongReceived;
  static const Duration _pingInterval = Duration(seconds: 15);  // Client sends ping every 15 seconds (more frequent)
  static const Duration _healthCheckInterval = Duration(seconds: 8);  // Check more frequently
  static const Duration _pongTimeout = Duration(seconds: 60);  // Increased: Wait max 60 seconds for pong

  Stream<Map<String, dynamic>> get smsStream => _smsController.stream;
  Stream<Map<String, dynamic>> get deviceStream => _deviceController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected && _channel != null;

  Future<void> ensureConnected() async {
    if (_isConnecting) {
      return;
    }

    if (_channel != null && _isConnected) {
      // Check if connection is still alive (more lenient)
      if (_lastPongReceived != null) {
        final timeSincePong = DateTime.now().difference(_lastPongReceived!);
        if (timeSincePong > _pongTimeout) {
          developer.log('⚠️ No pong received for ${timeSincePong.inSeconds}s, forcing reconnect', name: 'WebSocket');
          _forceReconnect();
          return;
        }
      } else {
        // If we just connected and haven't received pong yet, wait a bit more
        // This is normal for initial connection
      }
      return;
    }

    _isConnecting = true;
    _token = await _storage.getToken();

    if (_token == null) {
      _isConnecting = false;
      _updateConnectionStatus(false);
      return;
    }

    final uri = _buildWebSocketUri(_token!);

    try {
      // Close existing connection if any
      await _closeConnection();

      _channel = WebSocketChannel.connect(uri);
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          _updateConnectionStatus(false);
          _scheduleReconnect();
        },
        onError: (error) {
          _updateConnectionStatus(false);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _lastPongReceived = DateTime.now(); // Initialize pong time
      _updateConnectionStatus(true);
      
      // Start timers immediately
      _startPingTimer();
      _startHealthCheckTimer();
      
      // Send pending subscriptions after a short delay to ensure connection is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        _sendPendingSubscriptions();
      });
    } catch (e) {
      _updateConnectionStatus(false);
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(connected);
      }
    }
  }

  void subscribeToDevice(String deviceId) {
    if (deviceId.isEmpty) return;
    
    // Add to subscriptions set
    if (!_subscriptions.contains(deviceId)) {
      _subscriptions.add(deviceId);
      developer.log('📝 Added device to subscriptions: $deviceId', name: 'WebSocket');
    }
    
    // Retry subscribe if connection is not ready
    if (_channel == null || !_isConnected) {
      developer.log('⏳ Connection not ready, ensuring connection first...', name: 'WebSocket');
      ensureConnected().then((_) {
        if (_channel != null && _isConnected) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _sendAction('subscribe', deviceId);
          });
        } else {
          developer.log('⚠️ Failed to connect, will retry subscribe later', name: 'WebSocket');
        }
      });
    } else {
      // Connection is ready, send subscribe immediately
      developer.log('✅ Connection ready, subscribing to device: $deviceId', name: 'WebSocket');
      _sendAction('subscribe', deviceId);
    }
  }

  void unsubscribeFromDevice(String deviceId) {
    if (deviceId.isEmpty) return;
    _subscriptions.remove(deviceId);
    _sendAction('unsubscribe', deviceId);
  }


  Uri _buildWebSocketUri(String token) {
    final base = Uri.parse(ApiConstants.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';

    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/admin',
      queryParameters: {'token': token},
    );
  }

  void _handleMessage(dynamic event) {
    try {
      final raw = event is String ? event : utf8.decode(event as List<int>);
      final Map<String, dynamic> data = jsonDecode(raw);
      final type = data['type'];
      
      if (type == 'connected') {
        _isConnected = true;
        _updateConnectionStatus(true);
        _reconnectAttempts = 0;
        _lastPongReceived = DateTime.now();
        
        developer.log('✅ WebSocket connected, sending subscriptions...', name: 'WebSocket');
        
        // Start timers if not already started
        _startPingTimer();
        _startHealthCheckTimer();
        
        // Send all pending subscriptions immediately
        Future.delayed(const Duration(milliseconds: 200), () {
          _sendPendingSubscriptions();
        });
        
        // Also send a ping to confirm connection
        Future.delayed(const Duration(milliseconds: 500), () {
          _sendAction('ping', '');
        });
        
        return;
      }
      
      if (type == 'subscribed') {
        final deviceId = data['device_id'];
        developer.log('✅ Successfully subscribed to device: $deviceId', name: 'WebSocket');
        // Ensure it's in our subscriptions set
        if (deviceId != null && deviceId.isNotEmpty) {
          _subscriptions.add(deviceId);
        }
        return;
      }
      
      if (type == 'error' && data['message']?.toString().contains('Subscription') == true) {
        developer.log('⚠️ Subscription error: ${data['message']}', name: 'WebSocket');
        // Retry subscription after a delay
        final deviceId = data['device_id'];
        if (deviceId != null && deviceId.isNotEmpty) {
          Future.delayed(const Duration(seconds: 2), () {
            _sendAction('subscribe', deviceId);
          });
        }
        return;
      }

      if (type == 'pong') {
        _lastPongReceived = DateTime.now();
        return;
      }

      if (type == 'ping') {
        // Server sent us a ping, respond with pong
        _sendAction('pong', '');
        return;
      }

      if (type == 'sms' || type == 'sms_update') {
        developer.log('📨 Received SMS notification: ${data['device_id']}', name: 'WebSocket');
        // Add immediately to stream
        if (!_smsController.isClosed) {
          _smsController.add(data);
        }
      }
      
      if (type == 'device_update') {
        developer.log('📱 Received device update notification: ${data['device_id']}', name: 'WebSocket');
        // Add immediately to device stream
        if (!_deviceController.isClosed) {
          _deviceController.add(data);
        }
      }
    } catch (_) {
      // Ignore malformed messages.
    }
  }

  void _sendPendingSubscriptions() {
    if (_channel == null || _isConnecting) {
      return;
    }
    for (final deviceId in _subscriptions) {
      _sendAction('subscribe', deviceId);
    }
  }

  void _sendAction(String action, String deviceId) {
    if (_channel == null || _isConnecting) {
      if (action != 'ping') {
        ensureConnected().then((_) {
          if (_channel != null) {
            _sendAction(action, deviceId);
          }
        });
      }
      return;
    }

    final payload = <String, dynamic>{
      'action': action,
    };
    if (deviceId.isNotEmpty) {
      payload['device_id'] = deviceId;
    }

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // Exponential backoff with max delay of 60 seconds
      final delay = Duration(
        seconds: (3 * (1 << (_reconnectAttempts - _maxReconnectAttempts))).clamp(3, 60),
      );
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts = 0; // Reset after max attempts
        ensureConnected();
      });
      return;
    }

    _reconnectAttempts++;
    _isConnected = false;
    _updateConnectionStatus(false);
    
    _closeConnection();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 60s (max)
    final delay = Duration(
      seconds: (1 << (_reconnectAttempts - 1)).clamp(1, 60),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      ensureConnected();
    });
  }

  Future<void> _closeConnection() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    
    _channelSubscription?.cancel();
    _channelSubscription = null;
    
    try {
      await _channel?.sink.close(status.goingAway);
    } catch (_) {
      // Ignore errors when closing
    }
    _channel = null;
  }

  void _forceReconnect() {
    _reconnectAttempts = 0;
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_channel != null && _isConnected && !_isConnecting) {
        try {
          _sendAction('ping', '');
          developer.log('📤 Sent ping to server', name: 'WebSocket');
        } catch (e) {
          developer.log('❌ Failed to send ping: $e', name: 'WebSocket');
          _scheduleReconnect();
        }
      }
    });
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      if (_channel == null || !_isConnected) {
        return;
      }

      // Check if we haven't received pong in time
      if (_lastPongReceived != null) {
        final timeSincePong = DateTime.now().difference(_lastPongReceived!);
        if (timeSincePong > _pongTimeout) {
          developer.log('⚠️ Health check failed: No pong for ${timeSincePong.inSeconds}s, reconnecting...', name: 'WebSocket');
          _forceReconnect();
          return;
        }
      } else {
        // If no pong received yet after initial connection, wait a bit more
        // This is normal for initial connection - give it 30 seconds
        final timeSinceConnection = DateTime.now().difference(_lastPongReceived ?? DateTime.now());
        if (timeSinceConnection.inSeconds > 30) {
          developer.log('⚠️ Health check: No pong received after 30s, reconnecting...', name: 'WebSocket');
          _forceReconnect();
        }
      }
    });
  }

  void dispose() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _closeConnection();
    if (!_smsController.isClosed) {
      _smsController.close();
    }
    if (!_deviceController.isClosed) {
      _deviceController.close();
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
  }
}

