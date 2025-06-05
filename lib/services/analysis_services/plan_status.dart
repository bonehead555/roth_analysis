import 'monthly_plan.dart';
import 'person_analysis.dart';

/// Manages the status of the analysis of the full Roth Conversion Plan.
/// [scenarioAnalysisBin] - Holds the analysis status for every scenario in the plan.
abstract class PlanStatus {
  ScenarioStatus get scenarioStatus;
}

/// Typedef for a list of entries, each containing the analysis status of one Scenario.
typedef ScenarioStatuses = List<ScenarioStatus>;

/// Manages the analysis status for one scenario of the overall plan.
/// [yearlyStatus] - Holds the analysis status for every year analysed in the scenario.
abstract class ScenarioStatus {
  YearlyStatuses get yearlyStatueses;
}

/// Typedef for a list of entries, each containing the analysis status of one year's analysis.
typedef YearlyStatuses = List<YearlyStatus>;

/// Manages the analysis status for one year of one scenario of the overall plan.
/// [targetYear] - The year for which the status applies.
/// [expenses] - Yearly expense needs for both the self and spouse (if married).
/// [selfAnalysis] - Analysis status for the main participant in the plan,
/// for the given year in the given scenario.
/// [spouseAnalysis] - Analysis status for the main participant's spouse in the plan,
/// for the given year in the given scenario.
class YearlyStatus {
  final int targetYear;
  late double expenses;
  double plannedRothConversionAmount = 0;
  final MonthlyPlan ssIncomeDistributionPlan = MonthlyPlan();
  final MonthlyPlan iraDistributionPlan = MonthlyPlan();
  final MonthlyPlan federalIncomeTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan stateIncomeTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan localIncomeTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan ficaTaxPaymenyPlan = MonthlyPlan();
  final MonthlyPlan medicareTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan irmaaTaxPaymentPlan = MonthlyPlan();

  final MonthlyPlan incomeDistributionPlan = MonthlyPlan();

  late PersonAnalysis selfAnalysis;
  late PersonAnalysis spouseAnalysis;

  /// Default constructor
  /// [targetYear] - The year for which the reuslts apply.
  YearlyStatus({required this.targetYear});

  /// Returns the yearly total income for both the self and spouse (if married).
  double get ssIncome => ssIncomeDistributionPlan.yearlyAmount;

  /// Returns the yearly iraDistributions for both the self and spouse (if married).
  double get iraDistributions =>
      selfAnalysis.yearlyIraDistributions + spouseAnalysis.yearlyIraDistributions;

  /// Returns the yearly interest income for both the self and spouse (if married).
  double get interestIncome =>
      selfAnalysis.yearlyInterestIncome + spouseAnalysis.yearlyInterestIncome;

  /// Returns the yearly dividend income for both the self and spouse (if married).
  double get dividendIncome =>
      selfAnalysis.yearlyDividendIncome + spouseAnalysis.yearlyDividendIncome;

  /// Returns the yearly capital gains income for both the self and spouse (if married).
  double get capitalGainsIncome =>
      selfAnalysis.yearlyCapitalGainsIncome + spouseAnalysis.yearlyCapitalGainsIncome;

  /// Returns the yearly RMD / income distribution for both the self and spouse (if married).
   double get rmdDistribution => selfAnalysis.yearlyRmdDistribution + spouseAnalysis.yearlyRmdDistribution;
   double get rmdIncome => rmdDistribution;

  /// Returns the yearly regular income for both the self and spouse (if married).
  double get regularIncome =>
      selfAnalysis.yearlyRegularIncome + spouseAnalysis.yearlyRegularIncome;

  /// Returns the yearly self-employment income for both the self and spouse (if married).
  double get selfEmploymentIncome =>
      selfAnalysis.yearlySelfEmploymentIncome + spouseAnalysis.yearlySelfEmploymentIncome;

  /// Returns the yearly pension income for both the self and spouse (if married).
  double get pensionIncome =>
      selfAnalysis.yearlyPensionIncome + spouseAnalysis.yearlyPensionIncome;

  /// Returns the yearly federal MAGI for both the self and spouse (if married).
  double get federalMAGI => selfAnalysis.federalMAGI + spouseAnalysis.federalMAGI;

  /// Returns the yearly federal income tax for both the self and spouse (if married).
  double get federalIncomeTax => federalIncomeTaxPaymentPlan.yearlyAmount;

  /// Returns the yearly state income tax for both the self and spouse (if married).
  double get stateIncomeTax => stateIncomeTaxPaymentPlan.yearlyAmount;

  /// Returns the yearly local income tax for both the self and spouse (if married).
  double get localIncomeTax => localIncomeTaxPaymentPlan.yearlyAmount;

  /// Returns the yearly fica tax for both the self and spouse (if married).
  double get ficaTax => selfAnalysis.yearlyFicaTax + spouseAnalysis.yearlyFicaTax;

  /// Returns the yearly medicare income tax for both the self and spouse (if married).
  double get medicareTax => selfAnalysis.yearlyMedicareTax + spouseAnalysis.yearlyMedicareTax;

  /// Returns the yearly IRMAA tax for both the self and spouse (if married).
  double get irmaaTax => selfAnalysis.yearlyIrmaaTax + spouseAnalysis.yearlyIrmaaTax;

  /// Returns the yearly federal income tax underpayment for both the self and spouse (if married).
  double get federalIncomeTaxUnderpayment =>
      selfAnalysis.federalIncomeTaxUnderpayment +
      spouseAnalysis.federalIncomeTaxUnderpayment;

  /// Returns the yearly stae income tax underpayment for both the self and spouse (if married).
  double get stateIncomeTaxUnderpayment =>
      selfAnalysis.stateIncomeTaxUnderpayment +
      spouseAnalysis.stateIncomeTaxUnderpayment;

  /// Returns the total taxes from all taxing agencies, e.g., Federal, State, Local, FICA, Medicare, IRMAA
  double get totalTaxes =>
      federalIncomeTax +
      stateIncomeTax +
      localIncomeTax +
      ficaTax +
      medicareTax +
      irmaaTax;

  /// Returns the sum of yearly expenses and yearly taxes
  double get totalExpenses => expenses + totalTaxes;
}




