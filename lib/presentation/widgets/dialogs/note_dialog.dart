import 'package:flutter/material.dart';

class NoteDialog extends StatefulWidget {
  final String? initialMessage;
  final String? initialPriority;

  const NoteDialog({
    super.key,
    this.initialMessage,
    this.initialPriority,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _messageController;
  late String _selectedPriority;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
    _selectedPriority = widget.initialPriority ?? 'none';
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(6.4),
            ),
            child: const Icon(Icons.note_add_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text('Send Note'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PriorityChip(
                    label: 'None',
                    value: 'none',
                    selected: _selectedPriority == 'none',
                    color: Colors.grey,
                    onTap: () => setState(() => _selectedPriority = 'none'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityChip(
                    label: 'Low',
                    value: 'lowbalance',
                    selected: _selectedPriority == 'lowbalance',
                    color: const Color(0xFFF59E0B),
                    onTap: () => setState(() => _selectedPriority = 'lowbalance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _PriorityChip(
                label: 'High',
                value: 'highbalance',
                selected: _selectedPriority == 'highbalance',
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _selectedPriority = 'highbalance'),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Message',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your note message...',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5CF6),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _messageController.text.trim().isEmpty
              ? null
              : () {
            Navigator.pop(context, {
              'priority': _selectedPriority,
              'message': _messageController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: color,
                ),
              if (selected) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? color
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}