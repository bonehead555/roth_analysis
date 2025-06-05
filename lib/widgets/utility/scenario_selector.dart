import 'package:flutter/material.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';

class ScenarioSelector extends StatefulWidget {
  const ScenarioSelector({
    super.key,
    required this.activeScenario,
    required this.scenarioResults,
    required this.onSelected,
  });
  final ScenarioResult? activeScenario;
  final List<ScenarioResult> scenarioResults;
  final Function(ScenarioResult) onSelected;

  @override
  State<ScenarioSelector> createState() => _ScenarioSelectorState();

  /// Returrns a valid scenario to use as a selected scenario.
  /// * [scenarioResults] - List of currently valid [ScenarioResult].
  /// * [selectedScenario] - Scenario to validate.
  /// 
  /// Note: If [selectedScenario] does not match one of the scenarios in the provided [scenarioResults] (by id)
  /// the firs [ScenarioResult] in [scenarioResults] is returned.
  static ScenarioResult validateScenarioResult(
      List<ScenarioResult> scenarioResults, ScenarioResult? selectedScenario) {
    if (selectedScenario == null) {
      return scenarioResults[0];
    }
    return scenarioResults.firstWhere(
        (scenarioResult) => scenarioResult.id == selectedScenario.id,
        orElse: () => scenarioResults[0]);
  }
}

class _ScenarioSelectorState extends State<ScenarioSelector> {
  final TextEditingController scenarioController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Select Scenario',
      child: Row(
        children: [
          Text(
            'Scenario:  ',
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          DropdownMenu<ScenarioResult>(
            initialSelection: widget.activeScenario,
            controller: scenarioController,
            textStyle: Theme.of(context).textTheme.labelLarge,
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              isDense: true,
            ),
            dropdownMenuEntries: [
              for (final scenarioResult in widget.scenarioResults)
                DropdownMenuEntry<ScenarioResult>(
                  value: scenarioResult,
                  label: scenarioResult.scenarioName,
                ),
            ],
            onSelected: (scenarioResult) =>
                selectScenarioResult(scenarioResult),
          ),
        ],
      ),
    );
  }

  void selectScenarioResult(ScenarioResult? scenarioResult) {
    if (scenarioResult != null) {
      widget.onSelected(scenarioResult);
    }
  }
}
