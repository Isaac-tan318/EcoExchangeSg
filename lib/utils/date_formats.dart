import 'package:intl/intl.dart';

class DateFormats {
  static String monthWord(DateTime dt, {String? locale}) =>
      DateFormat.MMMM(locale).format(dt); // e.g., August

  static String dMonthY(DateTime dt, {String? locale}) =>
      DateFormat('d MMMM yyyy', locale).format(dt); // 10 August 2025

  static String dMonthYHm(DateTime dt, {String? locale}) =>
      DateFormat('d MMMM yyyy HH:mm', locale).format(dt); // 10 August 2025 14:30
}
