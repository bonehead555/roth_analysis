import 'package:roth_analysis/services/analysis_services/account_analysis.dart';
import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';

import 'income_analysis.dart';
import 'transaction_log.dart';

/// Class wraps a list of [IncomeAnalysis] object adding management of several useful
/// fileds and methods that oprate on the collectgion.
/// [_analysisConfig] - Configuration information for the plan analysis
/// [_targetYear] - the target year of the analysis
/// [_incomeAnalyses] - List of income analysis to manage
class IncomeAnalysisBin {
  final AnalysisConfig _analysisConfig;
  final int _targetYear;
  final List<IncomeAnalysis> _incomeAnalyses;

  /// Private Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [targetYear] - the target year of the analysis
  /// [incomeAnalyses] - provides the list of income analysis to manage
  IncomeAnalysisBin._({
    required AnalysisConfig analysisConfig,
    required int targetYear,
    required List<IncomeAnalysis> incomeAnalyses,
  })  : _incomeAnalyses = incomeAnalyses,
        _targetYear = targetYear,
        _analysisConfig = analysisConfig;

  /// Constructor used to create an [IncomeAnalysisBin] for the first year of a plan.
  /// From [IncomeInfo], for the start year,
  /// an inital [IncomeAnalysis] will be created for every income stream in the bin.
  factory IncomeAnalysisBin.fromIncomeInfo({
    required AnalysisConfig analysisConfig,
    required int targerYear,
  }) {
    List<IncomeAnalysis> incomeAnalyses = [];
    for (var incomeInfo in analysisConfig.incomeInfos) {
      incomeAnalyses.add(IncomeAnalysis.fromIncomeInfo(
        analysisConfig: analysisConfig,
        incomeInfo: incomeInfo,
        targetYear: analysisConfig.planStartYear,
      ));
    }
    var incomeAnalysisBin = IncomeAnalysisBin._(
        analysisConfig: analysisConfig,
        targetYear: targerYear,
        incomeAnalyses: incomeAnalyses);
    return incomeAnalysisBin;
  }

  /// Constructor used to create an [IncomeAnalysisBin] for the year 2 though n of a plan.
  /// [prevIncomeAnalysisBin] - provides previous years [IncomeAnalysisBin]
  /// From [prevIncomeAnalysisBin], for a subsequent year,
  /// an inital [AccountAnalysis] will be created for every account in the bin.
  factory IncomeAnalysisBin.fromPrevIncomeAnalyisBin({
    required IncomeAnalysisBin prevIncomeAnalysisBin,
    required int targetYear,
  }) {
    List<IncomeAnalysis> incomeAnalyses = [];
    for (var prevIncomeAnalysis in prevIncomeAnalysisBin._incomeAnalyses) {
      incomeAnalyses.add(IncomeAnalysis.fromPrevIncomeAnalysis(
        previousIncomeAnalysis: prevIncomeAnalysis,
      ));
    }
    var incomeAnalysisBin = IncomeAnalysisBin._(
      analysisConfig: prevIncomeAnalysisBin._analysisConfig,
      targetYear: targetYear,
      incomeAnalyses: incomeAnalyses,
    );
    return incomeAnalysisBin;
  }

  /// Returns the target year for the income analysis.
  int get targetYear => _targetYear;

  /// Returns the [TransactionLog] to log account transactions within.
  TransactionLog get transactionLog => _analysisConfig.transactionLog;

  void analysisPhase1() {}

  /// Estimates/Returns the remaining yearly income for the  specified [ownerType], [incomeType] and [month].
  /// If [month] is omitted, the full year's income estimate is returned.
  double estimateRemainingIncomeByOwnerAndIncomeType(
      {required OwnerType ownerType,
      required IncomeType incomeType,
      int month = 1}) {
    double result = 0.0;
    for (final incomeAnalysis in _incomeAnalyses) {
      if (incomeAnalysis.ownerType != ownerType ||
          incomeAnalysis.type != incomeType) {
        continue;
      }
      result += incomeAnalysis.remainingIncome(month: month);
    }
    return result;
  }

  /// Returns the month range that income is earned for the [targetYear]
  (int startMonth, int finalMonth) getIncomeMonthRange(OwnerType ownerType) {
    int startMonth = 1;
    int finalMonth = 12;
    for (final incomeAnalysis in _incomeAnalyses) {
      if (incomeAnalysis.ownerType != ownerType ||
          !(incomeAnalysis.type == IncomeType.employment ||
              incomeAnalysis.type == IncomeType.selfEmployment)) {
        continue;
      }
      final int incomeStartMonth = incomeAnalysis.startMonth;
      final int incomeFinalMonth = incomeAnalysis.finalMonth;
      if (incomeStartMonth > startMonth) {
        startMonth = incomeStartMonth;
      }
      if (incomeFinalMonth < finalMonth) {
        finalMonth = incomeFinalMonth;
      }
    }
    return (startMonth, finalMonth);
  }

  /// Estimates/Returns the reamining income starting from [month] (for all income streams).
  /// If [month] is omitted, the full year's income estimate is returned.
  double remainingIncome({int month = 1}) {
    double amount = 0.0;
    for (IncomeAnalysis incomeAnalysis in _incomeAnalyses) {
      amount = incomeAnalysis.remainingIncome(month: month);
    }
    return amount;
  }

  /// For all income streams, depost monthly income for specified [month] to specified [account]
  void monthlyIncomeToAccount(AccountAnalysis account, int month) {
    for (IncomeAnalysis incomeAnalysis in _incomeAnalyses) {
      var amount = incomeAnalysis.monthlyIncome(month);
      var memo =
          'Monthly ${incomeAnalysis.incomeInfo.type.label} income for ${incomeAnalysis.ownerType.label}';
      account.deposit(amount, month, memo);
    }
  }
}
