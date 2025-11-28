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

class _LeakLookupScreenState extends State<LeakLookupScreen> {
  final ToolsRepository _repository = ToolsRepository();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(text: '100');

  bool _isLoading = false;
  String _language = 'en';
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _queryController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _runLookup() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number or query')),
      );
      return;
    }

    int limit = int.tryParse(_limitController.text.trim()) ?? 100;
    limit = limit.clamp(1, 10000);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0B0F19), const Color(0xFF1A1F2E)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Leak Lookup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                      tooltip: 'Clear form',
                      onPressed: _isLoading
                          ? null
                          : () {
                              _queryController.clear();
                              _limitController.text = '100';
                              setState(() {
                                _result = null;
                                _errorMessage = null;
                              });
                            },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.phone_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Search Query',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _queryController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Phone number or query',
                                hintText: '+919876543210',
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF59E0B)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.paste_rounded),
                                  tooltip: 'Paste from clipboard',
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                                          if (data?.text != null) {
                                            _queryController.text = data!.text!;
                                          }
                                        },
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF59E0B),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _limitController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      labelText: 'Limit',
                                      hintText: '100',
                                      prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF3B82F6)),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF3B82F6),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _language,
                                    style: const TextStyle(fontSize: 15),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'en',
                                        child: Row(
                                          children: [
                                            Icon(Icons.language_rounded, size: 18, color: Color(0xFF10B981)),
                                            SizedBox(width: 8),
                                            Text('English'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ru',
                                        child: Row(
                                          children: [
                                            Icon(Icons.language_rounded, size: 18, color: Color(0xFF10B981)),
                                            SizedBox(width: 8),
                                            Text('Russian'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'hi',
                                        child: Row(
                                          children: [
                                            Icon(Icons.language_rounded, size: 18, color: Color(0xFF10B981)),
                                            SizedBox(width: 8),
                                            Text('Hindi'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              setState(() {
                                                _language = value;
                                              });
                                            }
                                          },
                                    decoration: InputDecoration(
                                      labelText: 'Language',
                                      prefixIcon: const Icon(Icons.language_rounded, color: Color(0xFF10B981)),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF10B981),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _runLookup,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_isLoading)
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.search_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isLoading ? 'Looking up...' : 'Start Lookup',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
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
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildResultView(isDark),
                      ),
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

  Widget _buildResultView(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.redAccent.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFF59E0B),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a query and click "Start Lookup" to search',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy JSON',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: prettyJson));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: SelectableText(
                  prettyJson,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

