/// Manages enumertion defining supported federal filing status.
/// * [label] - User readable label matching the enumerated filing status enum.
enum FilingStatus {
  single('Single'),
  marriedFilingJointly('Married Filing Jointly'),
  marriedFilingSeparately('Married Filing Separately'),
  headOfHousehold('Head of Household');

  final String label;

  const FilingStatus(this.label);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns FilingStatus.single if the label cannot be found.
  factory FilingStatus.fromLabel(String target) {
    for (var enumItem in FilingStatus.values) {
      if (enumItem.label == target) return enumItem;
    }
    return FilingStatus.single;
  }

  /// Returns true if the filing status enumeration is for married individuals.
  bool get isMarried {
    return this == FilingStatus.marriedFilingJointly ||
        this == FilingStatus.marriedFilingSeparately;
  }
}
