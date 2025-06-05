import 'dart:math';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/services/tax_services/state_tax/other_state_tax.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'colorado_tax.dart';
import 'illinois_tax.dart';
import 'new_hampshire_tax.dart';
import 'ohio_tax.dart';
import 'washington_tax.dart';
import 'todo_state_tax.dart';
import 'zero_state_tax.dart';
import '../tax_base.dart';

/// Base class of all State Tax Calculation classes.
/// Requires all derived classes to override [getDeductable] with state specifc deductable calculations
/// Requires all derived classes to override [calcTaxes] with state specific tax calculations.
abstract class StateTax extends TaxBase {
  StateTax(super.filingSettings);
  bool ssIncomeIsTaxable = false;
  bool iraIncomeIsTaxable = false;
  bool interestIncomeIsTaxable = false;
  bool dividendIncomeIsTaxable = false;
  bool capitalGainsAreTaxable = false;
  bool regularIncomeIsTaxable = false;
  bool selfEmploymentIncomeIsTaxable = false;
  bool pensionIncomeIsTaxable = false;

factory StateTax.getStateSpecifcService(TaxFilingSettings filingSettings) {
    StateTaxFactory stateTaxFactory =
      _supportedStates[filingSettings.filingState] ?? todoStateTaxFactory;
  return stateTaxFactory(filingSettings);
}

  /// Returns the taxable income.
  /// [forSpouseOnly] indicates that the calculation should only use spouse data
  /// used for marriedFilingSeperately.
  double getTaxableIncome({bool forSpouseOnly = false}) {
    double totalIncome = 0;

    double selfIncome = 0;
    selfIncome += ssIncomeIsTaxable ? filingSettings.selfInventory.ssIncome : 0;
    selfIncome += iraIncomeIsTaxable ? filingSettings.selfInventory.iraDistributions : 0;
    selfIncome +=
        interestIncomeIsTaxable ? filingSettings.selfInventory.interestIncome : 0;
    selfIncome +=
        dividendIncomeIsTaxable ? filingSettings.selfInventory.dividendIncome : 0;
    selfIncome +=
        capitalGainsAreTaxable ? filingSettings.selfInventory.capitalGainsIncome : 0;
    selfIncome +=
        regularIncomeIsTaxable ? filingSettings.selfInventory.regularIncome : 0;
    selfIncome += selfEmploymentIncomeIsTaxable
        ? filingSettings.selfInventory.selfEmploymentIncome
        : 0;
    selfIncome +=
        pensionIncomeIsTaxable ? filingSettings.selfInventory.pensionIncome : 0;

    double spouseIncome = 0;
    if (filingSettings.spouseInventory != null) {
      spouseIncome += ssIncomeIsTaxable ? filingSettings.spouseInventory!.ssIncome : 0;
      spouseIncome +=
          iraIncomeIsTaxable ? filingSettings.spouseInventory!.iraDistributions : 0;
      spouseIncome +=
          interestIncomeIsTaxable ? filingSettings.spouseInventory!.interestIncome : 0;
      spouseIncome +=
          dividendIncomeIsTaxable ? filingSettings.spouseInventory!.dividendIncome : 0;
      spouseIncome += capitalGainsAreTaxable
          ? filingSettings.spouseInventory!.capitalGainsIncome
          : 0;
      spouseIncome +=
          regularIncomeIsTaxable ? filingSettings.spouseInventory!.regularIncome : 0;
      spouseIncome += selfEmploymentIncomeIsTaxable
          ? filingSettings.spouseInventory!.selfEmploymentIncome
          : 0;
      spouseIncome +=
          pensionIncomeIsTaxable ? filingSettings.spouseInventory!.pensionIncome : 0;
    }

    if (filingSettings.filingStatus == FilingStatus.marriedFilingJointly) {
      totalIncome = selfIncome + spouseIncome;
    } else if (filingSettings.filingStatus ==
            FilingStatus.marriedFilingSeparately &&
        forSpouseOnly) {
      totalIncome = spouseIncome;
    } else {
      // filingSettings.filingStatus is either single or headOfhousehold
      totalIncome = selfIncome;
    }
    return max(totalIncome - getDeductable(), 0.0);
  }

  /// [Abstract] Returns the deductable / exemption amount apprpriate for the filing status.
  /// Should be overridden by the derived classes.
  /// Derived implementaions typically provide a Map of year to deductable values and
  /// delegate calculations to [calcDeductible] and/or [calcIndividualDeductbile]
  double getDeductable();

  /// [Abstract] Returns the state income tax apprpriate for the filing settings.
  /// Should be overridden by the derived classes.
  double calcTaxes();


