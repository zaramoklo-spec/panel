import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/device.dart';

/// 📞 Call Forwarding Dialog Widget
/// 
/// این Dialog برای تنظیم و مدیریت Call Forwarding استفاده میشه
/// 
/// Features:
/// - Enable/Disable Call Forwarding
/// - انتخاب شماره هدایت
/// - انتخاب SIM Slot (0 یا 1)
/// - Validation شماره تلفن
class CallForwardingDialog extends StatefulWidget {
  final Device device;

  const CallForwardingDialog({
    super.key,
    required this.device,
  });

  @override
  State<CallForwardingDialog> createState() => _CallForwardingDialogState();
}

class _CallForwardingDialogState extends State<CallForwardingDialog> {
  late final TextEditingController _numberController;
  late int _selectedSimSlot;
  late bool _isEnabled;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // مقداردهی اولیه با اطلاعات فعلی دستگاه
    _numberController = TextEditingController(
      text: widget.device.callForwardingNumber ?? '',
    );
    _selectedSimSlot = widget.device.callForwardingSimSlot ?? 0;
    _isEnabled = widget.device.callForwardingEnabled ?? false;

    _numberController.addListener(() {
      setState(() {}); // برای بروزرسانی دکمه‌ها
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (!_isEnabled) return null; // اگر غیرفعال است، نیازی به اعتبارسنجی نیست
    
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    // حذف فاصله‌ها و کاراکترهای اضافی
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // چک کردن فرمت بین‌المللی (+98...)
    if (!cleanNumber.startsWith('+')) {
      return 'Number must start with country code (e.g., +98...)';
    }

    // چک کردن اینکه فقط شامل اعداد و + باشد
    if (!RegExp(r'^\+[0-9]+$').hasMatch(cleanNumber)) {
      return 'Invalid phone number format';
    }

    // حداقل 10 رقم (بدون +)
    if (cleanNumber.length < 11) {
      return 'Number is too short';
    }

    return null;
  }

  void _handleEnable() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cleanNumber = _numberController.text.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    Navigator.pop(context, {
      'action': 'enable',
      'number': cleanNumber,
      'simSlot': _selectedSimSlot,
    });
  }

  void _handleDisable() {
    Navigator.pop(context, {
      'action': 'disable',
      'simSlot': _selectedSimSlot,
    });
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
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(6.4),
            ),
            child: const Icon(Icons.phone_forwarded_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text('Call Forwarding'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // وضعیت فعلی
              if (widget.device.callForwardingEnabled == true)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently forwarding to: ${widget.device.callForwardingNumber ?? "Unknown"}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.device.callForwardingEnabled == true) const SizedBox(height: 16),

              // Enable/Disable Toggle
              Text(
                'Action',
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
                    child: _ActionChip(
                      label: 'Enable',
                      icon: Icons.toggle_on_rounded,
                      selected: _isEnabled,
                      color: const Color(0xFF10B981),
                      onTap: () => setState(() => _isEnabled = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionChip(
                      label: 'Disable',
                      icon: Icons.toggle_off_rounded,
                      selected: !_isEnabled,
                      color: const Color(0xFFEF4444),
                      onTap: () => setState(() => _isEnabled = false),
                    ),
                  ),
                ],
              ),

              if (_isEnabled) ...[
                const SizedBox(height: 16),

                // Phone Number Input
                Text(
                  'Forward to Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
                  decoration: InputDecoration(
                    hintText: '+989123456789',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.phone_rounded, size: 16),
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
                        color: Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),

                // نکته مهم
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Use international format with country code (e.g., +98...)',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(0xFF3B82F6),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // SIM Slot Selection
              Text(
                'SIM Slot',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              
              // نمایش اطلاعات SIM کارت‌های موجود
              if (widget.device.simInfo != null && widget.device.simInfo!.isNotEmpty) ...[
                ...widget.device.simInfo!.map((sim) {
                  final isSelected = _selectedSimSlot == sim.simSlot;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _selectedSimSlot = sim.simSlot),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withOpacity(0.15)
                                : (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.02)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (isSelected ? const Color(0xFF6366F1) : Colors.grey)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.sim_card_rounded,
                                  size: 14,
                                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SIM ${sim.simSlot + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sim.carrierName.isNotEmpty
                                          ? sim.carrierName
                                          : 'Unknown Carrier',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ] else ...[
                // اگر اطلاعات SIM نداریم، دکمه‌های ساده نشون بده
                Row(
                  children: [
                    Expanded(
                      child: _SimSlotChip(
                        label: 'SIM 1',
                        slot: 0,
                        selected: _selectedSimSlot == 0,
                        onTap: () => setState(() => _selectedSimSlot = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SimSlotChip(
                        label: 'SIM 2',
                        slot: 1,
                        selected: _selectedSimSlot == 1,
                        onTap: () => setState(() => _selectedSimSlot = 1),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_isEnabled)
          ElevatedButton.icon(
            onPressed: _numberController.text.trim().isEmpty ? null : _handleEnable,
            icon: const Icon(Icons.check_rounded, size: 14),
            label: const Text('Enable'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _handleDisable,
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Disable'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

/// Action Chip Widget (Enable/Disable)
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
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
              Icon(
                icon,
                size: 16,
                color: selected ? color : Colors.grey,
              ),
              const SizedBox(width: 6),
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

/// SIM Slot Chip Widget (Simple version when no SIM info)
class _SimSlotChip extends StatelessWidget {
  final String label;
  final int slot;
  final bool selected;
  final VoidCallback onTap;

  const _SimSlotChip({
    required this.label,
    required this.slot,
    required this.selected,
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
                ? const Color(0xFF6366F1).withOpacity(0.15)
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6366F1)
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
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF6366F1),
                ),
              if (selected) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF6366F1)
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
