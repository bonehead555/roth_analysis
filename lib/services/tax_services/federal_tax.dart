import 'dart:math';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'fica_tax.dart';
import 'tax_base.dart';

/// Private utility class that represents information to support
/// the calculation of Federal Taxes for a specifc target year
/// [year] Year that tax rules came from, table was taken from IRS Infomation
/// [single] Tax rues for single filers
/// [marriedFilingSeparate] Tax rules for those filing Married Filing Separate
/// [marriedFilingJointly] Tax Rules for those filing Married Filing Jointly
/// [headOfHousehold] - Tax Rules for those filing a Head of Household
class FederalTaxRules extends TaxRulesBase {
  FederalTaxRules({
    required super.year,
    required this.single,
    required this.marriedFilingSeparate,
    required this.marriedFilingJointly,
    required this.headOfHousehold,
  });

  TaxRulesByFilingStatus single;
  TaxRulesByFilingStatus marriedFilingSeparate;
  TaxRulesByFilingStatus marriedFilingJointly;
  TaxRulesByFilingStatus headOfHousehold;
}

/// Private utility class that represents information to support
/// calculation of Federal Taxes for a specific year and filing status
/// [year] - Year that tax rules came from, table was taken from IRS Infomation
/// [standardDeduction] - Standard deduction for tax year and filing status
/// [taxBrackets] - Tax brackets for tax year and filing status
/// [capitalGainsBrackets] - Capital gains brackets for tax year and filing status
/// [netInvestmentIncomeTax] - Net Investement Income rules for tax year and filing status
class TaxRulesByFilingStatus {
  TaxRulesByFilingStatus({
    required this.year,
    required this.standardDeduction,
    required this.taxBrackets,
    required this.capitalGainsBrackets,
    required this.netInvestmentIncomeTax,
  });
  int year;
  StandardDeductionRule standardDeduction;
  List<TaxBracketRule> taxBrackets;
  List<TaxBracketRule> capitalGainsBrackets;
  NetInvestementIncomeRule netInvestmentIncomeTax;
}

/// Private utility class that represents data to calculate standard deduction
/// for a given year and filing status
/// [base] base deductgion for the given filing status.
/// [additional] additional amount for those 65 and older or blind
class StandardDeductionRule {
  StandardDeductionRule({
    required this.base,
    required this.additional,
  });
  double base;
  double additional;
}

/// Private utility class that represents one of N tax bracket rules
/// for a given year and filing status.
/// [agi] adjusted gross income limit for this tax bracket
/// [rate] tax rate to apply to income in this tax bracket
class TaxBracketRule {
  TaxBracketRule({
    required this.agi,
    required this.rate,
  });
  double agi;
  double rate;
}

/// Private utility class that represets the rules for calaculatin of net investment income
/// for a year and filing status.
/// [magiThreshold] income limit up to which net investement income is not qpplicable.
/// [rate] income rate to apply when [magiThreshold] is reached / exceeded.
class NetInvestementIncomeRule {
  NetInvestementIncomeRule({
    required this.magiThreshold,
    required this.rate,
  });
  double magiThreshold;
  double rate;
}

/// Class that supports the calculation of Federal Taxes for a given year and filing status
/// [_taxRules] - Tax rules for specified filing status and year closest but less than specified year.
///   I.e., there may be no matching tax rules for the specified year, e.g., it sin the future.
class FederalTaxByFilingStatus extends TaxBase {
  late TaxRulesByFilingStatus _taxRules;
  late FicaTax _ficaTax;

  /// Default Constructor
  FederalTaxByFilingStatus(super._filingSettings) {
    validateFederalFilingSettings(filingSettings);
    final federalTaxRules = TaxBase.getClosestTaxRulesByYear(
            filingSettings.targetYear, _historicalFederalTaxRules)
        as FederalTaxRules;
    _taxRules = _getTaxRulesByFilingStatus(
        federalTaxRules, filingSettings.filingStatus);
    _ficaTax = FicaTax(filingSettings);
  }

