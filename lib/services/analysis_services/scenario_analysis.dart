import 'package:roth_analysis/services/analysis_services/plan_results.dart';

import 'analysis_config.dart';
import 'year_analysis_bin.dart';

/// Manages the analysis of one speciifc scenario specified in the plan.
/// [analysisConfig] - The configuration information for the plan analysis
/// [yearAnalysisBin] - A collection managing the year over year analysis for the scenario,
/// one for each year specified in the plan
class ScenarioAnalysis {
  final AnalysisConfig analysisConfig;
  final YearAnalysisBin yearAnalysisBin;

  /// Constructor
  /// [analysisConfig] - The configuration information for the plan analysis.
  ScenarioAnalysis(this.analysisConfig)
      : yearAnalysisBin = YearAnalysisBin(analysisConfig: analysisConfig);

  /// Returns a [ScenarioResult] derived from this [ScenarioAnalysis].
  ScenarioResult scenarioResult() {
    return ScenarioResult(
      analysisConfig.currentScenario.id,
      analysisConfig.currentScenario.name,
      analysisConfig.currentScenario.colorOption,
      yearAnalysisBin.yearResults(),
      analysisConfig.transactionLog,
    );
  }
}
