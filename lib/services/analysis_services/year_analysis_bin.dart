
import 'analysis_config.dart';
import 'plan_results.dart';
import 'year_analysis.dart';

class YearAnalysisBin {
  final AnalysisConfig analysisConfig;
  final List<YearAnalysis> yearAnalyses = [];

  /// Private Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  YearAnalysisBin({
    required this.analysisConfig,
  }) {
    YearAnalysis? yearlyAnalysis;

    for (int year = analysisConfig.planStartYear;
        year <= analysisConfig.planEndYear;
        year++) {
      yearlyAnalysis = YearAnalysis(
        analysisConfig: analysisConfig,
        targetYear: year,
        prevYearsAnalysis: yearlyAnalysis,
      );
      yearAnalyses.add(yearlyAnalysis);
      if (yearlyAnalysis.monthWhereFundsExausted != null) {
        break;
      }
    }
  }

  /// Returns a list of [YearResult] derived from this [YearAnalysisBin].
  List<YearResult> yearResults() {
    double prevCumulativeTaxes = 0.0;
    List<YearResult> yearResults = [];
    for (final year in yearAnalyses) {
      final YearResult yearResult = year.yearResult(prevCumulativeTaxes: prevCumulativeTaxes);
      prevCumulativeTaxes += yearResult.totalTaxes;
      yearResults.add(yearResult);
    }
    return yearResults;
  }
}