  /// Returns the TaxRulesByFilingStatus for the specified filing status
  static TaxRulesByFilingStatus _getTaxRulesByFilingStatus(
    FederalTaxRules federalTaxRules,
    FilingStatus filingStatus,
  ) {
    // Find the matching FilingStatus and intialize the correct TaxRulesByFilingStatus
    TaxRulesByFilingStatus result = federalTaxRules.single;
    if (filingStatus == FilingStatus.marriedFilingSeparately) {
      result = federalTaxRules.marriedFilingSeparate;
    }
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result = federalTaxRules.marriedFilingJointly;
    }
    if (filingStatus == FilingStatus.headOfHousehold) {
      result = federalTaxRules.headOfHousehold;
    }
    // make sure year in TaxRulesdBuyFilingStatus.year matches FederalTaxRules.year
    result.year = federalTaxRules.year;
    return result;
  }

  static void validateFederalFilingSettings(TaxFilingSettings filingSettings) {
    if (filingSettings.filingStatus == FilingStatus.marriedFilingSeparately) {
      throw Exception(
          'Filing status of marriedFilingSeparetly is currently not supported in Federal Tax calculations');
    }
  }

  /// Returns the configured [TaxRulesByFilingStatus]
  TaxRulesByFilingStatus get taxRules => _taxRules;

  /// Returns the configured [FicaTax] object
  FicaTax get ficaTax => _ficaTax;

  /// Sets new [TaxFilingSettings]. New settings must have the same
  /// [targetYear] and [filingStatus].
  @override
  set filingSettings(TaxFilingSettings newFilingSettings) {
    if (targetYear != newFilingSettings.targetYear ||
        filingStatus != newFilingSettings.filingStatus) {
      throw Exception('Cannot change target year or filing Status');
    }
    validateFederalFilingSettings(newFilingSettings);
    super.filingSettings = newFilingSettings;
  }

  /// Returns the Total Income apprpriate for the configured filing status
  /// Includes regularIncome, selfEmploymentIncome, pensionIncome, interestIncome, dividendIncome,
  /// capitalGainIncome, iraDistributions and taxable social secuirty income.
  /// regularIncome and selfEmployment are adjusted for FICA and Medicare taxes.
  /// Schedule 1 Income is ignored
  double totalIncome() {
    double totalIncomeBeforeSS = regularIncome +
        selfEmploymentIncome -
        ficaTax.ficaTaxAdjustment() -
        ficaTax.medicareTaxAdjustment() +
        pensionIncome +
        interestIncome +
        dividendIncome +
        capitalGainsIncome +
        iraDistributions;

    return totalIncomeBeforeSS + taxableSocialSecurity(totalIncomeBeforeSS);
  }

  /// Returns the Adjusted Gross Income (AGI) apprpriate for the configured filing status
  /// * Includes totalIncome;
  /// * Schedule 1 adjustements are ignored
  double get adjustedGrossIncome {
    return totalIncome();
  }

  /// Returns the MOdified Adjusted Gross Income (AGI) apprpriate for the configured filing status
  /// * Includes totalIncome;
  /// * All MAGI adjustements are ignored
  double get modifiedAdjustedGrossIncome {
    return totalIncome();
  }

  /// Returns dollar amount of Social Security benefit that is taxable
  /// [totalIncomeBeforeSS] Adjusted gross income before accounting for Social Secuity Income
  /// Combined income if the filing status is "married_filing_jointly"
  /// The brackets and rates are not indexed for inflation.
  double taxableSocialSecurity(double totalIncomeBeforeSS) {
    // IRS tax appropriation for various combined income brackets
    const double allocate50Percent = 0.5;
    const double allocate85Percent = 0.85;
    final double maximumTaxableSS = ssIncome * allocate85Percent;

    // Per IRS, those filing marriedFilingSeperately have the maximum SS income allocated as taxable
    if (filingStatus == FilingStatus.marriedFilingSeparately) {
      return maximumTaxableSS;
    }

    // Per IRS, combined income is your adjusted gross income (AGI) plus
    // nontaxable interest and half of your Social Security benefits from the year.
    final double combinedIncome = totalIncomeBeforeSS + ssIncome / 2;

    // Get appropriate income limits for specified tax filing status
    final double lowerCombinedIncomeLimit =
        filingStatus == FilingStatus.marriedFilingJointly ? 32000.0 : 25000.0;
    final middleCombinedIncomeGap =
        filingStatus == FilingStatus.marriedFilingJointly ? 12000.0 : 8000.0;
    final double upperCombinedIncomeLimit =
        lowerCombinedIncomeLimit + middleCombinedIncomeGap;

    // Per IRS, if your combined income is less than the lower combined income limit, then SS income is not taxable.
    if (combinedIncome <= lowerCombinedIncomeLimit) {
      return 0.0;
    }

    // Per IRS, combined income in the middle tier is allocated at 50% rate of combined income existing in that middle tier
    // Insuring that this amount does not exceed 50% of the ssIncome
    final double combinedIncomeOverLowerLimit =
        combinedIncome - lowerCombinedIncomeLimit;
    final double middleTaxableCombinedIncome =
        min(combinedIncomeOverLowerLimit, middleCombinedIncomeGap) *
            allocate50Percent;
    final double middleTaxableSS =
        min(middleTaxableCombinedIncome, ssIncome * allocate50Percent);

    // Per IRS, if the combined income is less than the upper limit, only the middle tier is allocated.
    if (combinedIncome <= upperCombinedIncomeLimit) {
      return middleTaxableSS;
    }

    // Per IRS, combined income in the upper tier is allocated at the maximum allocation rate
    final double combinedIncomeOverUpperLimit =
        combinedIncome - upperCombinedIncomeLimit;
    final double upperTaxableCombinedIncome =
        combinedIncomeOverUpperLimit * allocate85Percent;

    // Per IRS, insure that thewe do not exceed the maximum amount of SS that is taxable.
    final double taxableSS =
        min(middleTaxableSS + upperTaxableCombinedIncome, maximumTaxableSS);
    return taxableSS.roundToDouble();
  }

  /// Returns the taxable income
  /// That is, adjusted gross income minus the standard deduction.
  /// Qualified Business Income is ignored.
  double taxableIncome() {
    // get the adjusted gross income adjusted to match the tax table year.
    double agi = adjustForTime(
      valueToAdjust: adjustedGrossIncome,
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );
    // return the agi minus deduction adjusted back to match the target year.
    return adjustForTime(
      valueToAdjust: max(0.0, agi - standardDeduction),
      toYear: filingSettings.targetYear,
      fromYear: taxRules.year,
    );
  }

  double incrementalTaxRate({double additionalIncome = 0}) {
    // get amount of regular income adjusted for the time value to match the taxRules year
    double ordinaryIncome = adjustForTime(
      valueToAdjust: taxableIncome() - capitalGainsIncome + additionalIncome,
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );

    double result = 0;
    for (var bracket in taxRules.taxBrackets) {
      var incomeLimit = bracket.agi;
      var taxRate = bracket.rate / 100;
      if (incomeLimit == 0) {
        result = taxRate;
        break;
      } else if (ordinaryIncome <= incomeLimit) {
        result = taxRate;
        continue;
      } else {
        //(ordinaryIncome > incomeLimit)
        break;
      }
    }
    return result;
  }

  /// Returns the federal income tax from ordinary income
  double ordinaryIncomeTax() {
    // get amount of regular income adjusted for the time value to match the taxRules year
    double ordinaryIncome = adjustForTime(
      valueToAdjust: max(0.0, taxableIncome() - capitalGainsIncome),
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );

    double prevIncomeLimit = 0;
    double result = 0;

    for (var bracket in taxRules.taxBrackets) {
      var incomeLimit = bracket.agi;
      var taxRate = bracket.rate;
      if (incomeLimit == 0) {
        result = result + (ordinaryIncome - prevIncomeLimit) * taxRate / 100;
        break;
      } else if (ordinaryIncome <= incomeLimit) {
        result += (ordinaryIncome - prevIncomeLimit) * taxRate / 100;
        break;
      } else {
        result += (incomeLimit - prevIncomeLimit) * taxRate / 100;
        prevIncomeLimit = incomeLimit;
      }
    }
    // return amount of tax, adjusted for the time value to match the target year
    return adjustForTime(
      valueToAdjust: result,
      toYear: filingSettings.targetYear,
      fromYear: taxRules.year,
    );
  }

  /// Calulates the federal tax due to capital gains for a given income,
  /// and filing status and tax year;
  /// and returns total income taxes from capital gains for the given year.
  /// [adjustedAgi] Adjusted gross income including capital gains
  /// [adjustedCapitalGainsIncome] Capital gains income
  /// [taxDeduction] Availible tax deduction
  double capitalGainsTax() {
    // get amount of agi and captial gains adjusted for the time value to match the taxRules year
    double adjustedAgi = adjustForTime(
      valueToAdjust: adjustedGrossIncome,
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );
    double adjustedCapitalGainsIncome = adjustForTime(
      valueToAdjust: capitalGainsIncome,
      toYear: taxRules.year,
      fromYear: filingSettings.targetYear,
    );

    // initalize some variables to use in the loop below
    final incomeLessCapGains =
        max(0.0, adjustedAgi - standardDeduction - adjustedCapitalGainsIncome);
    double remainingCapGains = adjustedCapitalGainsIncome;
    double capGainsTax = 0;
    //
    // for each bracket in the the capitaslGains table determine if any capital gains fit the bracket...
    //    Compute the tax for that bracket and accumulate it.
    //    And adjust the ramining capital gains to be taxed.
    //
    for (var taxRule in taxRules.capitalGainsBrackets) {
      var incomeLimit = taxRule.agi;
      var taxRate = taxRule.rate;
      var capGainsInBracket = incomeLimit - incomeLessCapGains;
      if (incomeLimit == 0) {
        //
        // This is the last tax bracket, so add in taxes for the remaining capital gains
        // at the tax rate for this final bracket, then we're done accumulating cap gains taxes
        // as this will be the last time through this loop
        //
        capGainsTax += remainingCapGains * taxRate / 100;
      } else {
        //
        // Determine the capital gains that fit into this bracket by determining how far the
        // income is below the income limit.  Also make sure that this value is not larger than the
        // remaining untaxed capital gains.
        capGainsInBracket =
            min(remainingCapGains, incomeLimit - incomeLessCapGains);
        if (capGainsInBracket <= 0) {
          //
          // if the captial gains in this bracket is less than or equal to 0 then there are no
          // capital gains to tax in this bracket, so nothing to do
          //
        } else {
          //
          // There are capital gains to tax within this bracket, so ...
          //    add in taxes for the capital gains within this bracket
          //    and adjust the remaining untaxed captital gains by the cap gains taxed here
          //
          capGainsTax += capGainsInBracket * taxRate / 100;
          remainingCapGains -= capGainsInBracket;
        }
      }
    }
    return adjustForTime(
        valueToAdjust: capGainsTax,
        toYear: filingSettings.targetYear,
        fromYear: taxRules.year);
  }

  /// Returns the standard deduction amount
  double get standardDeduction {
    var result = taxRules.standardDeduction.base;

    if (filingSettings.selfInventory.age >= 65) {
      result = result + taxRules.standardDeduction.additional;
    }
    if (filingSettings.selfInventory.isBlind) {
      result = result + taxRules.standardDeduction.additional;
    }
    if (filingSettings.filingStatus == FilingStatus.marriedFilingJointly &&
        filingSettings.spouseInventory != null) {
      if (filingSettings.spouseInventory!.age >= 65) {
        result = result + taxRules.standardDeduction.additional;
      }
      if (filingSettings.spouseInventory!.isBlind) {
        result = result + taxRules.standardDeduction.additional;
      }
    }
    return result;
  }

  /// Calulates net investment income (NIIT) tax, given...
  /// * [magi] - Modified adjusted from income.
  /// * [nii] - Net investment income.
  /// 
  /// Your modified adjusted gross income (MAGI) determines if you owe the net investment income tax.
  /// If your MAGI is higher than the statutory threshold for your filing status,
  /// then you must pay the net investment income tax.
  /// Next, you’ll need to figure out your net investment income (Interest, Capital gains,
  /// Dividends, Income from passive investment activities. Non-qualified annuity distributions,
  /// Rental and royalty income
  /// But before you can calculate your NII, you must know your gross investment income.
  /// Once you have that, subtracting eligible deductions from your gross investment income will provide you your NII.
  /// Some common investment deductions are brokerage fees, investment advisory fees, tax preparation charges,
  /// local and state income taxes, fiduciary expenses, investment interest expenses
  /// and any costs involved with rental and royalty income.
  /// You pay the NIIT based on the lesser of your net investment income
  /// or the amount by which your modified adjusted gross income (MAGI) surpasses the filing status-based thresholds imposed by the IRS.
  /// The dollar amount that’s subject to this 3.8% tax, will vary as follows:
  /// If your net investment income is lower than the amount by which you exceeded the statutory threshold, the tax applies to your NII.
  /// If your net investment income is higher than the amount by which you exceeded the statutory threshold, the tax applies to that exceeding value.
  /// Note: (NIIT) is a 3.8% surtax
  /// Note: threshold amounts are not indexed for inflation.
  /// Note: NIIT did not exist befor 2013.
  // ignore: unused_element
  double _calcNIIT(double magi, double nii) {
    if (taxRules.year < 2013) {
      return 0;
    }
    if (magi <= taxRules.netInvestmentIncomeTax.magiThreshold) {
      return 0;
    }
    double amountAboveThreshhold =
        magi - taxRules.netInvestmentIncomeTax.magiThreshold;
    double taxableAMount = min(amountAboveThreshhold, nii);
    return (taxableAMount * 3.8 / 100).roundToDouble();
  }

  /// Returns total income taxes for the given year.
  double calcIncomeTax() {
    // calculate tax from regular income
    double result = ordinaryIncomeTax();
    // adjust based on capital gains tax
    result += capitalGainsTax();
    result += _calcNIIT(modifiedAdjustedGrossIncome, interestIncome + dividendIncome + capitalGainsIncome);

    // return rounded result
    return result.roundToDouble();
  }
} // end class FederalTaxByFilingStatus

