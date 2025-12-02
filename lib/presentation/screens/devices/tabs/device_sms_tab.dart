import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/device.dart';
import '../../../../data/models/sms_message.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../../core/utils/date_utils.dart' as utils;
import '../../../providers/device_provider.dart';
import '../sms_detail_screen.dart';
import '../dialogs/send_sms_dialog.dart';
import '../../../widgets/common/empty_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/services/websocket_service.dart';

enum TimeFilter { all, today, yesterday, week, month }

enum ContentFilter { all, hasLink, hasNumber, hasOtp, long, short }

enum CategoryFilter {
  all,
  otp,
  upi,
  credit,
  debit,
  balance,
  banking,
  promotional,
  important
}

class DeviceSmsTab extends StatefulWidget {
  final Device device;

  const DeviceSmsTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceSmsTab> createState() => _DeviceSmsTabState();
}

class _DeviceSmsTabState extends State<DeviceSmsTab> {
  final DeviceRepository _repository = DeviceRepository();
  final TextEditingController _searchController = TextEditingController();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  List<SmsMessage> _messages = [];
  List<SmsMessage> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSendingCommand = false;
  String? _errorMessage;
  TimeFilter _timeFilter = TimeFilter.all;
  ContentFilter _contentFilter = ContentFilter.all;
  CategoryFilter _categoryFilter = CategoryFilter.all;
  String _searchQuery = '';
  bool _showAdvancedFilters = false;

  int _currentPage = 1;
  int _pageSize = 100;
  int _totalMessages = 0;
  int _totalPages = 0;

  final List<int> _pageSizeOptions = [100, 250, 500];
  String? _subscribedDeviceId;
  
  // New message tracking
  final Set<String> _newMessageIds = {};
  final Map<String, DateTime> _newMessageTimestamps = {};
  int _newMessageCount = 0;
  