  /// Returns an individuals (self / spouse) deductable adjusted for time.
  /// [knownYears] map of year and single deductable amount.
  /// [ageDeductable] amount to adust if 65 or over
  /// [blindDeductable] amount to adjust if blind
  double calcIndividualDeductbile(Map<int, double>? knownYears,
      {double ageDeductable = 0, double blindDeductable = 0}) {
    double deductible = 0;
    if (knownYears == null || knownYears.entries.isEmpty) {
      deductible = 0;
    } else if (knownYears[targetYear] != null) {
      deductible = knownYears[targetYear]!;
    } else {
      // Need to extarpolate the deductable
      final firstEntry = knownYears.entries.first;
      final lastEntry = knownYears.entries.last;

      final double projectedInflationRatio = pow(
          lastEntry.value / firstEntry.value,
          1.0 / (lastEntry.key - firstEntry.key)) as double;

      if (targetYear < lastEntry.key) {
        // targetYear is before known years, adjust to targetYear from firstEntry year
        deductible = adjustForTime(
          valueToAdjust: firstEntry.value,
          toYear: targetYear,
          fromYear: firstEntry.key,
          rateOfIncrease: projectedInflationRatio,
        );
      } else {
        // targetYear is beyond known years, adjust to targetYear from lastEntry year
        deductible = adjustForTime(
          valueToAdjust: lastEntry.value,
          toYear: targetYear,
          fromYear: lastEntry.key,
          rateOfIncrease: projectedInflationRatio,
        );
      }
    }
    // overall deducable include applicable ageDeductable and blindDeducuctable
    // which are assumed to not chnage over time.
    return deductible + ageDeductable + blindDeductable;
  }

  /// Calculates the deductable for a given year based on tablular information.
  /// Used in derived classes _getDeductable() methods
  /// [knownYears] map of year and single deductable amount.
  /// [ageDeductable] amount to adust if 65 or over
  /// [blindDeductable] amount to adjust if blind
  double calcDeductible(Map<int, double>? knownYears,
      {double ageDeductable = 0, double blindDeductable = 0}) {
    double deductable = calcIndividualDeductbile(
      knownYears,
      ageDeductable: filingSettings.selfInventory.age >= 65 ? ageDeductable : 0,
      blindDeductable: filingSettings.selfInventory.isBlind ? blindDeductable : 0,
    );

    if (filingSettings.filingStatus == FilingStatus.marriedFilingJointly) {
      deductable += calcIndividualDeductbile(
        knownYears,
        ageDeductable: filingSettings.spouseInventory!.age >= 65 ? ageDeductable : 0,
        blindDeductable: filingSettings.spouseInventory!.isBlind ? blindDeductable : 0,
      );
    }
    return deductable;
  }

  void throwStandardStateException() {
    throw Exception(
        'Unsupported Tax Year (${filingSettings.targetYear}) for the State of ${filingSettings.filingState.label})');
  }
} // End StateTax Class


typedef StateTaxFactory = StateTax Function(
    TaxFilingSettings filingSettings);
Map<FilingState, StateTaxFactory> _supportedStates = {
  FilingState.ak: zeroTaxStateFactory,
  FilingState.co: (TaxFilingSettings filingSettings) =>
      ColoradoTax(filingSettings),
  FilingState.fl: zeroTaxStateFactory,
  FilingState.il: (TaxFilingSettings filingSettings) =>
      IllinoisTax(filingSettings),
  FilingState.nh: (TaxFilingSettings filingSettings) =>
      NewHampshireTax(filingSettings),
  FilingState.nv: zeroTaxStateFactory,
  FilingState.oh: (TaxFilingSettings filingSettings) =>
      OhioTax(filingSettings),
  FilingState.sd: zeroTaxStateFactory,
  FilingState.tn: zeroTaxStateFactory,
  FilingState.tx: zeroTaxStateFactory,
  FilingState.wa: (TaxFilingSettings filingSettings) =>
      WashingtonTax(filingSettings),
  FilingState.wy: zeroTaxStateFactory,
  FilingState.other: (TaxFilingSettings filingSettings) =>
      OtherStateTax(filingSettings),
};

StateTax zeroTaxStateFactory(TaxFilingSettings filingSettings) {
  return ZeroStateTax(filingSettings);
}

StateTax todoStateTaxFactory(TaxFilingSettings filingSettings) {
  return TodoStateTax(filingSettings);
}

/// Return the state tax amount per the specified [filingSettings]
double calcStateTax(TaxFilingSettings filingSettings) {
  StateTaxFactory stateTaxFactory =
      _supportedStates[filingSettings.filingState] ?? todoStateTaxFactory;
  StateTax stateTax = stateTaxFactory(filingSettings);
  return stateTax.calcTaxes();
}

/// Return a list of FilingState where that FilingState has tax calculation support
List<FilingState> getSupportedStates() {
  return FilingState.values
      .where((filingState) => _supportedStates[filingState] != null)
      .toList();
}
