import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

import 'monthly_plan.dart';

/// Manages the analysis and analysis results for a single income stream
/// for a given year of a given scenario specified in the plan.
/// [analysisConfig] - holds the configuration information for the plan analysis
/// [incomeInfo] - holds the as configured income information for this income stream
/// [ownerInfo] - holds person information for the owner of the income stream
class IncomeAnalysis {
  final AnalysisConfig analysisConfig;
  final IncomeInfo incomeInfo;
  late PersonInfo ownerInfo;
  final int _targetYear;
  late MonthlyPlan _incomeDistributionPlan;

  /// Private Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [incomeInfo] - provides the as configured income stream informstion for this income stream
  /// [targetYear] - provides the target year that the income stream is to be calculated for.
  IncomeAnalysis._({
    required this.analysisConfig,
    required this.incomeInfo,
    required int targetYear,
  })  : _targetYear = targetYear,
        ownerInfo = analysisConfig.personFromOwnerType(incomeInfo.owner) {
    _incomeDistributionPlan = _createIncomeDistributionPlan();
  }

  /// Constructor used to create [IncomeAnalysis] for the first year of a plan.
  /// Creating it from [IncomeInfo]
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [incomeInfo] - provides the as configured income information for this income stream
  /// [targetYear] - provides the target year that the income stream is to be calculated for.
  factory IncomeAnalysis.fromIncomeInfo({
    required AnalysisConfig analysisConfig,
    required IncomeInfo incomeInfo,
    required int targetYear,
  }) {
    var incomeAnalysis = IncomeAnalysis._(
      analysisConfig: analysisConfig,
      incomeInfo: incomeInfo,
      targetYear: targetYear,
    );
    return incomeAnalysis;
  }

  /// Constructor used to create [IncomeAnalysis] for the year 2 though n of a plan.
  /// Creating it from the previous years [IncomeAnalysis]
  /// [previousIncomeAnalysis] - provides previous years [IncomeAnalysis] for this income stream
  factory IncomeAnalysis.fromPrevIncomeAnalysis(
      {required IncomeAnalysis previousIncomeAnalysis}) {
    var incomeAnalysis = IncomeAnalysis._(
      analysisConfig: previousIncomeAnalysis.analysisConfig,
      incomeInfo: previousIncomeAnalysis.incomeInfo,
      targetYear: previousIncomeAnalysis._targetYear + 1,
    );
    return incomeAnalysis;
  }

  /// Returns ID of Income Stream
  String get id => incomeInfo.id;

  /// Returns type of income stream.
  IncomeType get type => incomeInfo.type;

  /// Returns owner type of income stream.
  OwnerType get ownerType => incomeInfo.owner;

  /// Returns the year the income stream should start.
  DateTime get startDate => incomeInfo.startDate!;

  /// Returns the year the income stream should end.
  DateTime get endDate => type == IncomeType.socialSecurity
      ? analysisConfig.planInfo.planEndDate!
      : incomeInfo.endDate!;

  /// Returns the target year for the income anlysis.
  int get targetYear => _targetYear;

  /// Returns the starting month for the income
  int get startMonth => _incomeDistributionPlan.beginMonth;

  /// Returns the starting month for the income
  int get finalMonth => _incomeDistributionPlan.finalMonth;

  /// Returns estimated / projected remaining income for this income stream begining at [month].
  /// If [month] is omitted, income is for the full year.
  double remainingIncome({int month = 1}) =>
      _incomeDistributionPlan.remainingBalance(month);

  /// Returns estimated montly income for the specifiled [month]
  double monthlyIncome(int month) =>
      _incomeDistributionPlan.getMonthlyAmount(month);

  /// Estimates the gross income and returns a monthly distribution plan for the projected yearly income.
  /// Note: Income is adjusted for time value of $$$ (when appropriate).
  MonthlyPlan _createIncomeDistributionPlan() {
    int beginMonth = (startDate.year == _targetYear) ? startDate.month : 1;
    int finalMonth = (endDate.year == _targetYear) ? endDate.month : 12;
    double grossIncome = 0.0;

    if ((startDate.year <= _targetYear) && (endDate.year >= _targetYear)) {
      if (type == IncomeType.pension) {
        // Pension income typically does not have any cost-of-living increase.
        grossIncome = incomeInfo.yearlyIncome;
      } else {
        grossIncome = adjustForTime(
            valueToAdjust: incomeInfo.yearlyIncome,
            toYear: _targetYear,
            fromYear: startDate.year);
      }
    }
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(grossIncome,
        beginMonth: beginMonth, finalMonth: finalMonth);
    return monthlyPlan;
  }
}
