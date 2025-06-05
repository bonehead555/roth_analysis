import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'tiered_state_tax.dart';

class OhioTax extends TieredStateTax {
  OhioTax(TaxFilingSettings filingSettings)
      : super(filingSettings, _taxRulesList);
}

final List<TieredStateTaxRules> _taxRulesList = [
  TieredStateTaxRules(
    year: 2021,
    individualDeduction: 0,
    ageDeduction: 0,
    blindDeduction: 0,
    ssIncomeIsTaxable: false,
    iraIncomeIsTaxable: true,
    interestIncomeIsTaxable: true,
    dividendIncomeIsTaxable: true,
    capitalGainsAreTaxable: true,
    regularIncomeIsTaxable: true,
    selfEmploymentIncomeIsTaxable: true,
    pensionIncomeIsTaxable: true,
    taxBrackets: [
      TaxBracketRule(agi: 25000, base: 0, rate: 0),
      TaxBracketRule(agi: 44250, base: 346.16, rate: 2.765),
      TaxBracketRule(agi: 88450, base: 878.42, rate: 3.226),
      TaxBracketRule(agi: 110650, base: 2304.31, rate: 3.688),
      TaxBracketRule(agi: double.infinity, base: 3123.05, rate: 3.990),
    ],
  ),
 TieredStateTaxRules(
    year: 2024,
    individualDeduction: 0,
    ageDeduction: 0,
    blindDeduction: 0,
    ssIncomeIsTaxable: false,
    iraIncomeIsTaxable: true,
    interestIncomeIsTaxable: true,
    dividendIncomeIsTaxable: true,
    capitalGainsAreTaxable: true,
    regularIncomeIsTaxable: true,
    selfEmploymentIncomeIsTaxable: true,
    pensionIncomeIsTaxable: true,
    taxBrackets: [
      TaxBracketRule(agi: 26050, base: 0, rate: 0),
      TaxBracketRule(agi: 100000, base: 360.69, rate: 2.75),
      TaxBracketRule(agi: double.infinity, base: 2394.32, rate: 3.5),
    ],
  ),
];
