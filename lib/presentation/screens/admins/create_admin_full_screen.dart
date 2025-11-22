import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/admin.dart';
import '../../providers/admin_provider.dart';
import 'success_dialog.dart';

class CreateAdminFullScreen extends StatefulWidget {
  const CreateAdminFullScreen({super.key});

  @override
  State<CreateAdminFullScreen> createState() => _CreateAdminFullScreenState();
}

class _CreateAdminFullScreenState extends State<CreateAdminFullScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Basic info controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  // 2FA Telegram
  final _telegram2faChatIdController = TextEditingController();
  
  // Bot controllers (5 bots)
  final List<TextEditingController> _botNameControllers =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _botTokenControllers =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _botChatIdControllers =
      List.generate(5, (_) => TextEditingController());

  String _selectedRole = 'admin';
  bool _obscurePassword = true;
  bool _isLoading = false;
  DateTime? _expiresAt;
  
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set default bot names
    _botNameControllers[0].text = 'devices_bot';
    _botNameControllers[1].text = 'sms_bot';
    _botNameControllers[2].text = 'logs_bot';
    _botNameControllers[3].text = 'auth_bot';
    _botNameControllers[4].text = 'future_bot';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
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

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) {
      // Show error and switch to the tab with error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create telegram bots list
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
    final success = await adminProvider.createAdmin(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      role: _selectedRole,
      telegram2faChatId: _telegram2faChatIdController.text.trim().isEmpty
          ? null
          : _telegram2faChatIdController.text.trim(),
      telegramBots: telegramBots,
      expiresAt: _expiresAt,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        // ?? Success Animation!
        await _showSuccessAnimation();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(adminProvider.errorMessage ?? 'Error creating admin'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Admin'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _currentTab = index),
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Basic Info'),
            Tab(icon: Icon(Icons.telegram), text: '2FA & Bots'),
            Tab(icon: Icon(Icons.preview), text: 'Review'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Basic Info
            _buildBasicInfoTab(isDark),
            
            // Tab 2: Telegram Bots
            _buildTelegramBotsTab(isDark),
            
            // Tab 3: Review
            _buildReviewTab(isDark),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButton(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildBasicInfoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Username
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username *',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              hintText: 'e.g., john_admin',
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              hintText: 'e.g., John Doe',
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              hintText: 'e.g., john@example.com',
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Email is not valid';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              hintText: 'At least 6 characters',
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Role Cards - Compact
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Role *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      role: 'super_admin',
                      title: 'Super Admin',
                      icon: Icons.stars_rounded,
                      color: const Color(0xFFEF4444),
                      isSelected: _selectedRole == 'super_admin',
                      onTap: () => setState(() => _selectedRole = 'super_admin'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _RoleCard(
                      role: 'admin',
                      title: 'Admin',
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF6366F1),
                      isSelected: _selectedRole == 'admin',
                      onTap: () => setState(() => _selectedRole = 'admin'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _RoleCard(
                      role: 'viewer',
                      title: 'Viewer',
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF10B981),
                      isSelected: _selectedRole == 'viewer',
                      onTap: () => setState(() => _selectedRole = 'viewer'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Expiry Date - Compact
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFF59E0B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _expiresAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        23,
                        59,
                        59,
                      );
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _expiresAt == null
                              ? 'Set expiry (optional)'
                              : 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _expiresAt == null
                                ? Colors.grey
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_expiresAt != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _expiresAt = null;
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramBotsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0088cc), Color(0xFF00BFFF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.telegram_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Telegram Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // 2FA Section
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
                    Icon(Icons.security_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '2FA Bot (Shared)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Telegram Chat ID for receiving OTP codes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telegram2faChatIdController,
                  decoration: InputDecoration(
                    labelText: 'Telegram Chat ID',
                    prefixIcon: const Icon(Icons.telegram_outlined, size: 20),
                    hintText: 'e.g., -1001234567890',
                    filled: true,
                    fillColor: isDark 
                        ? Colors.white.withOpacity(0.03) 
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notification Bots - Compact
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Notification Bots (5)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Bots
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
    
    final botColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [botColors[index], botColors[index].withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  botPurposes[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bot Name
          TextFormField(
            controller: _botNameControllers[index],
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              labelText: 'Name *',
              labelStyle: const TextStyle(fontSize: 10),
              prefixIcon: const Icon(Icons.label_outline_rounded, size: 14),
              hintText: 'bot_${index + 1}',
              hintStyle: const TextStyle(fontSize: 10),
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.02) 
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 6),

          // Bot Token
          TextFormField(
            controller: _botTokenControllers[index],
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              labelText: 'Token *',
              labelStyle: const TextStyle(fontSize: 10),
              prefixIcon: const Icon(Icons.key_outlined, size: 14),
              hintText: '123:AAA...',
              hintStyle: const TextStyle(fontSize: 10),
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.02) 
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Token is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 6),

          // Chat ID
          TextFormField(
            controller: _botChatIdControllers[index],
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              labelText: 'Chat ID *',
              labelStyle: const TextStyle(fontSize: 10),
              prefixIcon: const Icon(Icons.tag_outlined, size: 14),
              hintText: '-100123...',
              hintStyle: const TextStyle(fontSize: 10),
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withOpacity(0.02) 
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Chat ID is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.preview_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Review & Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Basic Info Card
          _buildReviewCard(
            'Basic Information',
            [
              _buildReviewItem('Username', _usernameController.text),
              _buildReviewItem('Full Name', _fullNameController.text),
              _buildReviewItem('Email', _emailController.text),
              _buildReviewItem('Role', _selectedRole.replaceAll('_', ' ').toUpperCase()),
            ],
            isDark,
          ),

          const SizedBox(height: 16),

          // Telegram Info Card
          _buildReviewCard(
            'Telegram Configuration',
            [
              _buildReviewItem(
                '2FA Chat ID',
                _telegram2faChatIdController.text.isEmpty
                    ? 'Not configured'
                    : _telegram2faChatIdController.text,
              ),
              _buildReviewItem(
                'Configured Bots',
                '${_botTokenControllers.where((c) => c.text.isNotEmpty).length} of 5',
              ),
            ],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      String title, List<Widget> children, bool isDark) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              value.isEmpty ? '-' : value,
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

  Widget _buildFloatingButton(bool isDark) {
    if (_isLoading) return const SizedBox.shrink();
    
    return AnimatedScale(
      scale: _isLoading ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_currentTab < 2) {
                    _tabController.animateTo(_currentTab + 1);
                    setState(() => _currentTab++);
                  } else {
                    _createAdmin();
                  }
                },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _currentTab == 2
              ? const Icon(Icons.check_rounded, size: 28)
              : const Icon(Icons.arrow_forward_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1A1F2E).withOpacity(0.95) 
              : Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(3, (index) {
            final isActive = index <= _currentTab;
            final isCompleted = index < _currentTab;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              )
                            : null,
                        color: isActive
                            ? null
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < 2)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF059669),
                                ],
                              )
                            : null,
                        color: isCompleted
                            ? null
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade300),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            )
                          : null,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ?? ?????????? Role Card
class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

