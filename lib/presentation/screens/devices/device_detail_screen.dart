import 'package:flutter/material.dart';
import '../../../data/models/device.dart';
import 'tabs/device_info_tab.dart';
import 'tabs/device_sms_tab.dart';
import 'tabs/device_contacts_tab.dart';
import 'tabs/device_calls_tab.dart';
import 'tabs/device_logs_tab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // SliverAppBar with device header
            SliverAppBar(
              floating: false,
              pinned: false,
              snap: false,
              expandedHeight: 200,
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(6.4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(7.68),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 9.6, top: 6.4, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.device.isOnline
                          ? [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF059669).withOpacity(0.2)
                      ]
                          : [
                        const Color(0xFFEF4444).withOpacity(0.2),
                        const Color(0xFFDC2626).withOpacity(0.2)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.24),
                    border: Border.all(
                      color: widget.device.isOnline
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.4,
                        height: 6.4,
                        decoration: BoxDecoration(
                          color: widget.device.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.device.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                                  .withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.device.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: widget.device.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 60, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF6366F1).withOpacity(0.2),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ]
                          : [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12.8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smartphone_rounded,
                              color: Colors.white,
                              size: 25.6,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.device.model,
                                  style: TextStyle(
                                    fontSize: 19.2,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.device.manufacturer,
                                  style: TextStyle(
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(9.6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10.24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 12.8),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.device.deviceId,
                                style: const TextStyle(
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(7.68),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Info', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('SMS', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Contacts', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Calls', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Logs', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
                isDark: isDark,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            DeviceInfoTab(device: widget.device),
            DeviceSmsTab(device: widget.device),
            DeviceContactsTab(device: widget.device),
            DeviceCallsTab(device: widget.device),
            DeviceLogsTab(device: widget.device),
          ],
        ),
      ),
    );
  }
}

// Sticky TabBar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabBarDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3.2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10.24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}