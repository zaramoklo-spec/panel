import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/admin.dart';
import '../../providers/admin_provider.dart';

class EditAdminFullScreen extends StatefulWidget {
  final Admin admin;

  const EditAdminFullScreen({
    super.key,
    required this.admin,
  });

  @override
  State<EditAdminFullScreen> createState() => _EditAdminFullScreenState();
}

class _EditAdminFullScreenState extends State<EditAdminFullScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedRole;
  late bool _isActive;

  late TextEditingController _telegram2faChatIdController;

  final List<TextEditingController> _botNameControllers =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _botTokenControllers =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _botChatIdControllers =
      List.generate(5, (_) => TextEditingController());

  bool _isLoading = false;
  
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.admin.role;
    _isActive = widget.admin.isActive;
    
    _telegram2faChatIdController = TextEditingController(
      text: widget.admin.telegram2faChatId ?? '',
    );
    
    _tabController = TabController(length: 2, vsync: this);

    if (widget.admin.telegramBots != null) {
      for (int i = 0; i < widget.admin.telegramBots!.length && i < 5; i++) {
        final bot = widget.admin.telegramBots![i];
        _botNameControllers[i].text = bot.botName;
        _botTokenControllers[i].text = bot.token;
        _botChatIdControllers[i].text = bot.chatId;
      }
    } else {

      _botNameControllers[0].text = 'devices_bot';
      _botNameControllers[1].text = 'sms_bot';
      _botNameControllers[2].text = 'logs_bot';
      _botNameControllers[3].text = 'auth_bot';
      _botNameControllers[4].text = 'future_bot';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telegram2faChatIdController.dispose();
    
    for (var controller in _botNameControllers) {
      controller.dispose();
    }
    for (var controller in _botTokenControllers) {
      controller.dispose();
    }
    for (var controller in _botChatIdControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _updateAdmin() async {
    setState(() => _isLoading = true);

    final List<TelegramBot> telegramBots = [];
    for (int i = 0; i < 5; i++) {
      telegramBots.add(TelegramBot(
        botId: i + 1,
        botName: _botNameControllers[i].text.trim().isEmpty
            ? 'bot_${i + 1}'
            : _botNameControllers[i].text.trim(),
        token: _botTokenControllers[i].text.trim(),
        chatId: _botChatIdControllers[i].text.trim(),
      ));
    }

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateAdmin(
      widget.admin.username,
      role: _selectedRole != widget.admin.role ? _selectedRole : null,
      isActive: _isActive != widget.admin.isActive ? _isActive : null,
      telegram2faChatId: _telegram2faChatIdController.text.trim(),
      telegramBots: telegramBots,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.errorMessage ?? 'Error updating admin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.admin.username}'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _currentTab = index),
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Basic Settings'),
            Tab(icon: Icon(Icons.telegram), text: 'Telegram Bots'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [

          _buildBasicSettingsTab(isDark),

          _buildTelegramBotsTab(isDark),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildBasicSettingsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow('Username', widget.admin.username),
                _buildInfoRow('Full Name', widget.admin.fullName),
                _buildInfoRow('Email', widget.admin.email),
                _buildInfoRow(
                  'Created',
                  widget.admin.createdAt.toString().split('.')[0],
                ),
                if (widget.admin.lastLogin != null)
                  _buildInfoRow(
                    'Last Login',
                    widget.admin.lastLogin.toString().split('.')[0],
                  ),
                _buildInfoRow(
                  'Login Count',
                  widget.admin.loginCount.toString(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role & Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Viewer'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Account Status'),
                  subtitle: Text(_isActive ? 'Active' : 'Inactive'),
                  value: _isActive,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramBotsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '2FA Bot (Shared)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Telegram Chat ID for receiving OTP codes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telegram2faChatIdController,
                  decoration: InputDecoration(
                    labelText: 'Telegram Chat ID',
                    prefixIcon: const Icon(Icons.telegram),
                    hintText: 'e.g., -1001234567890',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configured Bots: ${widget.admin.configuredBotsCount} of 5',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Notification Bots',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Update Telegram bots configuration',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ...List.generate(5, (index) => _buildBotCard(index, isDark)),
        ],
      ),
    );
  }

  Widget _buildBotCard(int index, bool isDark) {
    final botPurposes = [
      'Device Notifications',
      'SMS Notifications',
      'Admin Activity Logs',
      'Login/Logout Logs',
      'Reserved for Future',
    ];

    final isConfigured = _botTokenControllers[index].text.isNotEmpty &&
        _botChatIdControllers[index].text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfigured
              ? const Color(0xFF10B981).withOpacity(0.5)
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConfigured
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bot ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  botPurposes[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isConfigured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '? Active',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _botNameControllers[index],
            decoration: InputDecoration(
              labelText: 'Bot Name',
              prefixIcon: const Icon(Icons.label, size: 20),
              hintText: 'e.g., my_device_bot',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _botTokenControllers[index],
            decoration: InputDecoration(
              labelText: 'Bot Token',
              prefixIcon: const Icon(Icons.key, size: 20),
              hintText: '1234567890:AAA...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _botChatIdControllers[index],
            decoration: InputDecoration(
              labelText: 'Chat ID',
              prefixIcon: const Icon(Icons.tag, size: 20),
              hintText: '-1001234567890',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateAdmin,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save Changes'),
      ),
    );
  }
}
