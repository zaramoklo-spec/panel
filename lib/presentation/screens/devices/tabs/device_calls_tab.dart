import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/device.dart';
import '../../../../data/models/call_log.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../../core/utils/date_utils.dart' as utils;
import '../../../widgets/common/empty_state.dart';
import '../../../providers/device_provider.dart';

class DeviceCallsTab extends StatefulWidget {
  final Device device;

  const DeviceCallsTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceCallsTab> createState() => _DeviceCallsTabState();
}

class _DeviceCallsTabState extends State<DeviceCallsTab>
    with SingleTickerProviderStateMixin {
  final DeviceRepository _repository = DeviceRepository();
  List<CallLog> _calls = [];
  bool _isLoading = false;
  String? _errorMessage;

  late TabController _tabController;

  int _currentPage = 1;
  int _pageSize = 100;
  int _totalCalls = 0;
  int _totalPages = 0;

  final List<int> _pageSizeOptions = [100, 250, 500];
  final Set<String> _deletingCallIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchCalls();
  }

  @override
  void didUpdateWidget(DeviceCallsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.deviceId != widget.device.deviceId || 
        oldWidget.key != widget.key) {
      _currentPage = 1;
      _fetchCalls();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCalls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skip = (_currentPage - 1) * _pageSize;
      final result = await _repository.getDeviceCalls(
        widget.device.deviceId,
        skip: skip,
        limit: _pageSize,
      );

      if (result['calls'] != null) {
        final callsList = result['calls'] as List;
        List<CallLog> parsedCalls = [];

        if (callsList.isNotEmpty) {
          if (callsList.first is CallLog) {
            parsedCalls = callsList.cast<CallLog>();
          } else if (callsList.first is Map) {
            for (var item in callsList) {
              try {
                parsedCalls.add(CallLog.fromJson(item as Map<String, dynamic>));
              } catch (e) {
                debugPrint('Error parsing call: $e');
              }
            }
          }
        }

        setState(() {
          _calls = parsedCalls;
          _totalCalls = result['total'] as int? ?? parsedCalls.length;
          _totalPages = (_totalCalls / _pageSize).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _calls = [];
          _totalCalls = 0;
          _totalPages = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSingleCall(CallLog call) async {
    if (_deletingCallIds.contains(call.id)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this call log?'),
          content: const Text('The selected call log will be removed from the panel.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _deletingCallIds.add(call.id));
    final deviceProvider = context.read<DeviceProvider>();
    final targetId = call.callId ?? call.id;
    final success = await deviceProvider.deleteSingleCall(widget.device.deviceId, targetId);
    if (!mounted) return;
    setState(() => _deletingCallIds.remove(call.id));

    if (success) {
      setState(() {
        _calls.removeWhere((c) => c.id == call.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call log deleted'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete call log'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<CallLog> _filterCalls(String type) {
    if (type == 'all') return _calls;
    return _calls.where((call) => call.callType.toLowerCase() == type).toList();
  }

  void _showCallDetails(CallLog call) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CallDetailsSheet(call: call),
    );
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

              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1F2E).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF374151).withOpacity(0.3)
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: false,
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF64748B),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(6),
                          tabs: [
                            _buildTab('All', Icons.call_rounded, _totalCalls),
                            _buildTab(
                                'In',
                                Icons.call_received_rounded,
                                null), // Don't show count for filtered tabs
                            _buildTab(
                                'Out',
                                Icons.call_made_rounded,
                                null),
                            _buildTab(
                                'Miss',
                                Icons.phone_missed_rounded,
                                null),
                            _buildTab(
                                'Reject',
                                Icons.phone_disabled_rounded,
                                null),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

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
                              child:
                                  const CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading Call Logs...',
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
                        ? Center(
                            child: EmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Error',
                              subtitle: _errorMessage,
                              actionText: 'Retry',
                              onAction: _fetchCalls,
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCallList('all', isDark),
                              _buildCallList('incoming', isDark),
                              _buildCallList('outgoing', isDark),
                              _buildCallList('missed', isDark),
                              _buildCallList('rejected', isDark),
                            ],
                          ),
              ),
            ],
          ),

          if (!_isLoading && _calls.isNotEmpty && _totalPages > 1)
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
                        _fetchCalls();
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
                                      _fetchCalls();
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
                                      _fetchCalls();
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

  Widget _buildTab(String label, IconData icon, int? count) {
    return Tab(
      height: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (count != null && count > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count > 999 ? '999+' : count.toString(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallList(String type, bool isDark) {
    final filteredCalls = _filterCalls(type);

    if (filteredCalls.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.phone_missed_rounded,
          title: 'No ${type == 'all' ? 'Call Logs' : '${type.capitalize()} Calls'}',
          subtitle: type == 'all'
              ? 'Call logs will appear here'
              : 'No ${type} calls found',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCalls,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredCalls.length,
        itemBuilder: (context, index) {
          return _CallLogCard(
            call: filteredCalls[index],
            isDark: isDark,
            onTap: () => _showCallDetails(filteredCalls[index]),
            onDelete: () => _deleteSingleCall(filteredCalls[index]),
            isDeleting: _deletingCallIds.contains(filteredCalls[index].id),
          );
        },
      ),
    );
  }
}

class _CallLogCard extends StatefulWidget {
  final CallLog call;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _CallLogCard({
    required this.call,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  State<_CallLogCard> createState() => _CallLogCardState();
}

class _CallLogCardState extends State<_CallLogCard> {
  bool _isPressed = false;

  Color _getCallTypeColor() {
    final type = widget.call.callType.toLowerCase();
    switch (type) {
      case 'incoming':
        return const Color(0xFF10B981);
      case 'outgoing':
        return const Color(0xFF3B82F6);
      case 'missed':
        return const Color(0xFFEF4444);
      case 'rejected':
        return const Color(0xFFF59E0B);
      case 'blocked':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getCallTypeIcon() {
    final type = widget.call.callType.toLowerCase();
    switch (type) {
      case 'incoming':
        return Icons.call_received_rounded;
      case 'outgoing':
        return Icons.call_made_rounded;
      case 'missed':
        return Icons.phone_missed_rounded;
      case 'rejected':
        return Icons.phone_disabled_rounded;
      case 'blocked':
        return Icons.block_rounded;
      default:
        return Icons.phone_rounded;
    }
  }

  String _getCallTypeLabel() {
    final type = widget.call.callType.toLowerCase();
    switch (type) {
      case 'incoming':
        return 'Incoming';
      case 'outgoing':
        return 'Outgoing';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      case 'blocked':
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }

  String _formatTimeAgo() {
    return utils.DateUtils.timeAgoEn(widget.call.timestampDate);
  }

  @override
  Widget build(BuildContext context) {
    final callColor = _getCallTypeColor();
    final displayName = widget.call.displayName;
    final number = widget.call.number;
    final duration = widget.call.formattedDuration;

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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      const Color(0xFF1A1F2E),
                      const Color(0xFF1A1F2E).withOpacity(0.8)
                    ]
                  : [Colors.white, Colors.white.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: widget.isDark
                  ? callColor.withOpacity(0.2)
                  : callColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: callColor.withOpacity(0.1),
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
            child: Row(
              children: [

                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        callColor.withOpacity(0.2),
                        callColor.withOpacity(0.1)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: callColor.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(_getCallTypeIcon(), size: 18, color: callColor),
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
                              displayName,
                              style: TextStyle(
                                fontSize: 13,
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
                                  callColor.withOpacity(0.2),
                                  callColor.withOpacity(0.15)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: callColor.withOpacity(0.3), width: 0.5),
                            ),
                            child: Text(
                              _getCallTypeLabel().toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: callColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (displayName != number && number.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            number,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF64748B),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
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
                                  size: 10,
                                  color: widget.isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                    _formatTimeAgo(),
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
                          if (widget.call.duration > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1).withOpacity(0.15),
                                    const Color(0xFF8B5CF6).withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color:
                                        const Color(0xFF6366F1).withOpacity(0.2),
                                    width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_rounded,
                                      size: 10, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 3),
                                  Text(
                                    duration,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6366F1),
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

                IconButton(
                  onPressed: widget.isDeleting ? null : widget.onDelete,
                  icon: widget.isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFFEF4444)),
                          ),
                        )
                      : const Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallDetailsSheet extends StatelessWidget {
  final CallLog call;

  const _CallDetailsSheet({required this.call});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Call Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? const Color(0xFFE8EAF0)
                  : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
              icon: Icons.person,
              label: 'Name',
              value: call.name,
              isDark: isDark),
          _DetailRow(
              icon: Icons.phone,
              label: 'Number',
              value: call.number,
              isDark: isDark),
          _DetailRow(
              icon: Icons.call,
              label: 'Type',
              value: call.callType,
              isDark: isDark),
          _DetailRow(
              icon: Icons.timer,
              label: 'Duration',
              value: call.formattedDuration,
              isDark: isDark),
          _DetailRow(
              icon: Icons.calendar_today,
              label: 'Time',
              value: call.timestamp,
              isDark: isDark),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252B3D)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}