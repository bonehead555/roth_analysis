/// Manages enumertion defining supported states.
/// * [label] - User readable label matching enumerated state.
enum FilingState {
  ak('Alaska'),
  co('Colorado'),
  fl('Florida'),
  il('Illinois'),
  oh('Ohio'),
  nv('Nevada'),
  nh('New Hampshire'),
  sd('South Dakota'),
  tn('Tennessee'),
  tx('Texas'),
  wa('Washington'),
  wy('Wyoming'),
  other('OTHER');

  final String label;

  const FilingState(this.label);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns FilingState.other if the label cannot be found.
  factory FilingState.fromLabel(String target) {
    for (var enumItem in FilingState.values) {
      if (enumItem.label == target) return enumItem;
    }
    return FilingState.other;
  }
}







