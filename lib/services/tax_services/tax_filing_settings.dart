import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';

/// Record that manages information about the person filing the taxes.
/// [age] - persons age
/// [isBlind] - whether the person is blind (or not).
/// [ssIncome] - Person's social security income (not taxable SS income)
/// [iraDistributions] - Person's IRA distributions
/// [interestIncome] - Person's interest income
/// [dividendIncome] - Person's dividend income
/// [capitalGainsIncome] - Person's capital gains income
/// [regularIncome] Person's regular income, e.g., wages
/// [selfEmploymentIncome] - Person's self-employment income
/// [pensionIncome] 
interface class PersonInventory {
  PersonInventory({
    required this.age,
    this.isBlind=false,
    this.ssIncome=0,
    this.iraDistributions=0,
    this.interestIncome=0,
    this.dividendIncome=0,
    this.capitalGainsIncome=0,
    this.regularIncome=0,
    this.selfEmploymentIncome=0,
    this.pensionIncome=0,
    this.prevPrevYearsMAGI=0,
});
  final int age;
  final bool isBlind;
  double ssIncome;
  double iraDistributions;
  double interestIncome;
  double dividendIncome;
  double capitalGainsIncome;
  double regularIncome;
  double selfEmploymentIncome;
  double pensionIncome;
  double prevPrevYearsMAGI;

  PersonInventory copyWith({
    int? age,
    bool? isBlind,
    double? ssIncome,
    double? iraDistributions,
    double? interestIncome,
    double? dividendIncome,
    double? capitalGainsIncome,
    double? regularIncome,
    double? selfEmploymentIncome,
    double? pensionIncome,
    double? prevPrevYearsMAGI,
  }) {
  return PersonInventory(
    age: age ?? this.age,
    isBlind: isBlind ?? this.isBlind,
    ssIncome: ssIncome ?? this.ssIncome,
    iraDistributions: iraDistributions ?? this.iraDistributions,
    interestIncome: interestIncome ?? this.interestIncome,
    dividendIncome: dividendIncome ?? this.dividendIncome,
    capitalGainsIncome: capitalGainsIncome ?? this.capitalGainsIncome,
    regularIncome: regularIncome ?? this.regularIncome,
    selfEmploymentIncome: selfEmploymentIncome ?? this.selfEmploymentIncome,
    pensionIncome: pensionIncome ?? this.pensionIncome,
    prevPrevYearsMAGI: prevPrevYearsMAGI ?? this.prevPrevYearsMAGI,
    );
  }
}

interface class TaxFilingSettings {
  TaxFilingSettings({
    required this.targetYear,
    required this.filingStatus,
    required this.filingState,
    this.stateTaxPercentage = 0.0,
    this.stateStandardDeduction = 0.0,
    this.stateTaxesSS = false,
    this.stateTaxesRetirementIncome = false,
    this.localTaxPercentage = 0.0,
    required this.selfInventory,
    this.spouseInventory,
  });
  final int targetYear;
  final FilingStatus filingStatus;
  final FilingState filingState;
  final double stateTaxPercentage;
  final double stateStandardDeduction;
  final bool stateTaxesSS ;
  final bool stateTaxesRetirementIncome;
  final double localTaxPercentage;
  final PersonInventory selfInventory;
  final PersonInventory? spouseInventory;

  TaxFilingSettings copyWith({
    int? targetYear,
    FilingStatus? filingStatus,
    FilingState? filingState,
    double? stateTaxPercentage,
    double? stateStandardDeduction,
    bool? stateTaxesSS,
    bool? stateTaxesRetirementIncome,
    double? localTaxPercentage,
    PersonInventory? selfInventory,
    PersonInventory? spouseInventory,
  }) {
    return TaxFilingSettings(
      targetYear: targetYear ?? this.targetYear,
      filingStatus: filingStatus ?? this.filingStatus,
      filingState: filingState ?? this.filingState,
      stateTaxPercentage: stateTaxPercentage ?? this.stateTaxPercentage,
      stateStandardDeduction: stateStandardDeduction ?? this.stateStandardDeduction,
      stateTaxesSS: stateTaxesSS ?? this.stateTaxesSS,
      stateTaxesRetirementIncome: stateTaxesRetirementIncome ?? this.stateTaxesRetirementIncome,
      localTaxPercentage: localTaxPercentage ?? this.localTaxPercentage,
      selfInventory: selfInventory ?? this.selfInventory,
      spouseInventory: spouseInventory ?? this.spouseInventory,

    );
  }
}
