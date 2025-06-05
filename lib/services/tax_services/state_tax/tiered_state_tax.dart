import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'state_tax.dart';
import '../tax_base.dart';

/// Class used to support calculation of States with Tired Tax Rules
/// [year] Year that tax rules came from, table was taken from IRS Infomation
/// [individualDeduction] Deduction for self and/or spouse
/// [ageDeduction] Additional deduction if self and/or spouse is over 65
/// [blindDeduction] Additional deduction if self and/or spouse is blind
/// [taxBrackeets] One or more brackets / tires used to calcuale income tax
class TieredStateTaxRules extends TaxRulesBase {
  const TieredStateTaxRules({
    required super.year,
    required this.individualDeduction,
    required this.ageDeduction,
    required this.blindDeduction,
    required this.ssIncomeIsTaxable,
    required this.iraIncomeIsTaxable,
    required this.interestIncomeIsTaxable,
    required this.dividendIncomeIsTaxable,
    required this.capitalGainsAreTaxable,
    required this.regularIncomeIsTaxable,
    required this.selfEmploymentIncomeIsTaxable,
    required this.pensionIncomeIsTaxable,
    required this.taxBrackets,
  });
  final double individualDeduction;
  final double ageDeduction;
  final double blindDeduction;
  final bool ssIncomeIsTaxable;
  final bool iraIncomeIsTaxable;
  final bool interestIncomeIsTaxable;
  final bool dividendIncomeIsTaxable;
  final bool capitalGainsAreTaxable;
  final bool regularIncomeIsTaxable;
  final bool selfEmploymentIncomeIsTaxable;
  final bool pensionIncomeIsTaxable;
  final List<TaxBracketRule> taxBrackets;
}

/// Record that represents one of N tax bracket rule for a given filing status.
/// [agi] adjusted gross income limit for this tax bracket
/// [rate] tax rate to apply to income in this tax bracket
class TaxBracketRule {
  TaxBracketRule({
    required this.agi,
    required this.base,
    required this.rate,
  });
  double agi;
  double base;
  double rate;
}

class TieredStateTax extends StateTax {
  TieredStateTax(super.filingSettings, List<TaxRulesBase> taxRulesList) {
    taxRules = TaxBase.getClosestTaxRulesByYear(
        filingSettings.targetYear, taxRulesList) as TieredStateTaxRules;
    ssIncomeIsTaxable = taxRules.ssIncomeIsTaxable;
    iraIncomeIsTaxable = taxRules.iraIncomeIsTaxable;
    interestIncomeIsTaxable = taxRules.interestIncomeIsTaxable;
    dividendIncomeIsTaxable = taxRules.dividendIncomeIsTaxable;
    capitalGainsAreTaxable = taxRules.capitalGainsAreTaxable;
    regularIncomeIsTaxable = taxRules.regularIncomeIsTaxable;
  }

  late TieredStateTaxRules taxRules;

  @override
  double getDeductable() {
    double deductable = taxRules.individualDeduction;
    if (filingSettings.filingStatus == FilingStatus.marriedFilingJointly) {
      deductable *= 2;
      if (filingSettings.spouseInventory!.age >= 65) {
        deductable += taxRules.ageDeduction;
      }
      if (filingSettings.spouseInventory!.isBlind) {
        deductable += taxRules.blindDeduction;
      }
    }
    if (filingSettings.selfInventory.age >= 65) {
      deductable += taxRules.ageDeduction;
    }
    if (filingSettings.selfInventory.isBlind) {
      deductable += taxRules.blindDeduction;
    }
    return deductable;
  }

  /// Returns the state income tax for the specified inputs by
  /// uisng the taxRules, [filingSettings] and [taxableIncome].
  /// Time value adjustements are made for the difference between the year of the
  /// taxTable and the targetYear spefcified in [filingSettings].
  double _calcTaxes(double taxableIncome) {
    // Adjust the taxableIncome for the value of money to match the taxRules year.
    double adjustedIncome = adjustForTime(
      valueToAdjust: taxableIncome,
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );

    double prevIncomeLimit = 0;
    double result = 0;
    // find the matching tax bracket and us its rules to calculae yax.
    for (var bracket in taxRules.taxBrackets) {
      var incomeLimit = bracket.agi;
      var taxRate = bracket.rate;
      if (adjustedIncome <= incomeLimit) {
        result =
            bracket.base + (adjustedIncome - prevIncomeLimit) * taxRate / 100;
        break;
      }
      prevIncomeLimit = incomeLimit;
    }
    // Adjust the state income tax for the time value of money to match the target year.
    return adjustForTime(
      valueToAdjust: result,
      toYear: filingSettings.targetYear,
      fromYear: taxRules.year,
    );
  }

  @override
  double calcTaxes() {
    double taxes = _calcTaxes(getTaxableIncome());
    if (filingSettings.filingStatus == FilingStatus.marriedFilingSeparately) {
      taxes += _calcTaxes(getTaxableIncome(forSpouseOnly: true));
    }
    return taxes.roundToDouble();
  }
}
