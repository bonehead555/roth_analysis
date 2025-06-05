/// Manages enumertion defining supported owner types.
/// * [label] - User readable label matching enumerated ownwer.
enum OwnerType {
  self('Self'),
  spouse('Spouse');

  final String label;
  const OwnerType(this.label);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns OwnerType.self if the label cannot be found.
  factory OwnerType.fromLabel(String target) {
    for (var enumItem in OwnerType.values) {
      if (enumItem.label == target) return enumItem;
    }
    return OwnerType.self;
  }

  /// Returns true if this enm represents the "self" owner.
  bool get isSelf => this == self;

  /// Returns true if this enm represents the "spouse" owner.
  bool get isSpouse => this == spouse;
}
