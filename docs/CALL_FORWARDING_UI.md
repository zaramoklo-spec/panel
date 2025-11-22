# 📞 Call Forwarding UI Guide

این مستند راهنمای استفاده از رابط کاربری Call Forwarding در Flutter App است.

## 📋 فهرست مطالب
- [معرفی](#معرفی)
- [فایل‌های ایجاد شده](#فایلهای-ایجاد-شده)
- [نحوه استفاده](#نحوه-استفاده)
- [ویژگی‌ها](#ویژگیها)
- [مثال‌های کد](#مثالهای-کد)
- [عیب‌یابی](#عیبیابی)

---

## معرفی

قابلیت **Call Forwarding UI** به ادمین‌ها اجازه می‌دهد که از طریق رابط گرافیکی، Call Forwarding رو روی دستگاه‌ها فعال یا غیرفعال کنند.

### ✨ قابلیت‌ها
- ✅ Dialog زیبا و کاربرپسند برای تنظیم Call Forwarding
- ✅ Validation شماره تلفن (فرمت بین‌المللی)
- ✅ انتخاب SIM Slot با نمایش اطلاعات کامل SIM کارت‌ها
- ✅ فعال‌سازی و غیرفعال‌سازی Call Forwarding
- ✅ نمایش وضعیت فعلی Call Forwarding در Device Info Tab
- ✅ دکمه "Manage" برای دسترسی سریع
- ✅ Feedback کامل به کاربر (Success/Error SnackBars)

---

## فایل‌های ایجاد شده

### 1. Dialog Widget
```
lib/presentation/widgets/dialogs/call_forwarding_dialog.dart
```

**کامپوننت‌های اصلی:**
- `CallForwardingDialog` - Dialog اصلی
- `_ActionChip` - دکمه Enable/Disable
- `_SimSlotChip` - انتخاب SIM Slot (حالت ساده)

### 2. Integration در Device Info Tab
فایل آپدیت شده:
```
lib/presentation/screens/devices/tabs/device_info_tab.dart
```

**تغییرات:**
- اضافه شدن متد `_handleCallForwarding()`
- اضافه شدن دکمه "Manage" در Call Forwarding Card
- نمایش بهتر وضعیت Call Forwarding

---

## نحوه استفاده

### 1️⃣ دسترسی به Call Forwarding

**مسیر:** Device Detail Screen → Info Tab → Call Forwarding Card

### 2️⃣ فعال‌سازی Call Forwarding

1. روی دکمه **"Manage"** در Call Forwarding Card کلیک کنید
2. گزینه **"Enable"** را انتخاب کنید
3. شماره هدایت را وارد کنید (مثال: `+989123456789`)
4. SIM Slot مورد نظر را انتخاب کنید
5. روی دکمه **"Enable"** کلیک کنید

### 3️⃣ غیرفعال‌سازی Call Forwarding

1. روی دکمه **"Manage"** کلیک کنید
2. گزینه **"Disable"** را انتخاب کنید
3. SIM Slot را انتخاب کنید
4. روی دکمه **"Disable"** کلیک کنید

---

## ویژگی‌ها

### 📱 Validation شماره تلفن

Dialog شماره تلفن را اعتبارسنجی می‌کنه:

```dart
// فرمت صحیح
+989123456789  ✅
+1234567890    ✅

// فرمت نادرست
09123456789    ❌ (باید با + شروع شه)
989123456789   ❌ (نیاز به + داره)
abc123         ❌ (فقط اعداد و +)
```

### 🎨 UI Components

#### نمایش وضعیت SIM کارت‌ها

اگر دستگاه اطلاعات SIM کارت داره، Dialog به صورت زیر نمایش میده:

```
┌─────────────────────────────┐
│  📱 SIM 1                    │
│  Irancell                    │
│  ✓                           │
└─────────────────────────────┘
┌─────────────────────────────┐
│  📱 SIM 2                    │
│  MCI                         │
└─────────────────────────────┘
```

#### نمایش وضعیت فعلی

اگر Call Forwarding فعال باشه:

```
┌─────────────────────────────┐
│  ℹ️ Currently forwarding to:  │
│  +989123456789               │
└─────────────────────────────┘
```

### 🔄 Feedback به کاربر

#### موفقیت‌آمیز (Success)
```
✅ Call forwarding command sent!
```

#### خطا (Error)
```
❌ Failed to send command
❌ Error: [error message]
```

---

## مثال‌های کد

### استفاده مستقیم از Dialog

```dart
import 'package:flutter/material.dart';
import '../widgets/dialogs/call_forwarding_dialog.dart';

// نمایش Dialog
final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => CallForwardingDialog(device: myDevice),
);

// پردازش نتیجه
if (result != null) {
  final action = result['action']; // 'enable' یا 'disable'
  
  if (action == 'enable') {
    final number = result['number'];    // شماره هدایت
    final simSlot = result['simSlot'];  // 0 یا 1
    
    // ارسال Command
    await deviceProvider.sendCommand(
      deviceId,
      'call_forwarding',
      parameters: {
        'number': number,
        'simSlot': simSlot,
      },
    );
  } else if (action == 'disable') {
    final simSlot = result['simSlot'];
    
    // غیرفعال‌سازی
    await deviceProvider.sendCommand(
      deviceId,
      'call_forwarding_disable',
      parameters: {
        'simSlot': simSlot,
      },
    );
  }
}
```

### نمایش وضعیت در UI

```dart
// چک کردن وضعیت Call Forwarding
if (device.callForwardingEnabled == true) {
  print('✅ Call Forwarding فعال است');
  print('📞 شماره: ${device.callForwardingNumber}');
  print('📱 SIM Slot: ${device.callForwardingSimSlot}');
  print('🕐 آخرین آپدیت: ${device.callForwardingUpdatedAt}');
} else {
  print('❌ Call Forwarding غیرفعال است');
}
```

---

## عیب‌یابی (Troubleshooting)

### مشکل: Dialog باز نمی‌شه

**علت‌های احتمالی:**
- Context اشتباه
- Device object null است

**راه حل:**
```dart
// اطمینان از وجود Context
if (!mounted) return;

// اطمینان از وجود Device
if (device == null) {
  print('❌ Device is null');
  return;
}

// نمایش Dialog
showDialog(context: context, builder: (_) => CallForwardingDialog(device: device));
```

---

### مشکل: Validation ارور می‌ده

**علت‌های احتمالی:**
- شماره با + شروع نمی‌شه
- شماره خیلی کوتاهه
- شماره شامل حروف هست

**راه حل:**
```dart
// فرمت صحیح:
final correctNumber = '+989123456789';

// حذف فاصله‌ها و کاراکترهای اضافی
final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
```

---

### مشکل: Command ارسال نمی‌شه

**علت‌های احتمالی:**
- دستگاه آفلاین است
- دستگاه FCM token نداره
- خطای شبکه

**راه حل:**
```dart
// چک کردن آنلاین بودن دستگاه
if (!device.isOnline) {
  print('❌ Device is offline');
  return;
}

// چک کردن FCM tokens
if (device.fcmTokens == null || device.fcmTokens!.isEmpty) {
  print('❌ Device has no FCM tokens');
  return;
}

// ارسال Command با Error Handling
try {
  final success = await deviceProvider.sendCommand(...);
  if (success) {
    print('✅ Command sent successfully');
  } else {
    print('❌ Command failed');
  }
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 🎯 Best Practices

### 1. همیشه Validation کنید
```dart
// قبل از ارسال، شماره رو Validate کنید
if (!_formKey.currentState!.validate()) {
  return;
}
```

### 2. Feedback مناسب بدید
```dart
// موفقیت
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('✅ Command sent!'),
    backgroundColor: Colors.green,
  ),
);

// خطا
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('❌ Error: ${error}'),
    backgroundColor: Colors.red,
  ),
);
```

### 3. رفرش کنید بعد از موفقیت
```dart
if (success) {
  // نمایش پیام موفقیت
  showSuccessSnackBar();
  
  // رفرش اطلاعات دستگاه بعد از 2 ثانیه
  await Future.delayed(Duration(seconds: 2));
  await refreshDeviceInfo();
}
```

---

## 📊 UI Screenshots

### Dialog در حالت Enable
```
┌─────────────────────────────────┐
│  📞 Call Forwarding             │
├─────────────────────────────────┤
│  Action:                        │
│  ┌─────────┐ ┌─────────┐       │
│  │ Enable  │ │ Disable │       │
│  └─────────┘ └─────────┘       │
│                                 │
│  Forward to Number:             │
│  ┌─────────────────────────┐   │
│  │ +989123456789           │   │
│  └─────────────────────────┘   │
│                                 │
│  💡 Use international format    │
│                                 │
│  SIM Slot:                      │
│  ┌─────────────────────────┐   │
│  │ 📱 SIM 1 - Irancell ✓   │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 📱 SIM 2 - MCI          │   │
│  └─────────────────────────┘   │
│                                 │
│  [Cancel]        [Enable]       │
└─────────────────────────────────┘
```

### Call Forwarding Card در Device Info

```
┌─────────────────────────────────┐
│  📞 Call Forwarding    [Manage] │
├─────────────────────────────────┤
│  ✓ Status: Enabled              │
│  📞 Forward Number:              │
│     +989123456789               │
│  📱 SIM Slot: SIM 1             │
│  🕐 Last Updated: 2 mins ago    │
└─────────────────────────────────┘
```

---

## 🔗 مستندات مرتبط

- [Backend API Documentation](./CALL_FORWARDING.md)
- [Device Model](../lib/data/models/device.dart)
- [Device Provider](../lib/presentation/providers/device_provider.dart)

---

**آخرین بروزرسانی:** 2025-11-10  
**نسخه:** 1.0.0  
**توسعه‌دهنده:** Flutter Team
