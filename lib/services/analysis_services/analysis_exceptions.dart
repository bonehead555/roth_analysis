
class MonthlyPlanException implements Exception {}

class InvalidMonthNumberException extends MonthlyPlanException {
  final int invalidMonth;
  final int beginMonth;
  final int finalMonth;
  InvalidMonthNumberException(this.invalidMonth,
      [this.beginMonth = 1, this.finalMonth = 12]);
  @override
  String toString() =>
      'InvalidMonthNumber: $invalidMonth is either less than beginMonth ($beginMonth) or greater than finalMonth ($finalMonth).';
}

class InvalidMonthRangeException extends MonthlyPlanException {
  final int beginMonth;
  final int finalMonth;
  InvalidMonthRangeException(this.beginMonth, this.finalMonth);
  @override
  String toString() =>
      'InvalidMonthRange: beginMonth ($beginMonth) > finalMonth ($finalMonth).';
}

class InvalidMonthlyAmount extends MonthlyPlanException {
  final double newAmount;
  InvalidMonthlyAmount(this.newAmount);
  @override
  String toString() =>
      'InvalidMonthAmount: New monthly amount (\$$newAmount) cannot be negative.';
}

class InvalidYearlyAmount extends MonthlyPlanException {
  final double newAmount;
  InvalidYearlyAmount(this.newAmount);
  @override
  String toString() =>
      'InvalidYearlyAmount: New Yearly amount (\$$newAmount) cannot be negative.';
}

class AccountAnalysisException implements Exception {}

class InsufficentAccountAssetException extends AccountAnalysisException {
  final String message;
  final int monthWhereFundsExausted;
  InsufficentAccountAssetException(this.message, this.monthWhereFundsExausted);
  @override
  String toString() => 'InsufficeintAccountAssets: $message.';
}


class EmptyAccountAnalysisStackException extends AccountAnalysisException {
  EmptyAccountAnalysisStackException();
  @override
  String toString() =>
      'EmptyAccountAnalysisStack: Attempt to restore AcccountAnalysis state from an empty stack.';
}

class AccureRemainingMisuseException extends AccountAnalysisException {
  AccureRemainingMisuseException();
  @override
  String toString() =>
      'AccrueRemainingMisuse: AccurRemaining called without previously saving account state.';

}