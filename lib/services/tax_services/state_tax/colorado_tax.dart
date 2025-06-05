import 'package:roth_analysis/services/tax_services/state_tax/flat_percentage_tax_state.dart';

/// Supports estimation of taxes for the state of Colorado
class ColoradoTax extends FlatPercentageTaxState {
  ColoradoTax(super.filingSettings) {
    interestIncomeIsTaxable = true;
    dividendIncomeIsTaxable = true;
    capitalGainsAreTaxable = true;
    regularIncomeIsTaxable = true;
    selfEmploymentIncomeIsTaxable = true;
  }

  @override
  double getDeductable() {
    return 0;
  }

  /// Returns the tax percentage
  /// May not factor in TABOR as the TABOR rules from year to year are
  /// too complicated and it is unclear what will happen to TABOR in the future.
  @override
  double getTaxPercentForTargetYear() {
    switch (filingSettings.targetYear) {
      case <= 2017:
        return 4.63;
      case 2018:
        return 4.63;
      case 2019:
        return 4.5;
      case 2020:
        return 4.55;
      case 2021:
        return 4.5;
      case >= 2002 && <= 2023:
        return 4.4;
      case 2024:
        return 4.25;
      case >= 2025:
        return 4.4;
      default:
        throwStandardStateException();
        return 0;
    }
  }
}