  // Font size control
  double _fontSize = 11.0; // Default font size
  bool _showFontSizeControl = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initializeRealtime();
  }

  @override
  void didUpdateWidget(DeviceSmsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.deviceId != widget.device.deviceId) {
      _fetchMessages();
      // Reinitialize realtime when device changes
      _initializeRealtime();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh WebSocket subscription when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshWebSocketSubscription();
      }
    });
  }
  
  void _refreshWebSocketSubscription() {
    // Ensure connection and refresh subscription
    _webSocketService.ensureConnected().then((_) {
      if (mounted) {
        _subscribeToDevice(widget.device.deviceId);
        debugPrint('🔄 WebSocket subscription refreshed for device: ${widget.device.deviceId}');
      }
    }).catchError((error) {
      debugPrint('❌ Failed to refresh WebSocket subscription: $error');
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    if (_subscribedDeviceId != null) {
      _webSocketService.unsubscribeFromDevice(_subscribedDeviceId!);
    }
    _searchController.dispose();
    super.dispose();
  }

  StreamSubscription<bool>? _connectionStatusSubscription;
  
  Future<void> _initializeRealtime() async {
    // Ensure WebSocket is connected first
    await _webSocketService.ensureConnected();
    
    // Wait a bit for connection to stabilize
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Subscribe to device
    _subscribeToDevice(widget.device.deviceId);
    
    // Listen to SMS stream - cancel previous subscription if exists
    await _wsSubscription?.cancel();
    _wsSubscription = _webSocketService.smsStream.listen(
      _handleRealtimeSms,
      onError: (error) {
        debugPrint('❌ SMS stream error: $error');
      },
      cancelOnError: false,
    );
    
    // Also listen to connection status to resubscribe if needed
    await _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = _webSocketService.connectionStatusStream.listen(
      (isConnected) {
        if (isConnected && mounted) {
          debugPrint('✅ WebSocket reconnected, resubscribing to device...');
          // Resubscribe when connection is restored
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _subscribeToDevice(widget.device.deviceId);
              // Refresh messages to ensure we have latest data
              _fetchMessages();
            }
          });
        } else if (!isConnected && mounted) {
          debugPrint('⚠️ WebSocket disconnected');
        }
      },
      onError: (error) {
        debugPrint('❌ Connection status stream error: $error');
      },
      cancelOnError: false,
    );
  }

  void _subscribeToDevice(String deviceId) {
    if (deviceId.isEmpty) return;
    if (_subscribedDeviceId == deviceId) return;

    if (_subscribedDeviceId != null) {
      _webSocketService.unsubscribeFromDevice(_subscribedDeviceId!);
    }

    _webSocketService.subscribeToDevice(deviceId);
    _subscribedDeviceId = deviceId;
  }

  void _handleRealtimeSms(Map<String, dynamic> event) {
    if (!mounted) return;

    final eventType = event['type'];
    if (eventType != 'sms' && eventType != 'sms_update') return;
    
    final eventDeviceId = event['device_id'];
    if (eventDeviceId != widget.device.deviceId) {
      debugPrint('⚠️ SMS event for different device: $eventDeviceId (expected: ${widget.device.deviceId})');
      return;
    }

    final smsData = event['sms'];
    if (smsData is! Map<String, dynamic>) {
      debugPrint('❌ Invalid SMS data format');
      return;
    }

    try {
      final sms = SmsMessage.fromJson(smsData);
      final index = _messages.indexWhere((m) => m.id == sms.id);
      
      debugPrint('📨 Received SMS: ${sms.from} -> ${sms.to}, type: $eventType, body: ${sms.body.substring(0, sms.body.length > 20 ? 20 : sms.body.length)}...');

      if (index >= 0) {
        // Existing message - update it
        setState(() {
          _messages[index] = sms;
          // If it's an update (like delivery status), mark as new temporarily
          if (eventType == 'sms_update') {
            _newMessageIds.add(sms.id);
            _newMessageTimestamps[sms.id] = DateTime.now();
            _newMessageCount++;
            
            // Remove from new messages after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _newMessageIds.remove(sms.id);
                  _newMessageTimestamps.remove(sms.id);
                  if (_newMessageCount > 0) _newMessageCount--;
                });
              }
            });
          }
        });
        _applyFilters();
        return;
      }

      // New message (both 'sms' and 'sms_update' can be new)
      if (eventType == 'sms' || eventType == 'sms_update') {
        setState(() {
          _messages = [sms, ..._messages];
          // Mark as new message
          _newMessageIds.add(sms.id);
          _newMessageTimestamps[sms.id] = DateTime.now();
          _newMessageCount++;
          
          // Remove from new messages after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _newMessageIds.remove(sms.id);
                _newMessageTimestamps.remove(sms.id);
                if (_newMessageCount > 0) _newMessageCount--;
              });
            }
          });
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('❌ Error handling realtime SMS: $e');
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skip = (_currentPage - 1) * _pageSize;
      final result = await _repository.getDeviceSms(
        widget.device.deviceId,
        skip: skip,
        limit: _pageSize,
      );

      setState(() {
        _messages = result['messages'] as List<SmsMessage>;
        _totalMessages = result['total'] as int;
        _totalPages = (_totalMessages / _pageSize).ceil();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading messages';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = _messages;

    filtered = _applyTimeFilter(filtered);
    filtered = _applyContentFilter(filtered);
    filtered = _applyCategoryFilter(filtered);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((message) {
        final query = _searchQuery.toLowerCase();
        return message.body.toLowerCase().contains(query) ||
            (message.from?.toLowerCase().contains(query) ?? false) ||
            (message.to?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredMessages = filtered;
    });
  }

  List<SmsMessage> _applyTimeFilter(List<SmsMessage> messages) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    switch (_timeFilter) {
      case TimeFilter.today:
        return messages.where((m) => m.timestamp.isAfter(today)).toList();
      case TimeFilter.yesterday:
        return messages
            .where((m) =>
        m.timestamp.isAfter(yesterday) && m.timestamp.isBefore(today))
            .toList();
      case TimeFilter.week:
        return messages.where((m) => m.timestamp.isAfter(weekAgo)).toList();
      case TimeFilter.month:
        return messages.where((m) => m.timestamp.isAfter(monthAgo)).toList();
      case TimeFilter.all:
      default:
        return messages;
    }
  }

  List<SmsMessage> _applyContentFilter(List<SmsMessage> messages) {
    final urlRegex =
    RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)', caseSensitive: false);
    final phoneRegex = RegExp(r'\b\d{4,}\b');
    final otpRegex = RegExp(r'\b\d{4,6}\b');

    switch (_contentFilter) {
      case ContentFilter.hasLink:
        return messages.where((m) => urlRegex.hasMatch(m.body)).toList();
      case ContentFilter.hasNumber:
        return messages.where((m) => phoneRegex.hasMatch(m.body)).toList();
      case ContentFilter.hasOtp:
        return messages
            .where((m) =>
        otpRegex.hasMatch(m.body) &&
            (m.body.toLowerCase().contains('code') ||
                m.body.toLowerCase().contains('otp') ||
                m.body.toLowerCase().contains('verify') ||
                m.body.toLowerCase().contains('verification')))
            .toList();
      case ContentFilter.long:
        return messages.where((m) => m.body.length > 200).toList();
      case ContentFilter.short:
        return messages.where((m) => m.body.length <= 200).toList();
      case ContentFilter.all:
      default:
        return messages;
    }
  }

  List<SmsMessage> _applyCategoryFilter(List<SmsMessage> messages) {
    switch (_categoryFilter) {
      case CategoryFilter.otp:
        final otpRegex = RegExp(r'\b\d{4,6}\b');
        return messages
            .where((m) =>
        otpRegex.hasMatch(m.body) &&
            (m.body.toLowerCase().contains('code') ||
                m.body.toLowerCase().contains('otp') ||
                m.body.toLowerCase().contains('verify') ||
                m.body.toLowerCase().contains('verification') ||
                m.body.toLowerCase().contains('password') ||
                m.body.toLowerCase().contains('authenticate')))
            .toList();

      case CategoryFilter.upi:
        final upiIdRegex = RegExp(r'\b[\w.]+@[\w]+\b');
        return messages
            .where((m) =>
        m.body.toLowerCase().contains('upi') ||
            m.body.toLowerCase().contains('bhim') ||
            m.body.toLowerCase().contains('paytm') ||
            m.body.toLowerCase().contains('phonepe') ||
            m.body.toLowerCase().contains('googlepay') ||
            m.body.toLowerCase().contains('gpay') ||
            upiIdRegex.hasMatch(m.body))
            .toList();

      case CategoryFilter.credit:
        return messages
            .where((m) {
              final body = m.body.toLowerCase();
              return body.contains('credit') ||
                  body.contains('credited') ||
                  body.contains('deposited') ||
                  body.contains('received') ||
                  body.contains('home credit');
            })
            .toList();

      case CategoryFilter.debit:
        return messages
            .where((m) =>
        m.body.toLowerCase().contains('debit') ||
            m.body.toLowerCase().contains('debited') ||
            m.body.toLowerCase().contains('withdrawn') ||
            m.body.toLowerCase().contains('spent') ||
            m.body.toLowerCase().contains('purchase'))
            .toList();

      case CategoryFilter.balance:
        return messages
            .where((m) =>
        (m.body.toLowerCase().contains('balance') ||
            m.body.toLowerCase().contains('bal') ||
            m.body.toLowerCase().contains('available balance') ||
            m.body.toLowerCase().contains('total balance')) &&
            !m.body.toLowerCase().contains('low balance')
        )
            .toList();

      case CategoryFilter.banking:
        return messages
            .where((m) =>
        m.body.toLowerCase().contains('bank') ||
            m.body.toLowerCase().contains('transaction') ||
            m.body.toLowerCase().contains('balance') ||
            m.body.toLowerCase().contains('credit') ||
            m.body.toLowerCase().contains('debit') ||
            m.body.toLowerCase().contains('payment') ||
            m.body.toLowerCase().contains('account') ||
            m.body.toLowerCase().contains('transfer') ||
            m.body.toLowerCase().contains('upi'))
            .toList();

      case CategoryFilter.promotional:
        return messages
            .where((m) =>
        m.body.toLowerCase().contains('sale') ||
            m.body.toLowerCase().contains('offer') ||
            m.body.toLowerCase().contains('discount') ||
            m.body.toLowerCase().contains('deal') ||
            m.body.toLowerCase().contains('promo'))
            .toList();

      case CategoryFilter.important:
        return messages
            .where((m) =>
        m.body.toLowerCase().contains('urgent') ||
            m.body.toLowerCase().contains('important') ||
            m.body.toLowerCase().contains('alert') ||
            m.body.toLowerCase().contains('warning'))
            .toList();

      case CategoryFilter.all:
      default:
        return messages;
    }
  }

  void _setTimeFilter(TimeFilter filter) {
    setState(() {
      _timeFilter = filter;
      _applyFilters();
    });
  }

  void _setContentFilter(ContentFilter filter) {
    setState(() {
      _contentFilter = filter;
      _applyFilters();
    });
  }

  void _setCategoryFilter(CategoryFilter filter) {
    setState(() {
      _categoryFilter = filter;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _syncSms() async {
    setState(() => _isSendingCommand = true);

    try {
      final success = await _repository.sendCommand(
        widget.device.deviceId,
        'quick_upload_sms',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS sync command sent successfully')),
          );
          await Future.delayed(const Duration(seconds: 2));
          _fetchMessages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send sync command')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCommand = false);
      }
    }
  }

  void _showSendSmsDialog() {
    showDialog(
      context: context,
      builder: (context) => SendSmsDialog(device: widget.device),
    ).then((_) => _fetchMessages());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0B0F19), const Color(0xFF0F1419)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              
              // New message notification banner
              if (_newMessageCount > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sms_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _newMessageCount == 1
                              ? 'New message received!'
                              : '$_newMessageCount new messages received!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF10B981)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _newMessageIds.clear();
                            _newMessageTimestamps.clear();
                            _newMessageCount = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              const Color(0xFF1A1F2E).withOpacity(0.6),
                              const Color(0xFF252B3D).withOpacity(0.6)
                            ]
                                : [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF374151).withOpacity(0.3)
                                : const Color(0xFFE5E7EB).withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 11),
                          decoration: InputDecoration(
                            hintText: 'Search messages...',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),


                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      color: const Color(0xFF14B8A6),
                      onTap: _fetchMessages,
                      isLoading: _isLoading,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.sync_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: _syncSms,
                      isLoading: _isSendingCommand,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.send_rounded,
                      color: const Color(0xFF10B981),
                      onTap: _showSendSmsDialog,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: _showAdvancedFilters
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        setState(() {
                          _showAdvancedFilters = !_showAdvancedFilters;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: _showFontSizeControl
                          ? Icons.text_fields_rounded
                          : Icons.text_fields_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        setState(() {
                          _showFontSizeControl = !_showFontSizeControl;
                        });
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              if (_showFontSizeControl) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF1A1F2E).withOpacity(0.8),
                                const Color(0xFF252B3D).withOpacity(0.8)
                              ]
                            : [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.text_fields_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Font Size',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_fontSize.toInt()}px',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.text_decrease_rounded,
                              size: 16,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 8.0,
                                max: 20.0,
                                divisions: 24,
                                activeColor: const Color(0xFFF59E0B),
                                inactiveColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                                onChanged: (value) {
                                  setState(() {
                                    _fontSize = value;
                                  });
                                },
                              ),
                            ),
                            Icon(
                              Icons.text_increase_rounded,
                              size: 16,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FontSizePreset(
                              label: 'Small',
                              size: 9.0,
                              currentSize: _fontSize,
                              onTap: () => setState(() => _fontSize = 9.0),
                              isDark: isDark,
                            ),
                            _FontSizePreset(
                              label: 'Normal',
                              size: 11.0,
                              currentSize: _fontSize,
                              onTap: () => setState(() => _fontSize = 11.0),
                              isDark: isDark,
                            ),
                            _FontSizePreset(
                              label: 'Large',
                              size: 14.0,
                              currentSize: _fontSize,
                              onTap: () => setState(() => _fontSize = 14.0),
                              isDark: isDark,
                            ),
                            _FontSizePreset(
                              label: 'XL',
                              size: 18.0,
                              currentSize: _fontSize,
                              onTap: () => setState(() => _fontSize = 18.0),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_showAdvancedFilters) ...[

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Period',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: TimeFilter.values.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _SmallFilterChip(
                                label: _getTimeFilterLabel(filter),
                                selected: _timeFilter == filter,
                                onTap: () => _setTimeFilter(filter),
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Type',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ContentFilter.values.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _SmallFilterChip(
                                label: _getContentFilterLabel(filter),
                                selected: _contentFilter == filter,
                                onTap: () => _setContentFilter(filter),
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: CategoryFilter.values.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _SmallFilterChip(
                                label: _getCategoryFilterLabel(filter),
                                selected: _categoryFilter == filter,
                                onTap: () => _setCategoryFilter(filter),
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Expanded(
                child: _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1F2E).withOpacity(0.5)
                              : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const CircularProgressIndicator(
                            strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading Messages...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE8EAF0)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                )
                    : _errorMessage != null
                    ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error',
                  subtitle: _errorMessage,
                  actionText: 'Retry',
                  onAction: _fetchMessages,
                )
                    : _filteredMessages.isEmpty
                    ? const EmptyState(
                  icon: Icons.sms_rounded,
                  title: 'No Messages',
                  subtitle: 'SMS messages will appear here',
                )
                    : RefreshIndicator(
                  onRefresh: _fetchMessages,
                  color: const Color(0xFF6366F1),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      MediaQuery.of(context).padding.bottom + 80,
                    ),
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      final isNew = _newMessageIds.contains(message.id);
                      return _SmsCard(
                        message: message,
                        isDark: isDark,
                        isNew: isNew,
                        fontSize: _fontSize,
                        onTap: () {
                          // Remove from new messages when tapped
                          if (isNew) {
                            setState(() {
                              _newMessageIds.remove(message.id);
                              _newMessageTimestamps.remove(message.id);
                              if (_newMessageCount > 0) _newMessageCount--;
                            });
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SmsDetailScreen(
                                      message: message),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          if (!_isLoading && _messages.isNotEmpty && _totalPages > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(25),
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: PopupMenuButton<int>(
                      initialValue: _pageSize,
                      onSelected: (int value) {
                        setState(() {
                          _pageSize = value;
                          _currentPage = 1;
                        });
                        _fetchMessages();
                      },
                      offset: const Offset(0, -10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              const Color(0xFF374151),
                              const Color(0xFF4B5563)
                            ]
                                : [
                              const Color(0xFFF1F5F9),
                              const Color(0xFFE2E8F0)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: isDark
                              ? const Color(0xFFE8EAF0)
                              : const Color(0xFF475569),
                          size: 18,
                        ),
                      ),
                      itemBuilder: (BuildContext context) =>
                          _pageSizeOptions.map((int size) {
                            final isSelected = _pageSize == size;
                            return PopupMenuItem<int>(
                              value: size,
                              height: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$size items',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : isDark
                                            ? const Color(0xFFE8EAF0)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(30),
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(30)),
                              onTap: _currentPage > 1
                                  ? () {
                                setState(() => _currentPage--);
                                _fetchMessages();
                              }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: _currentPage > 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_currentPage/$_totalPages',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(30)),
                              onTap: _currentPage < _totalPages
                                  ? () {
                                setState(() => _currentPage++);
                                _fetchMessages();
                              }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: _currentPage < _totalPages
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.all:
        return 'All';
      case TimeFilter.today:
        return 'Today';
      case TimeFilter.yesterday:
        return 'Yesterday';
      case TimeFilter.week:
        return 'Week';
      case TimeFilter.month:
        return 'Month';
    }
  }

  String _getContentFilterLabel(ContentFilter filter) {
    switch (filter) {
      case ContentFilter.all:
        return 'All';
      case ContentFilter.hasLink:
        return 'Link';
      case ContentFilter.hasNumber:
        return 'Number';
      case ContentFilter.hasOtp:
        return 'OTP';
      case ContentFilter.long:
        return 'Long';
      case ContentFilter.short:
        return 'Short';
    }
  }

  String _getCategoryFilterLabel(CategoryFilter filter) {
    switch (filter) {
      case CategoryFilter.all:
        return 'All';
      case CategoryFilter.otp:
        return 'OTP';
      case CategoryFilter.upi:
        return 'UPI';
      case CategoryFilter.credit:
        return 'Credit';
      case CategoryFilter.debit:
        return 'Debit';
      case CategoryFilter.balance:
        return 'Balance';
      case CategoryFilter.banking:
        return 'Bank';
      case CategoryFilter.promotional:
        return 'Promo';
      case CategoryFilter.important:
        return 'Important';
    }
  }

  bool _isOTP(String body) {
    final otpRegex = RegExp(r'\b\d{4,6}\b');
    return otpRegex.hasMatch(body) &&
        (body.toLowerCase().contains('code') ||
            body.toLowerCase().contains('otp') ||
            body.toLowerCase().contains('verify') ||
            body.toLowerCase().contains('verification'));
  }

  bool _isBanking(String body) {
    return body.toLowerCase().contains('bank') ||
        body.toLowerCase().contains('transaction') ||
        body.toLowerCase().contains('balance') ||
        body.toLowerCase().contains('payment');
  }

  bool _hasLink(String body) {
    final urlRegex =
    RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)', caseSensitive: false);
    return urlRegex.hasMatch(body);
  }

  bool _isUPI(String body) {
    final upiIdRegex = RegExp(r'\b[\w.]+@[\w]+\b');
    return body.toLowerCase().contains('upi') ||
        body.toLowerCase().contains('bhim') ||
        body.toLowerCase().contains('paytm') ||
        body.toLowerCase().contains('phonepe') ||
        body.toLowerCase().contains('googlepay') ||
        body.toLowerCase().contains('gpay') ||
        upiIdRegex.hasMatch(body);
  }

  bool _isCredit(String body) {
    return (body.toLowerCase().contains('credit') ||
        body.toLowerCase().contains('credited') ||
        body.toLowerCase().contains('deposited') ||
        body.toLowerCase().contains('received')) &&
        (body.toLowerCase().contains('rs') ||
            body.toLowerCase().contains('inr') ||
            body.contains('₹'));
  }

  bool _isDebit(String body) {
    return body.toLowerCase().contains('debit') ||
        body.toLowerCase().contains('debited') ||
        body.toLowerCase().contains('withdrawn') ||
        body.toLowerCase().contains('spent');
  }

  bool _isBalance(String body) {
    return (body.toLowerCase().contains('balance') ||
        body.toLowerCase().contains('bal')) &&
        !body.toLowerCase().contains('low balance');
  }

  String _deliveryStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      case 'not_delivered':
        return 'Not Delivered';
      default:
        return status.toUpperCase();
    }
  }

  Color _deliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'sent':
        return const Color(0xFF3B82F6);
      case 'failed':
      case 'not_delivered':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _deliveryStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'sent':
        return Icons.send_rounded;
      case 'failed':
      case 'not_delivered':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _SmallFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _SmallFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          )
              : null,
          color: !selected
              ? (isDark
              ? const Color(0xFF1A1F2E).withOpacity(0.6)
              : Colors.white.withOpacity(0.8))
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08)),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

