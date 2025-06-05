import 'dart:math';

import 'package:roth_analysis/utilities/number_utilities.dart';

import 'analysis_exceptions.dart';

/// Class manages a 12 month plan for a given yearly amount.
/// Inital plan is 11 equal instalments with the 12th installment acounting for rounding issues.\
/// Allows for on-going month adjustments via [updateMonthlyAmount].
/// Allows for on-going yearly adjustement via [updateYearlyAmount].
/// Notes:
///   * All values in the plan are rounded to two decimal places
///   * Can be used for either a payment plan or a distribution plan.
class MonthlyPlan {
  double _yearlyAmount = 0;
  int _beginMonth = 1;
  int _finalMonth = 12;
  final List<double> _monthlyAmounts = List.filled(12, 0.0);

  void _assertIsValidMonthNumber(int month) {
    if (month < 1 || month > 12) {
      throw (InvalidMonthNumberException(month));
    }
  }

  /// Returns true if [month] is within the valid payment plan months as established in [initialize] method.
  bool _isMonthInPlanRange(int month) =>
      (month >= _beginMonth && month <= _finalMonth);

  void _assertValidYearlyAmount(double yearlyAmount) {
    if (yearlyAmount < 0.0) {
      throw InvalidYearlyAmount(yearlyAmount);
    }
  }

  /// Returns the list index for the specified [month]
  /// Throws an exception if the [month] is out-of-range.
  int index(int month) {
    _assertIsValidMonthNumber(month);
    return month - 1;
  }

  /// Returns the as configured and maintained yearly amount.
  double get yearlyAmount => _yearlyAmount;

  /// Returns the as-configured beginning month.
  int get beginMonth => _beginMonth;

  /// Returns the as-configured beginning index.
  int get beginIndex => _beginMonth - 1;

  /// Returns the as-configured final month.
  int get finalMonth => _finalMonth;

  /// Returns the as-configured final index.
  int get finalIndex => _finalMonth - 1;

  /// Returns the total number of months in the plan.
  int get numberOfMonths => _finalMonth - _beginMonth + 1;

  /// Returns the balance from the specified [month] to the end of the year
  /// Throws an exception if the [month] is not a valid month number.
  double remainingBalance(int month) {
    int index = this.index(month);
    if (index == 0) {
      return yearlyAmount;
    }
    double balance = 0;
    for (; index <= finalIndex; index++) {
      if (index >= beginIndex) {
        balance += _monthlyAmounts[index];
      }
    }
    return balance;
  }

  /// Returns the plan's amount for the specified [month]
  /// Throws an exception if the [month] is not a valid month number.
  double getMonthlyAmount(int month) => _monthlyAmounts[index(month)];

  /// Initialize with the specified [yearlyAmount], [beginMonth], [finalMonth]
  /// * If [adjustForFractionalYear] is true, [yearlyAmount] will be adjusted based on the
  /// number of months in the plan, and then distributed to the active months.
  /// * If [adjustForFractionalYear] is false, [yearlyAmount] is not adjusted 
  /// and the full [yearlyAmount] is distributed to the active months.

  /// Throws an exception if
  /// * The [month] is not a valid month number.
  /// * Or if, [beginMonth] is greater than [finalMonth]
  void initialize(double yearlyAmount,
      {int beginMonth = 1,
      int finalMonth = 12,
      bool adjustForFractionalYear = true}) {
    int beginIndex = index(beginMonth);
    int finalIndex = index(finalMonth);
    if (beginMonth > finalMonth) {
      throw (InvalidMonthRangeException(beginMonth, finalMonth));
    }
    _assertValidYearlyAmount(yearlyAmount);

    _beginMonth = beginMonth;
    _finalMonth = finalMonth;
    // Adjust yearly amount based on the number of months in the plan.
    if (adjustForFractionalYear) {
      yearlyAmount *= numberOfMonths / 12;
    }
    double baseAmount = (yearlyAmount / numberOfMonths).roundToTwoPlaces();
    double runningTotal = 0.0;
    for (int i = 0; i < 12; i++) {
      double thisMonthsAmount;
      if (i < beginIndex || i > finalIndex) {
        thisMonthsAmount = 0.0;
      } else if (i == finalIndex) {
        thisMonthsAmount = (yearlyAmount - runningTotal).roundToTwoPlaces();
      } else {
        thisMonthsAmount = baseAmount;
      }
      _monthlyAmounts[i] = thisMonthsAmount;
      runningTotal += thisMonthsAmount;
    }
    _yearlyAmount = runningTotal;
    _beginMonth = beginMonth;
    _finalMonth = finalMonth;
  }

