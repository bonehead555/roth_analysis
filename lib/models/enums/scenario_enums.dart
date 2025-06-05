/// Enumerated Type that identifies how the Roth conversion amount constraint is specified.
/// [amount] - Indicates that it is a fixed amount to be convereted each year
/// [magiLimit] - Indicates that it is to be calculated such that it does not exceed a certain federal MAGI
/// [label] - Provides a human readable textual label for the cooresponding enum value
enum AmountConstraintType {
  amount('Fixed Amount'),
  magiLimit('MAGI Limit');

  final String label;

  /// Creates a named instance of an [AmountConstraintType] with specified [label]
  const AmountConstraintType(this.label);

  /// Returns a [AmountConstraintType] instance that correpsonds to the suppiled human readable [targetLabel]
  /// Returns AmountConstraintType.magiLimit if the label cannot be found.
  factory AmountConstraintType.fromLabel(String targetLabel) {
    for (var enumItem in AmountConstraintType.values) {
      if (enumItem.label == targetLabel) return enumItem;
    }
    return AmountConstraintType.magiLimit;
  }
}

/// Enumerated Type that identifies how the Roth conversion start date constraint is specified.
/// [onPlanStart] - Indicates that conversions are to start when the plan starts
/// [onFixedDate] - Indicates that conversions are to start on a specific date / year.
/// [label] - Provides a human readable textual label for the cooresponding enum value
enum ConversionStartDateConstraint {
  onPlanStart('On Start of Plan'),
  onFixedDate('On Fixed Date');

  final String label;

  /// Creates a named instance of an [ConversionStartDateConstraint] with specified [label]
  const ConversionStartDateConstraint(this.label);

  /// Returns a [ConversionStartDateConstraint] instance that correpsonds to the suppiled human readable [targetLabel]
  /// Returns ConversionStartDateConstraint.onFixedDate if the label cannot be found.
  factory ConversionStartDateConstraint.fromLabel(String targetLabel) {
    for (var enumItem in ConversionStartDateConstraint.values) {
      if (enumItem.label == targetLabel) return enumItem;
    }
    return ConversionStartDateConstraint.onFixedDate;
  }
}

/// Enumerated Type that identifies how the Roth conversion end date constraint is specified.
/// [onRmdStart] - Indicates that conversions are to end when RMDs begin.
/// [onFixedDate] - Indicates that conversions are to end on a specific date / year.
/// [onEndOfPlan] - Indicates that conversions are to end only when the plan ends.
/// [label] - Provides a human readable textual label for the cooresponding enum value
enum ConversionEndDateConstraint {
  onRmdStart('When RMDs Begin'),
  onFixedDate('On Fixed Date'),
  onEndOfPlan('On End of Plan');

  final String label;

  /// Creates a named instance of an [ConversionEndDateConstraint] with specified [label]
  const ConversionEndDateConstraint(this.label);

  /// Returns a [ConversionEndDateConstraint] instance that correpsonds to the suppiled human readable [targetLabel]
  /// Returns ConversionEndDateConstraint.onFixedDate if the label cannot be found.
  factory ConversionEndDateConstraint.fromLabel(String targetLabel) {
    for (var enumItem in ConversionEndDateConstraint.values) {
      if (enumItem.label == targetLabel) return enumItem;
    }
    return ConversionEndDateConstraint.onFixedDate;
  }
}
