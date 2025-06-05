/// Manages enumertion defining supported income types.
/// * [label] - User readable label matching the enumerated value.
enum IncomeType {
  employment('Employment'),
  selfEmployment('Self-Employment'),
  socialSecurity('Social Security'),
  pension('Pension');

  final String label;

  const IncomeType(this.label);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns IncomeType.employment if the label cannot be found.
   factory IncomeType.fromLabel(String target) {
    for (var enumItem in IncomeType.values) {
      if (enumItem.label == target) return enumItem;
    }
    return IncomeType.employment;
  }
}
