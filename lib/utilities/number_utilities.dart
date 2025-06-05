import 'dart:math';

import 'package:intl/intl.dart';

extension NumberRoudning on double {
  /// Returns result rounded to 2 decimal places
  double roundToTwoPlaces() {
    return (this * 100.0).roundToDouble() / 100.0;
  }
}

/// Returns a string for a dollar [value] with or without a leading dollar sign.
/// * [value] - dollar value to show
/// * [showDollarSign] - indicates whether or not to show leading dollar sign (defaults to true)
/// * [showCents] - indicates whther cents should be shown ot not (defaults to false)
String showDollarString(double? value, {bool showDollarSign = true, bool showCents = false}) {
  if (value == null) return '';
  NumberFormat dollarFormat = NumberFormat.currency(
    locale: "en_US",
    symbol: showDollarSign ? '\$' : '',
    decimalDigits: showCents ? 2 : 0,
  );
  return dollarFormat.format(value);
}

/// Parses US currency value and returns the dollar value of the [text] string
double? parseDollarString(String? text) {
  if (text == null) return null;
  NumberFormat dollarFormat = NumberFormat.currency(
    locale: "en_US",
    symbol: '',
    decimalDigits: 0,
  );
  double? value = dollarFormat.tryParse(text) as double?;
  return value;
}

/// Returns a string for a percent [value] with or without a trailing percent sign.
/// * [value] - dollar value to show
/// * [showPercentSign] - indicates whether or not to show trailing percent sign (defaults to true)
String showPercentage(double? value, {bool showPercentSign = true}) {
  if (value == null) return '';
  NumberFormat percentFormat;
  if (showPercentSign) {
    percentFormat = NumberFormat.decimalPercentPattern(
      locale: "en_US",
      decimalDigits: 2,
    );
    return percentFormat.format(value);
  }
  percentFormat = NumberFormat.decimalPatternDigits(
    locale: "en_US",
    decimalDigits: 2,
  );
  return percentFormat.format(value * 100);
}

/// Parses percent value and returns the percentage value of the [text] string
double? parsePercentage(String? text) {
  if (text == null) return null;
  if (!text.endsWith('%')) {
    text = '$text%';
  }
  NumberFormat percentFormat =
      NumberFormat.decimalPatternDigits(locale: "en_US", decimalDigits: 2);
  return percentFormat.tryParse(text) as double?;
}



/// Managed cost of living increases.
class CostOfLiving {
  // Default COLA percentage. i.e., the average percent of value change in the dollar
  // over the last 30 years, i.e., between the year 1994 and 2024.
  static const double defaultColaPercent = 2.55244;
  // COLA percentage currently in affect.
  static double _colaPercent = defaultColaPercent;
  // COLA rate of increase currently in affect.
  static double _rateOfIncrease = 1.0 + defaultColaPercent / 100.0;

  /// Returns the COLA percentage currently in affect.
  static double get colaPercent => _colaPercent;

  /// Sets the COLA percentage currently in affect to the provided [newPercent].
  /// If [newPercent] is omitted, the [defaultColaPercent] is used.
  static void setColaPercent([double newPercent = defaultColaPercent]) {
    _colaPercent = newPercent;
    _rateOfIncrease = 1.0 + colaPercent / 100.0;
  }

  /// Returns a value adjusted for time value of money.
  /// Inputs:
  /// * [valueToAdjust] - amount to adjust.
  /// * [fromYear] - year to adjust from.
  /// * [toYear] - year to adjust to.
  /// * [rateOfIncrease] - The COLA rate (1 + percent/100) to use to use.
  /// If ommitted, the rate associated with classes [colaPercent] is used.
  static double adjustForTime(
      {required double valueToAdjust,
      required int toYear,
      required int fromYear,
      double? rateOfIncrease}) {
    double result;
    rateOfIncrease = rateOfIncrease ?? _rateOfIncrease;
    if (fromYear == toYear) {
      result = valueToAdjust;
    } else {
      result =
          valueToAdjust * (pow(rateOfIncrease, toYear - fromYear) as double);
    }
    return result.roundToTwoPlaces();
  }
}

// Average rate of value change in the dollar over the last 30 years.
// I.e., between rghe year 1994 and 2024
//const double _rateOfIncrease = 1.0255244;

/// Returns a value adjusted for time value of money.
/// Inputs:
/// * [valueToAdjust] - amount to adjust.
/// * [fromYear] - year to adjust from.
/// * [toYear] - year to adjust to.
/// * [percent] - The COLA percent to use.  If ommitted, the classes [colaPercent] is used.
double adjustForTime(
    {required double valueToAdjust,
    required int toYear,
    required int fromYear,
    double? rateOfIncrease}) {
  return CostOfLiving.adjustForTime(
    valueToAdjust: valueToAdjust,
    toYear: toYear,
    fromYear: fromYear,
    rateOfIncrease: rateOfIncrease,
  );
}
