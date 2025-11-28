import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/repositories/tools_repository.dart';

class LeakLookupScreen extends StatefulWidget {
  final String? initialQuery;

  const LeakLookupScreen({super.key, this.initialQuery});

  @override
  State<LeakLookupScreen> createState() => _LeakLookupScreenState();
}

class _LeakLookupScreenState extends State<LeakLookupScreen>
    with TickerProviderStateMixin {
  final ToolsRepository _repository = ToolsRepository();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _limitController =
      TextEditingController(text: '100');

  bool _isLoading = false;
  String _language = 'en';
  Map<String, dynamic>? _result;
  String? _errorMessage;
  bool _showJson = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;

  static const int _defaultLimit = 100;
  static const int _minLimit = 1;
  static const int _maxLimit = 10000;
  static const int _maxDisplayItems = 10;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setInitialQuery();
  }

  void _initializeControllers() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _setInitialQuery() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _queryController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _runLookup() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      _showWarningSnackBar('Please enter a phone number or query');
      return;
    }

    final limit = _parseAndClampLimit();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showJson = false;
    });

    try {
      final data = await _repository.lookupLeak(
        query: query,
        limit: limit,
        lang: _language,
      );
      setState(() {
        _result = data;
      });
      _slideController.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _result = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _parseAndClampLimit() {
    final limit = int.tryParse(_limitController.text.trim()) ?? _defaultLimit;
    return limit.clamp(_minLimit, _maxLimit);
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _resetForm() {
    _queryController.clear();
    _limitController.text = _defaultLimit.toString();
    setState(() {
      _result = null;
      _errorMessage = null;
      _showJson = false;
    });
  }

  void _toggleJsonView() {
    setState(() => _showJson = !_showJson);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _queryController.text = data!.text!;
    }
  }

  void _copyJsonToClipboard() {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);
    Clipboard.setData(ClipboardData(text: prettyJson));
    _showSuccessSnackBar('Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getBackgroundGradientColors(isDark),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchCard(isDark),
                      const SizedBox(height: 8),
                      _buildResultSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getBackgroundGradientColors(bool isDark) {
    return isDark
        ? [
            const Color(0xFF0F172A),
            const Color(0xFF111827),
            const Color(0xFF1F2937),
          ]
        : [
            const Color(0xFFF9FAFB),
            const Color(0xFFF3F4F6),
            Colors.white,
          ];
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          _buildAppBarIcon(isDark),
          const SizedBox(width: 8),
          _buildAppBarTitle(isDark),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 18,
            ),
            tooltip: 'Reset',
            onPressed: _isLoading ? null : _resetForm,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: Color(0xFF10B981),
        size: 18,
      ),
    );
  }

  Widget _buildAppBarTitle(bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Leak Lookup',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Security Intelligence Search',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchCardHeader(isDark),
          const SizedBox(height: 8),
          _buildQueryField(isDark),
          const SizedBox(height: 6),
          _buildOptionsRow(isDark),
          const SizedBox(height: 8),
          _buildSearchButton(),
        ],
      ),
    );
  }

  BoxDecoration _getCardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildSearchCardHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.search_rounded,
            color: Color(0xFF10B981),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Search Parameters',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQueryField(bool isDark) {
    return _buildTextField(
      controller: _queryController,
      label: 'Query',
      hint: '+919876543210',
      icon: Icons.phone_android_rounded,
      iconColor: const Color(0xFF10B981),
      isDark: isDark,
      onPaste: _pasteFromClipboard,
    );
  }

  Widget _buildOptionsRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildLimitField(isDark)),
        const SizedBox(width: 6),
        Expanded(child: _buildLanguageDropdown(isDark)),
      ],
    );
  }

  Widget _buildLimitField(bool isDark) {
    return _buildTextField(
      controller: _limitController,
      label: 'Limit',
      hint: '100',
      icon: Icons.filter_list_rounded,
      iconColor: const Color(0xFF14B8A6),
      isDark: isDark,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onPaste,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: Icon(icon, color: iconColor, size: 16),
        suffixIcon: onPaste != null ? _buildPasteButton(onPaste) : null,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        border: _getTextFieldBorder(isDark, iconColor),
        enabledBorder: _getTextFieldBorder(isDark, iconColor),
        focusedBorder: _getFocusedBorder(iconColor),
      ),
    );
  }

  Widget _buildPasteButton(VoidCallback onPaste) {
    return IconButton(
      icon: const Icon(Icons.content_paste_rounded, size: 16),
      tooltip: 'Paste',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: _isLoading ? null : onPaste,
    );
  }

  OutlineInputBorder _getTextFieldBorder(bool isDark, Color iconColor) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  OutlineInputBorder _getFocusedBorder(Color iconColor) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: iconColor,
        width: 2,
      ),
    );
  }

  Widget _buildLanguageDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _language,
        decoration: const InputDecoration(
          labelText: 'Language',
          prefixIcon: Icon(
            Icons.translate_rounded,
            color: Color(0xFF10B981),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'ru', child: Text('Russian')),
          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
        ],
        onChanged: _isLoading
            ? null
            : (value) {
                if (value != null) {
                  setState(() => _language = value);
                }
              },
      ),
    );
  }

  Widget _buildSearchButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _runLookup,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Searching...' : 'Start Search',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    if (_errorMessage != null) {
      return _buildErrorCard(isDark);
    }

    if (_result == null) {
      return _buildEmptyState(isDark);
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: Column(
          children: [
            _buildResultStats(isDark),
            const SizedBox(height: 6),
            _buildResultCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStats(bool isDark) {
    final List<dynamic> data = _result?['Data'] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF059669).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          _buildSuccessIcon(),
          const SizedBox(width: 6),
          Expanded(child: _buildStatsText(data.length, isDark)),
          IconButton(
            icon: Icon(
              _showJson ? Icons.view_list_rounded : Icons.code_rounded,
              color: const Color(0xFF10B981),
            ),
            tooltip: _showJson ? 'Card View' : 'JSON View',
            onPressed: _toggleJsonView,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        size: 16,
      ),
    );
  }

  Widget _buildStatsText(int resultCount, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Search Complete',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$resultCount results found',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(8),
      decoration: _getResultCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHeader(isDark),
          const SizedBox(height: 8),
          if (_showJson) _buildJsonView(isDark) else _buildDataCards(isDark),
        ],
      ),
    );
  }

  BoxDecoration _getResultCardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withOpacity(0.7)
          : Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildResultHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.dataset_rounded, color: Color(0xFF10B981), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Results',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy_all_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          tooltip: 'Copy JSON',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _copyJsonToClipboard,
        ),
      ],
    );
  }

  Widget _buildJsonView(bool isDark) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: SelectableText(
            prettyJson,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCards(bool isDark) {
    final List<dynamic> data = _result?['Data'] ?? [];

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length > _maxDisplayItems ? _maxDisplayItems : data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _buildDataCard(data[index], index, isDark),
    );
  }

  Widget _buildDataCard(dynamic item, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataCardBadge(index),
          const SizedBox(height: 6),
          SelectableText(
            item.toString(),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCardBadge(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#${index + 1}',
        style: const TextStyle(
          color: Color(0xFF10B981),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(16),
          decoration: _getCardDecoration(isDark),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulsingIcon(),
              const SizedBox(height: 12),
              Text(
                'Ready to Search',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your query above and click\n"Start Search" to begin',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 10,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulsingIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981)
            .withOpacity(0.1 + (_pulseController.value * 0.1)),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.search_off_rounded,
        color: Color(0xFF10B981),
        size: 32,
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorIcon(),
          const SizedBox(height: 12),
          const Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 10,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error_outline_rounded,
        color: Colors.red,
        size: 32,
      ),
    );
  }
}