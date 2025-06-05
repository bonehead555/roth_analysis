import 'package:roth_analysis/models/enums/color_option.dart';
import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/services/analysis_services/transaction_log.dart';

/// Manages the analysis results for the full Roth Conversion plan.
/// * [analysisConfig] - Analysis Configuration used to build these results.
/// * [scenarioResults] - The analysis results for every scenario in the plan.
class PlanResult {
  final AnalysisConfig analysisConfig;
  final List<ScenarioResult> scenarioResults;

  /// Creates analysis results for the full Roth Conversion plan.
  /// * [analysisConfig] - Analysis Configuration used to build these results.
  /// * [scenarioResults] - The analysis results for every scenario in the plan.
  PlanResult(this.analysisConfig, this.scenarioResults);
}

/// Manages the analysis results for one scenario of the overall plan.
/// * [id] - ID of the corresponsing ScenarioInfo.
/// * [scenarioName] - Name of the scenario.
/// * [colorOption] - Color of the scenario.
/// * [yearlyResults] - Provides a list of each year's results.
/// * [transactionLog] - Account transaction log for this scenario
class ScenarioResult {
  final String id;
  final String scenarioName;
  final ColorOption colorOption;
  final List<YearResult> yearlyResults;
  final TransactionLog transactionLog;
  ScenarioResult(this.id, this.scenarioName, this.colorOption, this.yearlyResults, this.transactionLog);
}

/// Manages the analysis results for one year of one scenario of the overall plan.
/// [targetYear] - The year for which the reuslts apply.
/// [expenses] - The year's expenses for both the self and spouse (if married).
/// [savingsAssets] - Total year-end savings account assets.
/// [brokerageAssets] - Total year-end brokerage account assets.
/// [iraAssets] - Total year-end IRA account assets.
/// [rothAssets] - Total year-end Roth account assets.
/// [totalAssets] - Total assets including savings brokerage, IRA, and Roth assets.
/// [accountBalances] - List of availble balances in all accounts.
/// [selfResult] - The year's analysis results for the main participant.
/// [spouseResult] - The year's analysis results for the main participant's spouse.
class YearResult {
  final int targetYear;
  late double totalTaxes;
  late double cumulativeTaxes;
  final double expenses;
  final double totalIncome;
  final double savingsAssets;
  final double brokerageAssets;
  final double iraAssets;
  final double rothAssets;
  late double totalAssets;
  final List<double> accountBalances;
  final PersonResult selfResult;
  final PersonResult spouseResult;

  /// Default constructor
  /// [targetYear] - The year for which the reuslts apply.
  YearResult({
    required this.targetYear,
    required this.expenses,
    required this.totalIncome,
    required this.savingsAssets,
    required this.brokerageAssets,
    required this.iraAssets,
    required this.rothAssets,
    required this.accountBalances,
    required this.selfResult,
    required this.spouseResult,
    required double prevCumulativeTaxes,
  }) {
    totalTaxes = federalIncomeTax +
        stateIncomeTax +
        localIncomeTax +
        ficaTax +
        medicareTax +
        irmaaTax;
    totalAssets = savingsAssets + brokerageAssets + iraAssets + rothAssets;
    cumulativeTaxes = prevCumulativeTaxes + totalTaxes;
  }

  /// Returns the yearly RMD / income distribution for both the self and spouse (if married).
  double get rmdDistribution =>
      selfResult.rmdDistribution + spouseResult.rmdDistribution;
  double get rmdIncome =>
      selfResult.rmdDistribution + spouseResult.rmdDistribution;

  /// Returns the end-of-year taxable asset balance.
  double get taxableAssets => savingsAssets + brokerageAssets;

  /// Returns the yearly ROTH conversions for both the self and spouse (if married).
  double get rothConversion =>
      selfResult.rothConversion + spouseResult.rothConversion;

  /// Returns tother IRA distributions for both the self and spouse (if married).
  double get otherIraDistribution =>
      selfResult.otherIraDistribution + spouseResult.otherIraDistribution;

  /// Returns the yearly total income for both the self and spouse (if married).
  double get ssIncome => selfResult.ssIncome + spouseResult.ssIncome;

  /// Returns the yearly interest income for both the self and spouse (if married).
  double get interestIncome =>
      selfResult.interestIncome + spouseResult.interestIncome;

  /// Returns the yearly dividend income for both the self and spouse (if married).
  double get dividendIncome =>
      selfResult.dividendIncome + spouseResult.dividendIncome;

  /// Returns the yearly capital gains income for both the self and spouse (if married).
  double get capitalGainsIncome =>
      selfResult.capitalGainsIncome + spouseResult.capitalGainsIncome;

  /// Returns the yearly regular income for both the self and spouse (if married).
  double get regularIncome =>
      selfResult.regularIncome + spouseResult.regularIncome;

