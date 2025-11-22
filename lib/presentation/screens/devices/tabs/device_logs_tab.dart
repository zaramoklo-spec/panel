import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../data/models/device_log.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../../core/utils/date_utils.dart' as utils;
import '../../../widgets/common/empty_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum LogFilter { all, system, sms, contacts, error }

class DeviceLogsTab extends StatefulWidget {
  final Device device;

  const DeviceLogsTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceLogsTab> createState() => _DeviceLogsTabState();
}

class _DeviceLogsTabState extends State<DeviceLogsTab> {
  final DeviceRepository _repository = DeviceRepository();

  List<DeviceLog> _logs = [];
  List<DeviceLog> _filteredLogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  LogFilter _currentFilter = LogFilter.all;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.getDeviceLogs(widget.device.deviceId);
      setState(() {
        _logs = result['logs'] as List<DeviceLog>;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading logs';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    var filtered = _logs;

    switch (_currentFilter) {
      case LogFilter.system:
        filtered = filtered.where((l) => l.type == 'system').toList();
        break;
      case LogFilter.sms:
        filtered = filtered.where((l) => l.type == 'sms').toList();
        break;
      case LogFilter.contacts:
        filtered = filtered.where((l) => l.type == 'contacts').toList();
        break;
      case LogFilter.error:
        filtered = filtered.where((l) => l.isError).toList();
        break;
      case LogFilter.all:
      default:
        break;
    }

    setState(() {
      _filteredLogs = filtered;
    });
  }

  void _setFilter(LogFilter filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [

        if (_logs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ModernFilterChip(
                    label: 'All',
                    count: _logs.length,
                    selected: _currentFilter == LogFilter.all,
                    onTap: () => _setFilter(LogFilter.all),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'System',
                    count: _logs.where((l) => l.type == 'system').length,
                    selected: _currentFilter == LogFilter.system,
                    onTap: () => _setFilter(LogFilter.system),
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'SMS',
                    count: _logs.where((l) => l.type == 'sms').length,
                    selected: _currentFilter == LogFilter.sms,
                    onTap: () => _setFilter(LogFilter.sms),
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'Contacts',
                    count: _logs.where((l) => l.type == 'contacts').length,
                    selected: _currentFilter == LogFilter.contacts,
                    onTap: () => _setFilter(LogFilter.contacts),
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'Errors',
                    count: _logs.where((l) => l.isError).length,
                    selected: _currentFilter == LogFilter.error,
                    color: const Color(0xFFEF4444),
                    onTap: () => _setFilter(LogFilter.error),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Error',
            subtitle: _errorMessage,
            actionText: 'Retry',
            onAction: _fetchLogs,
          )
              : _filteredLogs.isEmpty
              ? const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No Logs',
            subtitle: 'Activity logs will appear here',
          )
              : RefreshIndicator(
            onRefresh: _fetchLogs,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filteredLogs.length,
              itemBuilder: (context, index) {
                final log = _filteredLogs[index];
                return _LogCard(
                  log: log,
                  isDark: isDark,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool isDark;

  const _ModernFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF6366F1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            colors: [chipColor, chipColor.withOpacity(0.8)],
          )
              : null,
          color: !selected
              ? (isDark
              ? const Color(0xFF1A1F2E)
              : const Color(0xFFF1F5F9))
              : null,
          borderRadius: BorderRadius.circular(7.68),
          border: Border.all(
            color: selected
                ? chipColor
                : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05)),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: chipColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.8, vertical: 1.6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.2)
                    : chipColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3.84),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 8.8,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : chipColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final DeviceLog log;
  final bool isDark;

  const _LogCard({
    required this.log,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getLogColor();
    final icon = _getLogIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9.6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.96),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(5.12),
                        ),
                        child: Text(
                          log.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time_rounded,
                        size: 9.6,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          utils.DateUtils.timeAgoEn(log.timestamp),
                          style: TextStyle(
                            fontSize: 9.6,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor() {
    if (log.isError) return const Color(0xFFEF4444);
    if (log.isWarning) return const Color(0xFFF59E0B);

    switch (log.type) {
      case 'system':
        return const Color(0xFF3B82F6);
      case 'sms':
        return const Color(0xFF10B981);
      case 'contacts':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getLogIcon() {
    if (log.isError) return Icons.error_rounded;
    if (log.isWarning) return Icons.warning_rounded;

    switch (log.type) {
      case 'system':
        return Icons.settings_rounded;
      case 'sms':
        return Icons.chat_bubble_rounded;
      case 'contacts':
        return Icons.people_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}