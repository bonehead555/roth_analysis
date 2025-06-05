import 'flat_percentage_tax_state.dart';

/// Supports estimation of taxes for the state of Washington
class WashingtonTax extends FlatPercentageTaxState {
  WashingtonTax(super.filingSettings) {
    capitalGainsAreTaxable = true;
  }

  @override
  double getDeductable() {
    const Map<int, double> knownYears = {
      2022: 250000,
      2023: 262000,
      2024: 270000,
    };
    if (filingSettings.targetYear < knownYears.entries.first.key) {
      return 0;
    }
    // Washington does not allow for both self and spouse deductables.
    return calcIndividualDeductbile(knownYears);
  }

  /// Returns the tax percentage for the filing year
  @override
  double getTaxPercentForTargetYear() {
    switch (filingSettings.targetYear) {
      case <= 2022:
        return 0.0;
      default:
        return 7.0; // <= 2023
    }
  }
}