  /// Returns the yearly self-employment income for both the self and spouse (if married).
  double get selfEmploymentIncome =>
      selfResult.selfEmploymentIncome + spouseResult.selfEmploymentIncome;

  /// Returns the yearly pension income for both the self and spouse (if married).
  double get pensionIncome =>
      selfResult.pensionIncome + spouseResult.pensionIncome;

  /// Returns the yearly federal MAGI for both the self and spouse (if married).
  double get federalMAGI => selfResult.federalMAGI + spouseResult.federalMAGI;

  /// Returns the yearly federal income tax for both the self and spouse (if married).
  double get federalIncomeTax =>
      selfResult.federalIncomeTax + spouseResult.federalIncomeTax;

  /// Returns the yearly state income tax for both the self and spouse (if married).
  double get stateIncomeTax =>
      selfResult.stateIncomeTax + spouseResult.stateIncomeTax;

  /// Returns the yearly local income tax for both the self and spouse (if married).
  double get localIncomeTax =>
      selfResult.localIncomeTax + spouseResult.localIncomeTax;

  /// Returns the yearly fica tax for both the self and spouse (if married).
  double get ficaTax => selfResult.ficaTax + spouseResult.ficaTax;

  /// Returns the yearly medicare income tax for both the self and spouse (if married).
  double get medicareTax => selfResult.medicareTax + spouseResult.medicareTax;

  /// Returns the yearly IRMAA tax for both the self and spouse (if married).
  double get irmaaTax => selfResult.irmaaTax + spouseResult.irmaaTax;

  /// Returns the yearly iraDistributions for both the self and spouse (if married).
  double get iraDistributions =>
      selfResult.iraDistributions + spouseResult.iraDistributions;
}

/// Manages the analysis results for a specifc persion (self or spouse)
/// in a given year of a given scenario in the plan.
/// [rmdDistribution] - Amount of IRA distribution taken for RMDs by this person in a given year
/// [rothConversion] - Amount of IRA distribution taken for Roth conversions by this person in a given year
/// [otherIraDistribution] - Amount of IRA distribution taken for other/needed income by this person in a given year
/// [ssIncome] - Social security income earned by this person in a given year.
/// [interestIncome] - Interest income earned by this person in a given year.
/// [dividendIncome] - Dividend income earned by this person in a given year.
/// [capitalGainsIncome] - Capital gains income earned by this person in a given year.
/// [regularIncome] - Regular income earned by this person in a given year.
/// [selfEmploymentIncome] - Self employment earned by this person in a given year.
/// [pensionIncome] - Pension income earned by this person in a given year.
/// [federalMAGI] - Federal Modified Adjusted Gross Income achieved by this person in a given year.
/// [federalIncomeTax] - Federal income tax payable by this person in a given year.
/// [stateIncomeTax] - State income tax payable by this person in a given year.
/// [ficaTax] - FICA tax payable by this person in a given year.
/// [medicareTax] - Medicare tax payable by this person in a given year.
/// [irmaaTax] - Income-Related Monthly Adjustment Amount payable by this person in a given year.
/// [federalIncomeTaxUnderpayment] - Federal income tax underpayement owed by this person in a given year,
/// to be paid in then following year.
/// [stateIncomeTaxUnderpayment] - State income tax underpayement owed by this person in a given year,
/// to be paid in then following year.
/// [localIncomeTaxUnderpayment] - Local income tax underpayement owed by this person in a given year,
/// to be paid in then following year.
class PersonResult {
  final double rmdDistribution;
  final double rothConversion;
  final double otherIraDistribution;
  final double ssIncome;
  final double interestIncome;
  final double dividendIncome;
  final double capitalGainsIncome;
  final double regularIncome;
  final double selfEmploymentIncome;
  final double pensionIncome;
  final double federalMAGI;
  final double federalIncomeTax;
  final double stateIncomeTax;
  final double localIncomeTax;
  final double ficaTax;
  final double medicareTax;
  final double irmaaTax;

  PersonResult({
    required this.rmdDistribution,
    required this.rothConversion,
    required this.otherIraDistribution,
    required this.ssIncome,
    required this.interestIncome,
    required this.dividendIncome,
    required this.capitalGainsIncome,
    required this.regularIncome,
    required this.selfEmploymentIncome,
    required this.pensionIncome,
    required this.federalMAGI,
    required this.federalIncomeTax,
    required this.stateIncomeTax,
    required this.localIncomeTax,
    required this.ficaTax,
    required this.medicareTax,
    required this.irmaaTax,
  });

  /// Returns the total iraDistribution (RMD, Roth Conversion, other) taken by this person in a given year
  double get iraDistributions =>
      rmdDistribution + rothConversion + otherIraDistribution;
}
