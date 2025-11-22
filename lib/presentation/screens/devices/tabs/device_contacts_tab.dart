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

  @override
  void initState() {
    super.initState();
    _fetchContacts();
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
      final result =
      await _repository.getDeviceContacts(widget.device.deviceId);
      setState(() {
        _contacts = result['contacts'] as List<Contact>;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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
                        '${_filteredContacts.length} Contacts',
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return _ContactCard(
                  contact: contact,
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

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final bool isDark;

  const _ContactCard({
    required this.contact,
    required this.isDark,
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