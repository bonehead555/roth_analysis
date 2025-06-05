import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

import 'scenario_analysis_bin.dart';

/// Manages the analysis and analysis results for the full Roth Conversion plan.
/// [analysisConfig] - holds the configuratio information for the plan analysis
/// [_scenarioAnalysisBin] - holds the anlysis for every scenario in the plan.
class PlanAnalysis {
  final AnalysisConfig analysisConfig;
  late ScenarioAnalysisBin _scenarioAnalysisBin;

  /// Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  PlanAnalysis({
    required this.analysisConfig,
  }) {
    CostOfLiving.setColaPercent(analysisConfig.planInfo.cola * 100.0);
    _scenarioAnalysisBin = ScenarioAnalysisBin(analysisConfig);
  }

  /// Returns a list of [PlanResult] derived from this [PlanAnalysis].
  PlanResult get planResults {
    PlanResult planResults = PlanResult(analysisConfig, _scenarioAnalysisBin.scenarioResults());
    return planResults;
  }
}
