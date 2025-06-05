/// Manages enumertion defining supported account types.
/// * [label] - User readable label matching the enumerated value.
/// * [isTaxable] - True if gains associated with the account are federaly taxable.
enum AccountType {
  taxableSavings('Savings/CD', true),
  taxableBrokerage('Brokerage', true),
  traditionalIRA('Traditional IRA', false),
  rothIRA('Roth IRA', false);

  final String label;
  final bool isTaxable;

  const AccountType(this.label, this.isTaxable);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns AccountType.taxableSavings if the label cannot be found.
  factory AccountType.fromLabel(String target) {
    for (var enumItem in AccountType.values) {
      if (enumItem.label == target) return enumItem;
    }
    return AccountType.taxableSavings;
  }
}