/// Federal Tax Rules for the year 2021
final _federalTaxRules2021 = FederalTaxRules(
  year: 2021,
  single: TaxRulesByFilingStatus(
    year: 2021,
    standardDeduction: StandardDeductionRule(base: 12550, additional: 1700),
    taxBrackets: [
      TaxBracketRule(agi: 9950, rate: 10),
      TaxBracketRule(agi: 40525, rate: 12),
      TaxBracketRule(agi: 86375, rate: 22),
      TaxBracketRule(agi: 164925, rate: 24),
      TaxBracketRule(agi: 209425, rate: 32),
      TaxBracketRule(agi: 523600, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 40400, rate: 0),
      TaxBracketRule(agi: 445850, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
  marriedFilingSeparate: TaxRulesByFilingStatus(
    year: 2021,
    standardDeduction: StandardDeductionRule(base: 12550, additional: 1350),
    taxBrackets: [
      TaxBracketRule(agi: 9950, rate: 10),
      TaxBracketRule(agi: 40525, rate: 12),
      TaxBracketRule(agi: 86375, rate: 22),
      TaxBracketRule(agi: 164925, rate: 24),
      TaxBracketRule(agi: 209425, rate: 32),
      TaxBracketRule(agi: 314150, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 40400, rate: 0),
      TaxBracketRule(agi: 250800, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 125000, rate: 3.8),
  ),
  marriedFilingJointly: TaxRulesByFilingStatus(
    year: 2021,
    standardDeduction: StandardDeductionRule(base: 25100, additional: 1350),
    taxBrackets: [
      TaxBracketRule(agi: 19900, rate: 10),
      TaxBracketRule(agi: 81050, rate: 12),
      TaxBracketRule(agi: 172750, rate: 22),
      TaxBracketRule(agi: 329850, rate: 24),
      TaxBracketRule(agi: 418850, rate: 32),
      TaxBracketRule(agi: 628300, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 80800, rate: 0),
      TaxBracketRule(agi: 501600, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 250000, rate: 3.8),
  ),
  headOfHousehold: TaxRulesByFilingStatus(
    year: 2021,
    standardDeduction: StandardDeductionRule(base: 18800, additional: 1700),
    taxBrackets: [
      TaxBracketRule(agi: 14200, rate: 10),
      TaxBracketRule(agi: 54200, rate: 12),
      TaxBracketRule(agi: 86350, rate: 22),
      TaxBracketRule(agi: 164900, rate: 24),
      TaxBracketRule(agi: 209400, rate: 32),
      TaxBracketRule(agi: 523600, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 54100, rate: 0),
      TaxBracketRule(agi: 473750, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
);

/// Federal Tax Rules of the year 2024
final _federalTaxRules2024 = FederalTaxRules(
  year: 2024,
  single: TaxRulesByFilingStatus(
    year: 2024,
    standardDeduction: StandardDeductionRule(base: 14600, additional: 1550),
    taxBrackets: [
      TaxBracketRule(agi: 11600, rate: 10),
      TaxBracketRule(agi: 47150, rate: 12),
      TaxBracketRule(agi: 100525, rate: 22),
      TaxBracketRule(agi: 191950, rate: 24),
      TaxBracketRule(agi: 243725, rate: 32),
      TaxBracketRule(agi: 609350, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 47025, rate: 0),
      TaxBracketRule(agi: 518900, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
  marriedFilingSeparate: TaxRulesByFilingStatus(
    year: 2024,
    standardDeduction: StandardDeductionRule(base: 14600, additional: 1550),
    taxBrackets: [
      TaxBracketRule(agi: 11600, rate: 10),
      TaxBracketRule(agi: 47150, rate: 12),
      TaxBracketRule(agi: 100525, rate: 22),
      TaxBracketRule(agi: 191950, rate: 24),
      TaxBracketRule(agi: 243725, rate: 32),
      TaxBracketRule(agi: 365600, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 47025, rate: 0),
      TaxBracketRule(agi: 291850, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 125000, rate: 3.8),
  ),
  marriedFilingJointly: TaxRulesByFilingStatus(
    year: 2024,
    standardDeduction: StandardDeductionRule(base: 29200, additional: 1550),
    taxBrackets: [
      TaxBracketRule(agi: 23200, rate: 10),
      TaxBracketRule(agi: 94300, rate: 12),
      TaxBracketRule(agi: 201050, rate: 22),
      TaxBracketRule(agi: 383900, rate: 24),
      TaxBracketRule(agi: 487450, rate: 32),
      TaxBracketRule(agi: 731200, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 94050, rate: 0),
      TaxBracketRule(agi: 583750, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 250000, rate: 3.8),
  ),
  headOfHousehold: TaxRulesByFilingStatus(
    year: 2024,
    standardDeduction: StandardDeductionRule(base: 21900, additional: 1550),
    taxBrackets: [
      TaxBracketRule(agi: 16550, rate: 10),
      TaxBracketRule(agi: 63100, rate: 12),
      TaxBracketRule(agi: 100500, rate: 22),
      TaxBracketRule(agi: 191950, rate: 24),
      TaxBracketRule(agi: 243700, rate: 32),
      TaxBracketRule(agi: 609350, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 63000, rate: 0),
      TaxBracketRule(agi: 551350, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
);

/// Federal Tax Rules of the year 2024
final _federalTaxRules2025 = FederalTaxRules(
  year: 2025,
  single: TaxRulesByFilingStatus(
    year: 2025,
    standardDeduction: StandardDeductionRule(base: 14600, additional: 2000),
    taxBrackets: [
      TaxBracketRule(agi: 11925, rate: 10),
      TaxBracketRule(agi: 48475, rate: 12),
      TaxBracketRule(agi: 103350, rate: 22),
      TaxBracketRule(agi: 197300, rate: 24),
      TaxBracketRule(agi: 250525, rate: 32),
      TaxBracketRule(agi: 626350, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 48350, rate: 0),
      TaxBracketRule(agi: 533400, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
  marriedFilingSeparate: TaxRulesByFilingStatus(
    year: 2025,
    standardDeduction: StandardDeductionRule(base: 14600, additional: 2000),
    taxBrackets: [
      TaxBracketRule(agi: 11925, rate: 10),
      TaxBracketRule(agi: 48475, rate: 12),
      TaxBracketRule(agi: 103350, rate: 22),
      TaxBracketRule(agi: 197300, rate: 24),
      TaxBracketRule(agi: 250525, rate: 32),
      TaxBracketRule(agi: 626350, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 47025, rate: 0),
      TaxBracketRule(agi: 291850, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 125000, rate: 3.8),
  ),
  marriedFilingJointly: TaxRulesByFilingStatus(
    year: 2025,
    standardDeduction: StandardDeductionRule(base: 30000, additional: 1600),
    taxBrackets: [
      TaxBracketRule(agi: 23850, rate: 10),
      TaxBracketRule(agi: 96950, rate: 12),
      TaxBracketRule(agi: 206700, rate: 22),
      TaxBracketRule(agi: 394600, rate: 24),
      TaxBracketRule(agi: 501050, rate: 32),
      TaxBracketRule(agi: 751600, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 96700, rate: 0),
      TaxBracketRule(agi: 600050, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 250000, rate: 3.8),
  ),
  headOfHousehold: TaxRulesByFilingStatus(
    year: 2025,
    standardDeduction: StandardDeductionRule(base: 22500, additional: 1550),
    taxBrackets: [
      TaxBracketRule(agi: 17000, rate: 10),
      TaxBracketRule(agi: 64850, rate: 12),
      TaxBracketRule(agi: 103350, rate: 22),
      TaxBracketRule(agi: 197300, rate: 24),
      TaxBracketRule(agi: 250500, rate: 32),
      TaxBracketRule(agi: 626350, rate: 35),
      TaxBracketRule(agi: 0, rate: 37),
    ],
    capitalGainsBrackets: [
      TaxBracketRule(agi: 64750, rate: 0),
      TaxBracketRule(agi: 566700, rate: 15),
      TaxBracketRule(agi: 0, rate: 20),
    ],
    netInvestmentIncomeTax:
        NetInvestementIncomeRule(magiThreshold: 200000, rate: 3.8),
  ),
);


List<FederalTaxRules> _historicalFederalTaxRules = [
  _federalTaxRules2021,
  _federalTaxRules2024,
  _federalTaxRules2025,
];
