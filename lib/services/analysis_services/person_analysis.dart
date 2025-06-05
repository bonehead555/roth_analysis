import 'package:roth_analysis/services/analysis_services/monthly_plan.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';

/// Manages the analysis status for a specifc persion (self or spouse)
/// in a given year of a given scenario in the plan.
/// [yearlyRmdDistribution] - Amount of IRA distribution taken for RMDs by this person in a given year
/// [yearlyRothConversion] - Amount of IRA distribution taken for Roth conversions by this person in a given year
/// [yearlyIraWithdraws] - Total IRA assets withdrawn including RMDs and ROTH conversions.
/// [simulationIraDistribution] - Amount of IRA distribution that can be used during simulation.
/// [yearlySsIncome] - Social security income earned by this person in a given year.
/// [yearlyInterestIncome] - Interest income earned by this person in a given year.
/// [yearlyDividendIncome] - Dividend income earned by this person in a given year.
/// [yearlyCapitalGainsIncome] - Capital gains income earned by this person in a given year.
/// [yearlyRegularIncome] - Regular income earned by this person in a given year.
/// [yearlySelfEmploymentIncome] - Self employment earned by this person in a given year.
/// [yearlyPensionIncome] - Pension income earned by this person in a given year.
/// [federalMAGI] - Federal Modified Adjusted Gross Income achieved by this person in a given year.
/// [federalIncomeTax] - Federal income tax payable by this person in a given year.
/// [stateIncomeTax] - State income tax payable by this person in a given year.
/// [ficaTaxPaymentPlan] - FICA tax payment plan for this person for a given year.
/// [medicareTaxPaymentPlan] - Medicare tax payment plan for this person for a given year.
/// [irmaaTaxPaymentPlan] - Income-Related Monthly Adjustment payment plan for this person for a given year.
/// [federalIncomeTaxUnderpayment] - Federal income tax underpayement owed by this person in a given year,
/// to be paid in then following year.
/// [stateIncomeTaxUnderpayment] - State income tax underpayement owed by this person in a given year,
/// to be paid in then following year.
class PersonAnalysis {
  double yearlyRmdDistribution = 0;
  double yearlyIraWithdraws = 0;
  double simulationIraDistribution = 0;
  double yearlySsIncome = 0;
  double yearlyInterestIncome = 0;
  double yearlyDividendIncome = 0;
  double yearlyCapitalGainsIncome = 0;
  double yearlyRegularIncome = 0;
  double yearlySelfEmploymentIncome = 0;
  double yearlyPensionIncome = 0;
  double federalMAGI = 0;
  double federalIncomeTax = 0;
  double stateIncomeTax = 0;
  double localIncomeTax = 0;
  MonthlyPlan rothConversionPlan = MonthlyPlan();
  MonthlyPlan ficaTaxPaymentPlan = MonthlyPlan();
  MonthlyPlan medicareTaxPaymentPlan = MonthlyPlan();
  MonthlyPlan irmaaTaxPaymentPlan = MonthlyPlan();
  double federalIncomeTaxUnderpayment = 0;
  double stateIncomeTaxUnderpayment = 0;
  double localIncomeTaxUnderpayment = 0;

  /// Returns the yearly ROTH conversion to be executed by this person.
  double get yearlyRothConversion => rothConversionPlan.yearlyAmount;

  /// Returns the monthly ROTH conversion to be executed by this person.
  double monthlyRothConversion(int month) =>
      rothConversionPlan.getMonthlyAmount(month);

  /// Returns the yearly FICA tax to be payed by this person.
  double get yearlyFicaTax => ficaTaxPaymentPlan.yearlyAmount;

  /// Returns the monthly FICA tax to be payed by this person for specified [month].
  double monthlyFicaTax(int month) =>
      ficaTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the yearly Medicare tax to be payed by this person.
  double get yearlyMedicareTax => medicareTaxPaymentPlan.yearlyAmount;

  /// Returns the monthly Medicare tax to be payed by this person for specified [month].
  double monthlyMedicareTax(int month) =>
      medicareTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the yearly IRMAA tax to be payed by this person.
  double get yearlyIrmaaTax => irmaaTaxPaymentPlan.yearlyAmount;

  /// Returns the monthly IRMAA tax to be payed by this person for specified [month].
  double monthlyIrmaaTax(int month) =>
      irmaaTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the total iraDistribution (RMD, Roth Conversion, other) taken by this person in a given year
  double get yearlyIraDistributions =>
      yearlyIraWithdraws + simulationIraDistribution;

  /// Returns a [PersonResult] derived from this [PersonAnalysis].
  PersonResult personResult() {
    return PersonResult(
      rmdDistribution: yearlyRmdDistribution,
      rothConversion: yearlyRothConversion,
      otherIraDistribution: simulationIraDistribution,
      ssIncome: yearlySsIncome,
      interestIncome: yearlyInterestIncome,
      dividendIncome: yearlyDividendIncome,
      capitalGainsIncome: yearlyCapitalGainsIncome,
      regularIncome: yearlyRegularIncome,
      selfEmploymentIncome: yearlySelfEmploymentIncome,
      pensionIncome: yearlyPensionIncome,
      federalMAGI: federalMAGI,
      federalIncomeTax: federalIncomeTax,
      stateIncomeTax: stateIncomeTax,
      localIncomeTax: localIncomeTax,
      ficaTax: yearlyFicaTax,
      medicareTax: yearlyMedicareTax,
      irmaaTax: yearlyIrmaaTax,
    );
  }
}
