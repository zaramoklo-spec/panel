import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/sms_message.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/date_utils.dart' as utils;

class SmsDetailScreen extends StatelessWidget {
  final SmsMessage message;

  const SmsDetailScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messageColor =
    message.isInbox ? const Color(0xFF3B82F6) : const Color(0xFF10B981);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            child: PopupMenuButton(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.24),
              ),
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => [
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
                        'Copy Text',
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.body));
                    Future.delayed(const Duration(milliseconds: 100), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Text copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.68),
                          ),
                        ),
                      );
                    });
                  },
                ),
                if (message.from != null)
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
                    onTap: () => _makeCall(context, message.from!),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 60,
              20,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  messageColor.withOpacity(isDark ? 0.2 : 0.1),
                  messageColor.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [messageColor, messageColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(15.36),
                    boxShadow: [
                      BoxShadow(
                        color: messageColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    message.isInbox
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.8,
                    vertical: 6.4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [messageColor, messageColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(7.68),
                  ),
                  child: Text(
                    message.isInbox ? 'Received Message' : 'Sent Message',
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(15.36),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (message.from != null)
                          _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'From',
                            value: message.from!,
                            isDark: isDark,
                            trailing: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.phone_rounded,
                                  size: 14.4,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(6.4),
                                constraints: const BoxConstraints(),
                                onPressed: () => _makeCall(context, message.from!),
                              ),
                            ),
                          ),
                        if (message.from != null && message.to != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9.6),
                            child: Divider(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                        if (message.to != null)
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'To',
                            value: message.to!,
                            isDark: isDark,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9.6),
                          child: Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Date & Time',
                          value: utils.DateUtils.formatForDisplay(
                              message.timestamp),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(15.36),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 20,
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
                              padding: const EdgeInsets.all(6.4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    messageColor.withOpacity(0.2),
                                    messageColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6.4),
                              ),
                              child: Icon(
                                Icons.chat_bubble_rounded,
                                color: messageColor,
                                size: 14.4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          message.body,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.28,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF334155),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(10.24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: message.body));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Text copied'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7.68),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.content_copy_rounded,
                              size: 14.4,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Copy Text',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (message.from != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF059669)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10.24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _makeCall(context, message.from!),
                              icon: const Icon(
                                Icons.phone_rounded,
                                size: 14.4,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Call',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(7.68),
          ),
          child: Icon(
            icon,
            size: 14.4,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.6,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}