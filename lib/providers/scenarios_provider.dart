import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/enums/color_option.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';

typedef ScenarioInfos = List<ScenarioInfo>;

/// Riverpod provider class for a List of [ScenarioInfo].
class ScenariosProvider extends StateNotifier<ScenarioInfos> {
  ScenariosProvider() : super(ScenarioInfos.empty() /*_scenarioSources*/);

  /// Updates the entire list of [ScenarioInfo].  Used for example when new data is read from a file.
  void updateAll(ScenarioInfos newInfos) {
    state = newInfos;
  }

  /// Replaces the item specified by [oldInfo] with the item specified in [newInfo].
  void updateInfoItem(ScenarioInfo oldInfo, ScenarioInfo newInfo) {
    state = state.map((info) => info == oldInfo ? newInfo : info).toList();
  }

  /// Adds / inserts the item specified in [newInfo] at the location specified by [insertAt].
  bool addInfoItem(ScenarioInfo newInfo, int insertAt) {
    final ScenarioInfos newInfos = [...state];
    if (insertAt <  0) return false;
    if (insertAt > newInfos.length) return false;
    newInfos.insert(insertAt, newInfo);
    state = newInfos;
    return true;
  }

  /// Removes at the location specified in [removeAt].
  void removeInfoItemAt(int removeAt) {
    final ScenarioInfos newInfos = [...state];
    newInfos.removeAt(removeAt);
    state = newInfos;
  }

  /// Moves the item at [oldIndex] to the location specified at [newIndex].
  void moveInfoItem(int oldIndex, int newIndex) {
    final ScenarioInfos newInfos = [...state];
    final ScenarioInfo item = newInfos.removeAt(oldIndex);
    newInfos.insert(newIndex, item);
    state = newInfos;
  }
}

typedef ScenariosNotifierProvider
    = StateNotifierProvider<ScenariosProvider, ScenarioInfos>;

/// Riverpod provider for a List of [ScenarioInfo].
final scenarioInfosProvider = ScenariosNotifierProvider((ref) {
  return ScenariosProvider();
});

final DateTime defaultDT = DateTime(2020, 12, 25);

// Default list of conversion scenarios used for initial development.
// ignore: unused_element
final ScenarioInfos _scenarioSources = [
  ScenarioInfo(
    name: 'Barney',
    colorOption: ColorOption.blue,
    amountConstraint: const AmountConstraint(type: AmountConstraintType.amount, fixedAmount: 10000) ,
    startDateConstraint: ConversionStartDateConstraint.onPlanStart,
    endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
    stopWhenTaxableIncomeUnavailible: true,
  ),
  ScenarioInfo(
    colorOption: ColorOption.green,
    amountConstraint: const AmountConstraint(type: AmountConstraintType.magiLimit, fixedAmount: 140000),
    startDateConstraint: ConversionStartDateConstraint.onFixedDate,
    specificStartDate: defaultDT,
    endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
    stopWhenTaxableIncomeUnavailible: true,
  ),
  ScenarioInfo(
    colorOption: ColorOption.purple,
    amountConstraint: const AmountConstraint(type: AmountConstraintType.amount, fixedAmount: 120000.0),
    startDateConstraint: ConversionStartDateConstraint.onPlanStart,
    endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
    stopWhenTaxableIncomeUnavailible: true,
  ),
];
