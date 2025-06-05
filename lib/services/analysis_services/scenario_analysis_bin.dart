import 'analysis_config.dart';
import 'plan_results.dart';
import 'scenario_analysis.dart';

/// Manages the analysis for all scenarios specified in the plan.
/// [scenarioAnalyses] - A list of scenario analysis objects, one for each scenario specified in the plan
class ScenarioAnalysisBin {
  final List<ScenarioAnalysis> scenarioAnalyses = [];

  /// Constructor
  /// [analysisConfig] - The configuratio information for the plan analysis
  ScenarioAnalysisBin(AnalysisConfig analysisConfig) {
    for (final scenarioInfo in analysisConfig.scenarioInfos) {
      // Create a SceanrioAnalysis object with a copy of an AnalysisConfig pinned to the specific scenario
      // Add that ScenarioAnalysis to the class' list of ScenarioAnalysis objects
      scenarioAnalyses.add(ScenarioAnalysis(
        analysisConfig.copyWithCurrentScenario(scenarioInfo),
      ));
    }
  }

  /// Returns a list of [ScenarioResult] derived from this [ScenarioAnalysisBin].
  List<ScenarioResult> scenarioResults() {
    List<ScenarioResult> scenarioResults = [];
    for (final scenarioAnalysis in scenarioAnalyses) {
      scenarioResults.add(scenarioAnalysis.scenarioResult());
    }
    return scenarioResults;
  }
 }