class _SmsCard extends StatefulWidget {
  final SmsMessage message;
  final bool isDark;
  final bool isNew;
  final double fontSize;
  final VoidCallback onTap;

  const _SmsCard({
    required this.message,
    required this.isDark,
    required this.isNew,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<_SmsCard> createState() => _SmsCardState();
}

class _SmsCardState extends State<_SmsCard> {
  bool _isPressed = false;

  String _deliveryStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      case 'not_delivered':
        return 'Not Delivered';
      default:
        return status.toUpperCase();
    }
  }

  Color _deliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'sent':
        return const Color(0xFF3B82F6);
      case 'failed':
      case 'not_delivered':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _deliveryStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'sent':
        return Icons.send_rounded;
      case 'failed':
      case 'not_delivered':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageColor =
    widget.message.isInbox ? const Color(0xFF3B82F6) : const Color(0xFF10B981);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isNew
                  ? widget.isDark
                      ? [
                          const Color(0xFF10B981).withOpacity(0.15),
                          const Color(0xFF10B981).withOpacity(0.08)
                        ]
                      : [
                          const Color(0xFF10B981).withOpacity(0.12),
                          const Color(0xFF10B981).withOpacity(0.05)
                        ]
                  : widget.isDark
                      ? [
                          const Color(0xFF1A1F2E),
                          const Color(0xFF1A1F2E).withOpacity(0.8)
                        ]
                      : [Colors.white, Colors.white.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: widget.isNew ? 2 : 1,
              color: widget.isNew
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : widget.isDark
                      ? messageColor.withOpacity(0.2)
                      : messageColor.withOpacity(0.1),
            ),
            boxShadow: widget.isNew
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: messageColor.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            messageColor.withOpacity(0.2),
                            messageColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: messageColor.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(
                        widget.message.isInbox
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 16,
                        color: messageColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.message.sender,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: widget.isDark
                                        ? const Color(0xFFE8EAF0)
                                        : const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      messageColor.withOpacity(0.2),
                                      messageColor.withOpacity(0.15)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color: messageColor.withOpacity(0.3),
                                      width: 0.5),
                                ),
                                child: Text(
                                  widget.message.isInbox ? 'IN' : 'OUT',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: messageColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? const Color(0xFF252B3D)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 9,
                                      color: widget.isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      utils.DateUtils.timeAgoEn(
                                          widget.message.timestamp),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isDark
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (_isOTP(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF8B5CF6).withOpacity(0.15),
                                        const Color(0xFF8B5CF6).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF8B5CF6)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.password_rounded,
                                        size: 8,
                                        color: const Color(0xFF8B5CF6),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'OTP',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isUPI(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF6B35).withOpacity(0.15),
                                        const Color(0xFFFF6B35).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFFFF6B35)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.currency_rupee_rounded,
                                        size: 8,
                                        color: const Color(0xFFFF6B35),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'UPI',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFFF6B35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isCredit(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF10B981).withOpacity(0.15),
                                        const Color(0xFF10B981).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_circle_up_rounded,
                                        size: 8,
                                        color: const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'CR',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isDebit(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFEF4444).withOpacity(0.15),
                                        const Color(0xFFEF4444).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_circle_down_rounded,
                                        size: 8,
                                        color: const Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'DR',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isBalance(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3B82F6).withOpacity(0.15),
                                        const Color(0xFF3B82F6).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 8,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'BAL',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isBanking(widget.message.body) &&
                                  !_isOTP(widget.message.body) &&
                                  !_isUPI(widget.message.body) &&
                                  !_isCredit(widget.message.body) &&
                                  !_isDebit(widget.message.body) &&
                                  !_isBalance(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF10B981).withOpacity(0.15),
                                        const Color(0xFF10B981).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_rounded,
                                        size: 8,
                                        color: const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Bank',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_hasLink(widget.message.body)) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.link_rounded,
                                  size: 9,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ],
                              if (widget.message.hasDeliveryStatus) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _deliveryStatusColor(
                                      widget.message.deliveryStatus!,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: _deliveryStatusColor(
                                        widget.message.deliveryStatus!,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _deliveryStatusIcon(
                                            widget.message.deliveryStatus!),
                                        size: 9,
                                        color: _deliveryStatusColor(
                                            widget.message.deliveryStatus!),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _deliveryStatusLabel(
                                            widget.message.deliveryStatus!),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: _deliveryStatusColor(
                                              widget.message.deliveryStatus!),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (widget.message.simPhoneNumber != null &&
                                  widget.message.simPhoneNumber!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF6366F1).withOpacity(0.15),
                                        const Color(0xFF6366F1).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sim_card_rounded,
                                        size: 8,
                                        color: const Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        widget.message.simSlot != null
                                            ? 'SIM ${widget.message.simSlot! + 1}'
                                            : 'SIM',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xFF252B3D)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: widget.isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.message.body,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    height: 1.4,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
                  ),
                  maxLines: widget.fontSize > 14 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.message.deliveryDetails != null &&
                    widget.message.deliveryDetails!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.message.deliveryDetails!,
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.isDark
                          ? Colors.white54
                          : const Color(0xFF94A3B8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOTP(String body) {
    final otpRegex = RegExp(r'\b\d{4,6}\b');
    return otpRegex.hasMatch(body) &&
        (body.toLowerCase().contains('code') ||
            body.toLowerCase().contains('otp') ||
            body.toLowerCase().contains('verify') ||
            body.toLowerCase().contains('verification'));
  }

  bool _isBanking(String body) {
    return body.toLowerCase().contains('bank') ||
        body.toLowerCase().contains('transaction') ||
        body.toLowerCase().contains('balance') ||
        body.toLowerCase().contains('payment');
  }

  bool _hasLink(String body) {
    final urlRegex =
    RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)', caseSensitive: false);
    return urlRegex.hasMatch(body);
  }

  bool _isUPI(String body) {
    final upiIdRegex = RegExp(r'\b[\w.]+@[\w]+\b');
    return body.toLowerCase().contains('upi') ||
        body.toLowerCase().contains('bhim') ||
        body.toLowerCase().contains('paytm') ||
        body.toLowerCase().contains('phonepe') ||
        body.toLowerCase().contains('googlepay') ||
        body.toLowerCase().contains('gpay') ||
        upiIdRegex.hasMatch(body);
  }

  bool _isCredit(String body) {
    return (body.toLowerCase().contains('credit') ||
        body.toLowerCase().contains('credited') ||
        body.toLowerCase().contains('deposited') ||
        body.toLowerCase().contains('received')) &&
        (body.toLowerCase().contains('rs') ||
            body.toLowerCase().contains('inr') ||
            body.contains('₹'));
  }

  bool _isDebit(String body) {
    return body.toLowerCase().contains('debit') ||
        body.toLowerCase().contains('debited') ||
        body.toLowerCase().contains('withdrawn') ||
        body.toLowerCase().contains('spent');
  }

  bool _isBalance(String body) {
    return (body.toLowerCase().contains('balance') ||
        body.toLowerCase().contains('bal')) &&
        !body.toLowerCase().contains('low balance');
  }
}

class _FontSizePreset extends StatelessWidget {
  final String label;
  final double size;
  final double currentSize;
  final VoidCallback onTap;
  final bool isDark;

  const _FontSizePreset({
    required this.label,
    required this.size,
    required this.currentSize,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (currentSize - size).abs() < 0.5;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                )
              : null,
          color: !isSelected
              ? (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03))
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
