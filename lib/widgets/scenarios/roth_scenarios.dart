import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/enums/color_option.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';
import 'package:roth_analysis/providers/scenarios_provider.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/scenarios/scenario_editor.dart';
import 'package:roth_analysis/widgets/utility/empty_list.dart';

class RothScenarios extends ConsumerStatefulWidget {
  const RothScenarios({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<RothScenarios> createState() => _RothScenariosState();
}

class _RothScenariosState extends ConsumerState<RothScenarios> {
  int selected = -1;

  @override
  void initState() {
    updateAppBarController(onUpdate: false);
    super.initState();
  }

  bool get isSelected {
    return selected >= 0;
  }

  void setSelected(int index) {
    setState(() {
      if (index == selected) {
        selected = -1;
      } else {
        selected = index;
      }
      updateAppBarController(onUpdate: true);
    });
  }

  void _newIncomeInfo() async {
    int insertAt = 0;
    if (isSelected) {
      insertAt = selected + 1;
    } else {
      insertAt = ref.read(scenarioInfosProvider).length;
    }
    ScenarioInfo defaultInfo = ScenarioInfo();
    ScenarioInfo? newInfo = await _editInfoDialog(defaultInfo, true);
    if (newInfo == null) return;
    bool wasAdded =
        ref.read(scenarioInfosProvider.notifier).addInfoItem(newInfo, insertAt);
    if (!wasAdded) return;
    setSelected(insertAt);
  }

  void _editSelectedIncomeInfo() {
    if (!isSelected) {
      // print('No selection for edit Income Item');
      return;
    }
    _editIncomeInfoAt(selected);
  }

  void _editIncomeInfoAt(int index) async {
    ScenarioInfo? oldInfo =
        ref.read(scenarioInfosProvider).elementAtOrNull(index);
    if (oldInfo == null) return;
    ScenarioInfo? newInfo = await _editInfoDialog(oldInfo, false);
    if (newInfo == null) return;
    ref.read(scenarioInfosProvider.notifier).updateInfoItem(oldInfo, newInfo);
    if (index != selected) {
      setState(() {
        selected = index;
      });
    }
  }

  Future<ScenarioInfo?> _editInfoDialog(
      ScenarioInfo initialInfo, bool isNew) async {
    double dialogHeight = context.size!.height * 0.9;
    double dialogWidth = min(context.size!.width * 0.9, 800);
    Offset parentOffset =
        (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    double dialogX = parentOffset.dx + dialogWidth * 0.1 / 2;
    double dialogY = parentOffset.dy + dialogHeight * 0.1 / 2;

    ScenarioInfo? updatedInfo = await showDialog<ScenarioInfo?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        alignment: Alignment.topLeft,
        insetPadding: EdgeInsets.only(top: dialogY, left: dialogX),
        child: ScenarioEditor(
          width: dialogWidth,
          initialInfo: initialInfo,
          isNew: isNew,
          onEditComplete: (editedScenario) {
            Navigator.pop(context, editedScenario);
          },
        ),
      ),
    );
    return updatedInfo;
  }

  void _removeIncomeInfo() {
    if (!isSelected) {
      // print('No selection for remove Income Item');
      return;
    }

    ref.read(scenarioInfosProvider.notifier).removeInfoItemAt(selected);
    ScenarioInfos updatedSources = ref.read(scenarioInfosProvider);

    if (updatedSources.isEmpty) {
      setSelected(-1);
    } else if (updatedSources.length <= selected) {
      setSelected(updatedSources.length - 1);
    } else {
      // selected does not need updated.
    }
  }

  void _moveIncomeInfoUp() {
    if (!isSelected) {
      // print('No selection for move up Income Item');
      return;
    }
    final int oldIndex = selected;
    final int newIndex = oldIndex - 1;
    ref.read(scenarioInfosProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  void _moveIncomeInfoDown() {
    if (!isSelected) {
      // print('No selection for move down Income Item');
      return;
    }
    int oldIndex = selected;
    if (oldIndex == ref.read(scenarioInfosProvider).length - 1) return;
    int newIndex = oldIndex + 1;
    ref.read(scenarioInfosProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  Widget getAmountConstraintValueWidget(AmountConstraint amountConstraint) {
    return Text(showDollarString(amountConstraint.fixedAmount));
  }

  List<Widget> _buildStartDateConstraintValueWidgets(
      ScenarioInfo scenarioInfo) {
    const Widget emptyCell = SizedBox();
    if (scenarioInfo.startDateConstraint ==
        ConversionStartDateConstraint.onPlanStart) {
      return [emptyCell, emptyCell, emptyCell];
    }
    // scenarioInfo.startDateConstraint == ConversionStartDateConstraint.onFixedDate
    return [
      buildLabel('Date'),
      emptyCell,
      Text(dateToString(scenarioInfo.specificStartDate)),
    ];
  }

  List<Widget> _buildEndDateConstraintValueWidgets(ScenarioInfo scenarioInfo) {
    const Widget emptyCell = SizedBox();
    if (scenarioInfo.endDateConstraint ==
            ConversionEndDateConstraint.onEndOfPlan ||
        scenarioInfo.endDateConstraint ==
            ConversionEndDateConstraint.onRmdStart) {
      return [
        emptyCell,
        emptyCell,
        emptyCell,
      ];
    }
    //scenarioInfo.endDateConstraint == ConversionEndDateConstraint.onFixedDate
    return [
      buildLabel('Date'),
      emptyCell,
      Text(dateToString(scenarioInfo.specificEndDate)),
    ];
  }

  Widget buildLabel(String? text) {
    return Text(
      text != null ? '$text:' : '',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget buildCard(
      BuildContext context, ScenarioInfos scenarioInfos, int index) {
    const Widget emptyCell = SizedBox();
    ScenarioInfo scenarioInfo = scenarioInfos[index];
    ColorOption colorOption = scenarioInfo.colorOption;
    AmountConstraint amountConstraint = scenarioInfo.amountConstraint;

    Color defaultCardBorderColor = Colors.grey;
    Color selectedCardBorderColor = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 800,
        child: GestureDetector(
          onTap: () {
            setSelected(index);
          },
          onDoubleTap: () {
            _editIncomeInfoAt(index);
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected == index
                    ? selectedCardBorderColor
                    : defaultCardBorderColor,
                width: selected == index ? 5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: FixedColumnWidth(220.0),
                  1: FixedColumnWidth(8.0),
                  2: FixedColumnWidth(150.0),
                  3: FixedColumnWidth(20.0),
                  4: FixedColumnWidth(60.0),
                  5: FixedColumnWidth(8.0),
                  6: FixedColumnWidth(130.0),
                  7: FixedColumnWidth(10.0),
                  8: FixedColumnWidth(60.0),
                  9: FixedColumnWidth(8.0),
                  10: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: [
                      buildLabel('Scenario Name'),
                      emptyCell,
                      Text(scenarioInfo.name),
                      emptyCell,
                      buildLabel('Color'),
                      emptyCell,
                      Text(colorOption.label,
                          style: TextStyle(color: colorOption.color)),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      buildLabel('Amount Constraint Type'),
                      emptyCell,
                      Text(amountConstraint.type.label),
                      emptyCell,
                      buildLabel('Value'),
                      emptyCell,
                      getAmountConstraintValueWidget(amountConstraint),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      buildLabel('Start Date Constraint Type'),
                      emptyCell,
                      Text(scenarioInfo.startDateConstraint.label),
                      emptyCell,
                      ..._buildStartDateConstraintValueWidgets(scenarioInfo),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      buildLabel('End Date Constraint Type'),
                      emptyCell,
                      Text(scenarioInfo.endDateConstraint.label),
                      emptyCell,
                      ..._buildEndDateConstraintValueWidgets(scenarioInfo),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      buildLabel('Use Pre-Tax Dollars for Taxes'),
                      emptyCell,
                      Text(scenarioInfo.stopWhenTaxableIncomeUnavailible
                          ? 'No'
                          : 'Yes'),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void updateAppBarController({required bool onUpdate}) {
    int numIncomeItems = ref.read(scenarioInfosProvider).length;
    widget.appBarController.update(
      title: 'Configuration - Scenarios',
      actionAdditions: [
        Tooltip(
          message: 'Item down',
          child: IconButton(
            onPressed: onUpdate && isSelected && selected < numIncomeItems - 1
                ? _moveIncomeInfoDown
                : null,
            icon: const Icon(Icons.move_down),
          ),
        ),
        Tooltip(
          message: 'Item up',
          child: IconButton(
            onPressed: onUpdate && isSelected && selected > 0
                ? _moveIncomeInfoUp
                : null,
            icon: const Icon(Icons.move_up),
          ),
        ),
        Tooltip(
          message: 'Add Item',
          child: IconButton(
            onPressed: _newIncomeInfo,
            icon: const Icon(Icons.add_sharp),
          ),
        ),
        Tooltip(
          message: 'Edit Item',
          child: IconButton(
            onPressed: onUpdate && isSelected ? _editSelectedIncomeInfo : null,
            icon: const Icon(Icons.edit),
          ),
        ),
        Tooltip(
          message: 'Delete Item',
          child: IconButton(
            onPressed: onUpdate && isSelected ? _removeIncomeInfo : null,
            icon: const Icon(Icons.delete),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScenarioInfos scenarioInfos = ref.watch(scenarioInfosProvider);
    if (scenarioInfos.isEmpty) {
      return const EmptyList(itemName: 'Roth Conversion Scenarios');
    } else {
      return Center(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: scenarioInfos.length,
          itemBuilder: (context, index) =>
              buildCard(context, scenarioInfos, index),
        ),
      );
    }
  }
}
