import 'package:intl/intl.dart';

/// Date and time formatting utilities for consistent display across the app.
class DateFormatter {
  DateFormatter._();

  /// Formats a timestamp for chat message display.
  /// - Today: "2:30 PM"
  /// - This week: "Mon"
  /// - This year: "Mar 15"
  /// - Older: "03/15/24"
  static String chatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat.jm().format(dateTime); // 2:30 PM
    }

    final weekAgo = today.subtract(const Duration(days: 7));
    if (messageDate.isAfter(weekAgo)) {
      return DateFormat.E().format(dateTime); // Mon
    }

    if (dateTime.year == now.year) {
      return DateFormat.MMMd().format(dateTime); // Mar 15
    }

    return DateFormat.yMd().format(dateTime); // 03/15/24
  }

  /// Formats a timestamp for message detail view.
  /// Returns "2:30 PM" format.
  static String messageTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Formats "last seen" status for user profiles.
  /// - Online now: "online"
  /// - Today: "last seen today at 2:30 PM"
  /// - Yesterday: "last seen yesterday at 2:30 PM"
  /// - Older: "last seen Mar 15 at 2:30 PM"
  static String lastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'offline';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 2) return 'online';

    final today = DateTime(now.year, now.month, now.day);
    final seenDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat.jm().format(dateTime);

    if (seenDate == today) return 'last seen today at $time';

    final yesterday = today.subtract(const Duration(days: 1));
    if (seenDate == yesterday) return 'last seen yesterday at $time';

    final date = DateFormat.MMMd().format(dateTime);
    return 'last seen $date at $time';
  }

  /// Formats call duration as "MM:SS" or "H:MM:SS".
  static String callDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats file size for display (KB, MB, GB).
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
