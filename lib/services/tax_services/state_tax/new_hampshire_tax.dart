import 'flat_percentage_tax_state.dart';

/// Supports estimation of taxes for the state of New Hampshire
class NewHampshireTax extends FlatPercentageTaxState {
  NewHampshireTax(super.filingSettings) {
    dividendIncomeIsTaxable = true;
    interestIncomeIsTaxable = true;
  }

  /// Returns the deduction/exemption amount
  /// There is an exemption for income of $2,400 or $4800 if married filing jointly
  /// A $1,200 exemption is available for residents who are 65 years of age or older.
  /// A $1,200 exemption is available for residents who are blind regardless of their age.
  /// And, a $1,200 exemption is available to disabled individuals who are unable to work,
  /// provided they have not reached their 65th birthday.
  @override
  double getDeductable() {
    const Map<int, double> knownYears = {
      2024: 2400,
    };
    return calcDeductible(
      knownYears,
      ageDeductable: 1200,
      blindDeductable: 1200,
    );
  }

  /// Returns the tax percentage
  @override
  double getTaxPercentForTargetYear() {
    switch (filingSettings.targetYear) {
      case >= 1977 && <= 2022:
        return 5.0;
      case 2023:
        return 4.0;
      case 2024:
        return 3.0;
      case >= 2025:
        return 0.0;
      default:
        throwStandardStateException();
        return 0;
    }
  }
}
