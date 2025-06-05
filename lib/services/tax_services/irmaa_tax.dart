import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'tax_base.dart';

/// Private class that represents IRMAA Tax tax bracket rules
/// [magi] Adjusted gross income limit for this bracket
/// [partBCost] Mutliplier for base rate at a given MAGI bracket
/// [partDCost] Additional fee for Medicare Part D at a given MAGI
class IrmaaTaxBracketRule {
  IrmaaTaxBracketRule({
    required this.magi,
    required this.partBCost,
    required this.partDCost,
  });
  final double magi;
  final double partBCost;
  final double partDCost;
} // end class IrmaaTaxBracketRule

/// Private class that represents IRMAA rules for a given filing status
/// [irmaaBrackets] List of IRMAA bracket rules for the specified year
class IrmaaTaxRulesByFilingStatus {
  IrmaaTaxRulesByFilingStatus({
    required this.year,
    required this.brackets,
  });
  int year;
  final List<IrmaaTaxBracketRule> brackets;
}

/// Private class that represents IRMAA rules for all filing statuses for a given year.
/// [year] Year that tax rules represent (per IRS Infomation)
/// [inflationRateMAGI] Inflation rate to be applied to MAGI limits
/// [inflationRateBaseCost] Inflation rate to be applied to base costs
/// [baseCost] Base cost for Medicare Part B
/// [single] IRMAA rules for single filers
/// [marriedFilingSeparate] IRMAA rules those filing Married Filing Separate
/// [marriedFilingJointly] IRMAA Rules for those filing Married Filing Jointly
/// [headOfHousehold] IRMAA Rules for those filing a Head of Household
class IrmaaTaxRules extends TaxRulesBase {
  IrmaaTaxRules({
    required super.year,
    required this.inflationRateMAGI,
    required this.inflationRateBaseCost,
    required this.baseCost,
    required this.single,
    required this.marriedFilingJointly,
  });
  double inflationRateMAGI;
  double inflationRateBaseCost;
  double baseCost;
  IrmaaTaxRulesByFilingStatus single;
  IrmaaTaxRulesByFilingStatus marriedFilingJointly;
}

/// A class that represents IRMAA Tax behavior for a given tax year and filings status
/// [filingSettings] -  Settings used to file taxes
/// [taxRules] - IRMAA Tax tax bracket rules for selected year and filing status
/// [baseCost] - Base cost of MEdicare Part B for elected year
class IrmaaTaxByFilingStatus extends TaxBase {
  late IrmaaTaxRulesByFilingStatus taxRules;
  late double baseCost;
  IrmaaTaxByFilingStatus(super.filingSettings) {
    _initTaxRulesByFilingStatus(filingSettings);
  }

  void _initTaxRulesByFilingStatus(TaxFilingSettings filingSettings) {
    IrmaaTaxRules irmaaTaxRules = TaxBase.getClosestTaxRulesByYear(
        filingSettings.targetYear, _irmaaTaxRulesList) as IrmaaTaxRules;
    // Initilaize base cost
    baseCost = irmaaTaxRules.baseCost;

    // Find the matching FilingStatus and intialize the correct TaxRulesByFilingStatus
    switch (filingSettings.filingStatus) {
      case FilingStatus.single:
      case FilingStatus.marriedFilingSeparately:
      case FilingStatus.headOfHousehold:
        taxRules = irmaaTaxRules.single;
        break;
      case FilingStatus.marriedFilingJointly:
        taxRules = irmaaTaxRules.marriedFilingJointly;
        break;
    }
    // verify that IrmaaTaxRulesByFilingStatus.year is the same as IrmaaTaxRules.year
    taxRules.year = irmaaTaxRules.year;
  }

  /// Calculates the additionl yearly amount due for IRMAA for a given MAGI and
  /// returns the total ADDITIONAL yearly amount for PART B and PART D because of higher MAGI
  /// [ownerType] - Identifies the person (self or spouse) for which taxes are calculated, however if not specified,
  /// the result includes taxes for both self and spouse (if married).
  /// Note: Medicare office uses MAGI from two years previous, i.e., if calculating IRMAA
  /// amounts for 2022 the MAGI for 2020 is used.
  double calcTaxes({OwnerType? ownerType}) {
    double result = 0;
    if (ownerType != null) {
      // Get yearly medicare base cost adjusted for the time value of money to match the targetYear.
      final double adjustedBaseCost = adjustForTime(
        valueToAdjust: baseCost * 12,
        toYear: filingSettings.targetYear,
        fromYear: taxRules.year,
      );
      // Get yearly medicare cost (already adjusted for time value of money to match target year)
      final double medicareCost = calcMedicareCost(ownerType: ownerType);
      // return the additional IRMAA cost adjusted for time value of money
      if (medicareCost == 0) {
        result = 0.0;
      } else {
        result = (medicareCost - adjustedBaseCost).roundToDouble();
      }
    } else {
      result = calcTaxes(ownerType: OwnerType.self);
      if (filingSettings.filingStatus.isMarried) {
        result += calcTaxes(ownerType: OwnerType.spouse);
      }
    }
    return result.roundToTwoPlaces();
  }

