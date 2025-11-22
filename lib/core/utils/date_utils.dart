import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateUtils {
  /// ????? ????? ?? local timezone
  static DateTime _toLocal(DateTime date) {
    if (date.isUtc) {
      return date.toLocal();
    }
    return date;
  }

  /// Format ???? ????? ?? ???? ??????
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd HH:mm'}) {
    final localDate = _toLocal(date);
    return DateFormat(format).format(localDate);
  }

  /// ?????? ???? ????? ?? ??????? ?? timeago package
  static String timeAgo(DateTime date) {
    final localDate = _toLocal(date);
    return timeago.format(localDate, locale: 'en');
  }

  /// ?????? ???? ????? ?? ??????? (????)
  static String timeAgoEn(DateTime date) {
    // ????? ?? local time
    final localDate = _toLocal(date);
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.isNegative) {
      return 'Just now'; // ????? ?????!
    }

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// ????? ????? ???? UI (Today, Yesterday, ?? ????? ????)
  static String formatForDisplay(DateTime date) {
    // ????? ?? local time
    final localDate = _toLocal(date);
    final now = DateTime.now();
    
    // ??? ????? (???? ????) ???? ??????
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(localDate.year, localDate.month, localDate.day);

    if (dateToCheck == today) {
      return 'Today ${DateFormat('HH:mm').format(localDate)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(localDate)}';
    } else if (now.difference(localDate).inDays < 7) {
      // ??? ???? ?? ?? ????: ????? ??? ????
      return DateFormat('EEEE HH:mm').format(localDate);
    } else {
      return DateFormat('yyyy/MM/dd HH:mm').format(localDate);
    }
  }

  /// ?? ???? ????? ????? ????? ??? ?? ??
  static bool isToday(DateTime date) {
    final localDate = _toLocal(date);
    final now = DateTime.now();
    return localDate.year == now.year && 
           localDate.month == now.month && 
           localDate.day == now.day;
  }

  /// ?? ???? ????? ????? ????? ??? ?? ??
  static bool isYesterday(DateTime date) {
    final localDate = _toLocal(date);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return localDate.year == yesterday.year &&
           localDate.month == yesterday.month &&
           localDate.day == yesterday.day;
  }
}