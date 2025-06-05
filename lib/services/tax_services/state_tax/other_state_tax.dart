
import 'package:roth_analysis/services/tax_services/state_tax/flat_percentage_tax_state.dart';

class OtherStateTax extends FlatPercentageTaxState {
  OtherStateTax(super._filingSettings) {
    regularIncomeIsTaxable = true;
    selfEmploymentIncomeIsTaxable = true;
    ssIncomeIsTaxable = filingSettings.stateTaxesRetirementIncome;
    pensionIncomeIsTaxable = filingSettings.stateTaxesRetirementIncome;
  }

  @override
  double getTaxPercentForTargetYear() {
    return filingSettings.stateTaxPercentage;
  }

  @override
  double getDeductable() {
    return filingSettings.stateStandardDeduction;
  }
}