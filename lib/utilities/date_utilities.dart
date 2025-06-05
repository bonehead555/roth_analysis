 
import 'package:intl/intl.dart';

/// Returns a formatted string of the form 'yyyy-MM-dd' for the specified [dateTime].
/// When [dateTime] is null, an empty string is returned.
String dateToString(DateTime? dateTime) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    return dateTime == null ? '' : dateFormat.format(dateTime);
  }

/// Returns a [DateTime] object pased from [text].
/// When the [text] cannot be parsed into a [DateTime], null is returned.
DateTime? dateFromString(String? text) {
  if (text == null) return null;
  return DateTime.tryParse(text);
}

final NumberFormat _year = NumberFormat("0000", "en_US");
final NumberFormat _month = NumberFormat("00", "en_US");

/// Returns a format date string of the form yyyy/mm based on [year] and [month]
String showYyyyMm(int year, int month) {
  String yearText = _year.format(year);
  String monthText = _month.format(month);
  return '$yearText/$monthText';
}

/// Returns a format date string of the form yyyy/mm based on [year] and [month]
String showYyyy(int year) {
  return _year.format(year);
}