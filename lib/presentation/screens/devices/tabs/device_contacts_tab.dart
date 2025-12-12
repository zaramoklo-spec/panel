import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/device.dart';
import '../../../../data/models/contact.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../providers/device_provider.dart';
import '../../../widgets/common/empty_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceContactsTab extends StatefulWidget {
  final Device device;

  const DeviceContactsTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceContactsTab> createState() => _DeviceContactsTabState();
}

class _DeviceContactsTabState extends State<DeviceContactsTab> {
  final DeviceRepository _repository = DeviceRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  bool _isSendingCommand = false;
  String? _errorMessage;
  String _searchQuery = '';

  int _currentPage = 1;
  int _pageSize = 100;
  int _totalContacts = 0;
  int _totalPages = 0;

  final List<int> _pageSizeOptions = [100, 250, 500];
  final Set<String> _deletingContactIds = {};

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void didUpdateWidget(DeviceContactsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.device.deviceId != widget.device.deviceId || 
        oldWidget.key != widget.key) {
      _fetchContacts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skip = (_currentPage - 1) * _pageSize;
      final result = await _repository.getDeviceContacts(
        widget.device.deviceId,
        skip: skip,
        limit: _pageSize,
      );
      setState(() {
        _contacts = result['contacts'] as List<Contact>;
        _totalContacts = result['total'] as int;
        _totalPages = (_totalContacts / _pageSize).ceil();
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading contacts';
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    var filtered = _contacts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) {
        final query = _searchQuery.toLowerCase();
        return contact.name.toLowerCase().contains(query) ||
            contact.phoneNumber.toLowerCase().contains(query) ||
            (contact.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredContacts = filtered;
    });
  }

  void _setSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty && _currentPage != 1) {
        _currentPage = 1;
      }
      _applySearch();
    });
  }

  Future<void> _syncContacts() async {
    setState(() => _isSendingCommand = true);

    final deviceProvider = context.read<DeviceProvider>();
    final success = await deviceProvider.sendCommand(
        widget.device.deviceId, 'quick_upload_contacts');

    setState(() => _isSendingCommand = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync command sent' : 'Failed to send command'),
          backgroundColor: success
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.68)),
        ),
      );

      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        _fetchContacts();
      }
    }
  }

  Future<void> _deleteSingleContact(Contact contact) async {
    if (_deletingContactIds.contains(contact.id)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete contact?'),
          content: const Text('This contact will be removed from the panel.'),
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

    setState(() => _deletingContactIds.add(contact.id));
    final deviceProvider = context.read<DeviceProvider>();
    final success = await deviceProvider.deleteSingleContact(widget.device.deviceId, contact.id);
    if (!mounted) return;
    setState(() => _deletingContactIds.remove(contact.id));

    if (success) {
      setState(() {
        _contacts.removeWhere((c) => c.id == contact.id);
        _filteredContacts.removeWhere((c) => c.id == contact.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact deleted'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete contact'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1F2E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _setSearchQuery,
                    style: const TextStyle(fontSize: 11.2),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 17.6,
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
                          _setSearchQuery('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.8,
                        vertical: 11.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8.96),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSendingCommand ? null : _syncContacts,
                    borderRadius: BorderRadius.circular(8.96),
                    child: Container(
                      padding: const EdgeInsets.all(9.6),
                      child: _isSendingCommand
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.sync_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9.6,
                    vertical: 4.8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(6.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 12.8,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '${_filteredContacts.length} Results'
                            : '${_totalContacts} Contacts',
                        style: const TextStyle(
                          fontSize: 9.6,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            onAction: _fetchContacts,
          )
              : _filteredContacts.isEmpty
              ? EmptyState(
            icon: _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            title: _searchQuery.isNotEmpty
                ? 'No Results'
                : 'No Contacts',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Contacts will appear here',
          )
              : RefreshIndicator(
            onRefresh: _fetchContacts,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 80,
              ),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return _ContactCard(
                  contact: contact,
                  isDark: isDark,
                  onDelete: () => _deleteSingleContact(contact),
                  isDeleting: _deletingContactIds.contains(contact.id),
                );
              },
            ),
          ),
        ),
          ],
        ),

        if (!_isLoading && _contacts.isNotEmpty && _totalPages > 1 && _searchQuery.isEmpty)
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
                      _fetchContacts();
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
                                    _fetchContacts();
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
                                    _fetchContacts();
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
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final bool isDark;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _ContactCard({
    required this.contact,
    required this.isDark,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    final initial = contact.name.isNotEmpty
        ? contact.name[0].toUpperCase()
        : '?';

    final colors = _getGradientColors(initial);

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
          children: [

            Container(
              width: 41.6,
              height: 41.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(10.24),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 11.2,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.phoneNumber,
                          style: TextStyle(
                            fontSize: 10.4,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (contact.email != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 11.2,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contact.email!,
                            style: TextStyle(
                              fontSize: 9.6,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            PopupMenuButton(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.24),
              ),
              icon: Container(
                padding: const EdgeInsets.all(6.4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(7.68),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF64748B),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          size: 12.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _makeCall(context, contact.phoneNumber),
                ),
                PopupMenuItem(
                  enabled: !isDeleting,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          size: 12.8,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Delete Contact',
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: onDelete,
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: const Icon(
                          Icons.content_copy_rounded,
                          size: 12.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Copy Number',
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: contact.phoneNumber));
                    Future.delayed(const Duration(milliseconds: 100), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Number copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.68),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String initial) {
    final charCode = initial.codeUnitAt(0);
    final hue = (charCode * 15) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor(),
      HSLColor.fromAHSL(1, (hue + 30) % 360, 0.7, 0.6).toColor(),
    ];
  }

  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot make call'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.68),
            ),
          ),
        );
      }
    }
  }
}