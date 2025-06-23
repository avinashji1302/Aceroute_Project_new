// utils/timezone_utils.dart
import 'package:intl/intl.dart';

class TimeZoneUtils {
  /// Converts UTC string like "2025/06/20 08:00 -00:00" to local DateTime.
  static DateTime parseUtcToLocal(String raw) {
    try {
      final parts = raw.split(' ');
      if (parts.length < 2) throw FormatException("Invalid format");

      final datePart = parts[0].replaceAll('/', '-');
      final timePart = parts[1];

      final timeSplit = timePart.split(':');
      final hour = timeSplit[0].padLeft(2, '0');
      final minute = timeSplit.length > 1 ? timeSplit[1].padLeft(2, '0') : '00';

      final isoString = '$datePart' + 'T$hour:$minute:00Z';
      return DateTime.parse(isoString).toLocal();
    } catch (e) {
      print("❌ parseUtcToLocal Error: $e | Raw: $raw");
      return DateTime.now(); // fallback
    }
  }

  /// Same as above, but returns formatted string: "yyyy-MM-dd HH:mm:ss"
  static String formatUtcToLocal(String raw) {
    final local = parseUtcToLocal(raw);
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(local);
  }

  /// Converts local DateTime to display string: "June 1:30 PM"
  static String formatReadable(DateTime date) {
    final month = DateFormat('MMMM').format(date); // June
    final time = DateFormat.jm().format(date);     // 1:30 PM
    return '$month $time';
  }
}
