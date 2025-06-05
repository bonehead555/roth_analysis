import 'package:roth_analysis/models/enums/filing_status.dart';
import 'state_tax.dart';

/// Base class of all State Tax Calculation classes for states comprising
/// a deductable and flat tax rate / percentage.
/// Requires all derived classes to override the calc() method.
abstract class FlatPercentageTaxState extends StateTax {
  FlatPercentageTaxState(super.filingSettings);

  double getTaxPercentForTargetYear();

  /// Returns total income taxes for the given year assuming the state 
  /// has a flat tax rate.
  @override
  double calcTaxes() {
    var taxableIncome = getTaxableIncome();
    if (filingSettings.filingStatus == FilingStatus.marriedFilingSeparately) {
      taxableIncome += getTaxableIncome(forSpouseOnly: true);
    }
    double taxes = taxableIncome * getTaxPercentForTargetYear() / 100;
    return taxes.roundToDouble();
  }
}