/// Tools for dealing with date and time objects in the app and the Philips Hue
/// system.
class DateTimeTool {
  /// Converts the given `dateTime` to a string that the Hue bridge can
  /// understand.
  static String toHueString(DateTime dateTime) {
    String dateTimeStr = dateTime.toIso8601String();
    return dateTimeStr.substring(0, dateTimeStr.indexOf('.'));
  }

  /// Returns a [DateTime] with the date of the original, but time set to
  /// midnight.
  static DateTime dateOnly(DateTime date) {
    final DateTime now = DateTime.now();

    return DateTime.utc(now.year, now.month, now.day);
  }
}