  /// Calculates the yearly Medicare Part B and D costs for a given MAGI and
  /// returns the total yearly Medicare cost for PART B and PART D
  /// If the availible taxRules.year is different than the targetYear, values
  /// will be adjusted for the time value of money
  /// [ownerType] - Identifies the person (self or spouse) for which taxes are calculated, however if not specified,
  /// the result includes taxes for both self and spouse (if married).
  /// Note: Medicare office uses MAGI from two years previous, i.e., if calculating IRMAA
  /// amounts for 2022 the MAGI for 2020 should be used.
  double calcMedicareCost({OwnerType? ownerType}) {
    double medicareCost = 0;

    if (filingSettings.filingStatus.isMarried &&
        filingSettings.spouseInventory == null) {
      throw Exception('Filing Married without specifing spouse inventory.');
    }

    if (ownerType != null) {
      double magi = 0;

      PersonInventory personInventory = ownerType.isSelf
          ? filingSettings.selfInventory
          : filingSettings.spouseInventory!;

      // Check if person is of Medicare age, if younger tehn there is no cost.
      if (personInventory.age < 65) {
        return 0.0;
      }

      if (filingSettings.filingStatus == FilingStatus.marriedFilingJointly) {
        magi = filingSettings.selfInventory.prevPrevYearsMAGI +
            filingSettings.spouseInventory!.prevPrevYearsMAGI;
      } else {
        magi = personInventory.prevPrevYearsMAGI;
      }
      // adjust the magi for the time value of money to match the taxRules year
      double adjustedMagi = adjustForTime(
        valueToAdjust: magi,
        toYear: taxRules.year,
        fromYear: filingSettings.targetYear,
      );

      for (final bracket in taxRules.brackets) {
        final double incomeLimit = bracket.magi;
        if (adjustedMagi <= incomeLimit || incomeLimit == 0) {
          medicareCost = (bracket.partBCost + bracket.partDCost) * 12;
          break;
        }
      }

      medicareCost = adjustForTime(
        valueToAdjust: medicareCost,
        toYear: filingSettings.targetYear,
        fromYear: taxRules.year,
      );
    } else {
      medicareCost = calcMedicareCost(ownerType: OwnerType.self);
      if (filingSettings.filingStatus.isMarried) {
        medicareCost += calcMedicareCost(ownerType: OwnerType.spouse);
      }
    }
    return medicareCost.roundToTwoPlaces();
  }
} // end class IrmaaByFilingStatus

final _irmaaTaxRulesList = [
  IrmaaTaxRules(
    year: 2021,
    inflationRateMAGI: 1.25,
    inflationRateBaseCost: 6.25,
    baseCost: 148.50,
    single: IrmaaTaxRulesByFilingStatus(year: 0, brackets: [
      IrmaaTaxBracketRule(magi: 88000, partBCost: 148.5, partDCost: 0),
      IrmaaTaxBracketRule(magi: 111000, partBCost: 207.90, partDCost: 12.30),
      IrmaaTaxBracketRule(magi: 138000, partBCost: 297.00, partDCost: 31.80),
      IrmaaTaxBracketRule(magi: 165000, partBCost: 386.10, partDCost: 51.20),
      IrmaaTaxBracketRule(magi: 500000, partBCost: 475.20, partDCost: 70.70),
      IrmaaTaxBracketRule(magi: 0, partBCost: 504.90, partDCost: 77.10),
    ]),
    marriedFilingJointly: IrmaaTaxRulesByFilingStatus(year: 0, brackets: [
      IrmaaTaxBracketRule(magi: 176000, partBCost: 148.5, partDCost: 0),
      IrmaaTaxBracketRule(magi: 222000, partBCost: 207.90, partDCost: 12.30),
      IrmaaTaxBracketRule(magi: 276000, partBCost: 297.00, partDCost: 31.80),
      IrmaaTaxBracketRule(magi: 330000, partBCost: 386.10, partDCost: 51.20),
      IrmaaTaxBracketRule(magi: 750000, partBCost: 475.20, partDCost: 70.70),
      IrmaaTaxBracketRule(magi: 0, partBCost: 504.90, partDCost: 77.10),
    ]),
  ),
  IrmaaTaxRules(
    year: 2025,
    inflationRateMAGI: 1.25,
    inflationRateBaseCost: 6.25,
    baseCost: 185.00,
    single: IrmaaTaxRulesByFilingStatus(year: 0, brackets: [
      IrmaaTaxBracketRule(magi: 106000, partBCost: 185.00, partDCost: 0),
      IrmaaTaxBracketRule(magi: 133000, partBCost: 259.00, partDCost: 12.30),
      IrmaaTaxBracketRule(magi: 167000, partBCost: 370.00, partDCost: 31.80),
      IrmaaTaxBracketRule(magi: 200000, partBCost: 480.90, partDCost: 51.20),
      IrmaaTaxBracketRule(magi: 500000, partBCost: 591.90, partDCost: 70.70),
      IrmaaTaxBracketRule(magi: 0, partBCost: 628.90, partDCost: 77.10),
    ]),
    marriedFilingJointly: IrmaaTaxRulesByFilingStatus(year: 0, brackets: [
      IrmaaTaxBracketRule(magi: 212000, partBCost: 185.00, partDCost: 0),
      IrmaaTaxBracketRule(magi: 266000, partBCost: 259.00, partDCost: 12.30),
      IrmaaTaxBracketRule(magi: 334000, partBCost: 370.00, partDCost: 31.80),
      IrmaaTaxBracketRule(magi: 400000, partBCost: 480.90, partDCost: 51.20),
      IrmaaTaxBracketRule(magi: 750000, partBCost: 591.90, partDCost: 70.70),
      IrmaaTaxBracketRule(magi: 0, partBCost: 628.90, partDCost: 77.10),
    ]),
  ),
];