  /// Updates the monthly amount for the specified [month].
  /// * Adjusting the next months amount to maintain the [yearlyAmount].
  /// * Unless this is the last month of the plan, where the [yearlyAmount] itself gets adjusted.
  /// * No adjustements are made if the specified month is outside the valid plan months
  /// as established in the initialize() method.
  /// Throws an exception if
  /// * The [month] is out-of-range.
  /// * The [month] is not within the begin and final plan months
  /// * The [newAmount]  is negative.
  void updateMonthlyAmount(int month, double newAmount) {
    final int index = this.index(month);
    if (!_isMonthInPlanRange(month)) {
      return;
    }
    if (newAmount < 0.0) {
      throw (InvalidMonthlyAmount(newAmount));
    }

    // delta will be the amount that must be subtracted from the new monthlyAmount to get the previous monthlyAmount
    // conversely, the amount that must be added to the previous monthlyAmount to get the new monthlyAmount
    double delta = _monthlyAmounts[index] - newAmount;
    _monthlyAmounts[index] = newAmount;

    int numRemainingMonths = finalMonth - month;
    double monthlyDelta = 0.0;
    double lastMonthsDelta = delta;
    if (numRemainingMonths != 0) {
      monthlyDelta = (delta / numRemainingMonths).roundToTwoPlaces();
      lastMonthsDelta = delta - monthlyDelta * (numRemainingMonths - 1);
    }

    for (int i = index + 1; i < finalIndex; i++) {
      double newMonthlyAmount = _monthlyAmounts[i] + monthlyDelta;
      if (newMonthlyAmount >= 0.0) {
        _monthlyAmounts[i] = newMonthlyAmount;
      } else {
        _monthlyAmounts[i] = 0.0;
        lastMonthsDelta += newMonthlyAmount;
      }
    }
    double newMonthlyAmount = _monthlyAmounts[finalIndex] + lastMonthsDelta;
    if (newMonthlyAmount >= 0.0) {
      _monthlyAmounts[finalIndex] = newMonthlyAmount;
    } else {
      _monthlyAmounts[finalIndex] = 0.0;
      _yearlyAmount -= newMonthlyAmount;
    }
  }

  /// Updates the plans yearly amount to [newYearlyAmount]
  /// and correpsondingly updates the remaing monthly amounts to match.
  /// [month] - The start month for which the yearly plan is being updated.
  /// Monthly amounts ealier than [month] are considered realized / final.
  /// If [month] is omitted, it defaults to 1 and the entire monthly plan is updated.
  /// * No adjustements are made ifthe specified month is outside the valid plan months
  /// as established in the initialize() method.
  /// Throws an exception if the [month] is out-of-range.
  void updateYearlyAmount(double newYearlyAmount, {int month = 1}) {
    // Convert month number to month index which checks to see if month is between 1 and 12.
    // Also check to see if is within the configured begin and end months.
    int index = this.index(month);
    if (!_isMonthInPlanRange(month)) {
      return;
    }
    newYearlyAmount = newYearlyAmount.roundToTwoPlaces();
    // Shortcut the process if the new yearly amount matches the objects yearly amount.
    if (newYearlyAmount == yearlyAmount) {
      return;
    }
    // Sub-list of all of the months that have realized/actual values.
    final List<double> realizedMonths =
        _monthlyAmounts.sublist(beginIndex, index);
    // Yearly amount that has been realized.
    final double realizedYearlyAmount =
        realizedMonths.fold<double>(0.0, (value, element) => value + element);
    // Yearly amount that has yet to be realized (based on newYearlyAmount)
    final double unrealizedYearlyAmount =
        max(0.0, newYearlyAmount - realizedYearlyAmount);
    // The number of months that have been unrealized and therefore require update.
    final int unrealizedNumberOfMonths = finalIndex - index + 1;
    // Monthy amount that must be realized per month for remaining months.
    double newMonthlyAmount =
        (unrealizedYearlyAmount / unrealizedNumberOfMonths).roundToTwoPlaces();
    double runningTotal = realizedYearlyAmount;
    for (; index <= finalIndex; index++) {
      if (index == finalIndex) {
        // adjustment for the final month as it may be slightly different due to rounding.
        newMonthlyAmount =
            max(0.0, newYearlyAmount - runningTotal).roundToTwoPlaces();
      }
      _monthlyAmounts[index] = newMonthlyAmount;
      runningTotal += newMonthlyAmount;
    }
    _yearlyAmount = runningTotal;
  }

  /// Returns the cumulative monthly amounts that occur before [month].
  double accruedAmount(int month) {
    double amount = 0.0;
    for (int index = this.index(month) - 1; index >= 0; index--) {
      amount += _monthlyAmounts[index];
    }
    return amount;
  }
}
