import 'state_tax.dart';
import 'flat_percentage_tax_state.dart';

/// Supports estimation of taxes for the state of New Hampshire
class IllinoisTax extends FlatPercentageTaxState {
  IllinoisTax(super.filingSettings) {
    interestIncomeIsTaxable = true;
    dividendIncomeIsTaxable = true;
    capitalGainsAreTaxable = true;
    regularIncomeIsTaxable = true;
    selfEmploymentIncomeIsTaxable = true;
  }

  /// Returns the deduction/exemption amount apprpriate foor the filing status.
  /// The single exemption depends on the year, must be doubled if married filing jointly
  /// A additional $1,000 exemption is available for residents who are 65 years of age or older.
  /// A additional $1,000 exemption is available for residents who are blind regardless of their age.
  /// Delegates work to the [StateTax.calcDeductible] method.
  @override
  double getDeductable() {
    const Map<int, double> knownYears = {
      2017: 2000,
      2018: 2225,
      2019: 2275,
      2020: 2325,
      2021: 2375,
      2022: 2425,
      2023: 2425,
    };
    return calcDeductible(
      knownYears,
      ageDeductable: 1000,
      blindDeductable: 1000,
    );
  }

  /// Returns the tax percentage
  @override
  double getTaxPercentForTargetYear() {
    switch (filingSettings.targetYear) {
      case >= 1969 && <= 1982:
        return 2.5;
      case 1983:
        return 3.0;
      case 1984:
        return 2.75;
      case >= 1985 && <= 1988:
        return 2.5;
      case 1989:
        return 2.75;
      case >= 1990 && <= 2010:
        return 3.00;
      case >= 2011 && <= 2014:
        return 5.00;
      case >= 2015 && <= 2017:
        return 3.75;
      case >= 2018:
        return 4.95;
      default:
        throw Exception(
            'Unsupported Tax Year (${filingSettings.targetYear} for the State of Illinois)');
    }
  }
}
