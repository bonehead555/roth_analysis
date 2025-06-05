import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/providers/income_sources_provider.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/income_sources/income_source_editor.dart';
import 'package:roth_analysis/widgets/utility/empty_list.dart';

class IncomeSources extends ConsumerStatefulWidget {
  const IncomeSources({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<IncomeSources> createState() => _IncomeSourcesState();
}

class _IncomeSourcesState extends ConsumerState<IncomeSources> {
  int selected = -1;

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
      insertAt = ref.read(incomeInfoProvider).length;
    }
    IncomeInfo oldIncomeInfo = IncomeInfo(type: IncomeType.employment);
    IncomeInfo? newIncomeInfo = await _editInfoDialog(oldIncomeInfo, true);
    if (newIncomeInfo == null) return;
    bool wasAdded = ref
        .read(incomeInfoProvider.notifier)
        .addInfoItem(newIncomeInfo, insertAt);
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
    IncomeInfo? oldIncomeInfo =
        ref.read(incomeInfoProvider).elementAtOrNull(index);
    if (oldIncomeInfo == null) return;
    IncomeInfo? newIncomeInfo = await _editInfoDialog(oldIncomeInfo, false);
    if (newIncomeInfo == null) return;
    ref
        .read(incomeInfoProvider.notifier)
        .updateInfoItem(oldIncomeInfo, newIncomeInfo);
    if (index != selected) {
      setState(() {
        selected = index;
      });
    }
  }

  Future<IncomeInfo?> _editInfoDialog(
      IncomeInfo initialInfo, bool isNew) async {
    double dialogHeight = context.size!.height * 0.9;
    double dialogWidth = min(context.size!.width * 0.9, 770);
    Offset parentOffset =
        (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    double dialogX = parentOffset.dx + dialogWidth * 0.1 / 2;
    double dialogY = parentOffset.dy + dialogHeight * 0.1 / 2;

    IncomeInfo? updatedInfo = await showDialog<IncomeInfo?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        alignment: Alignment.topLeft,
        insetPadding: EdgeInsets.only(top: dialogY, left: dialogX),
        child: IncomeSourceEditor(
          width: dialogWidth,
          initialInfo: initialInfo,
          isNew: isNew,
          onEditComplete: (editedAccount) {
            Navigator.pop(context, editedAccount);
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

    ref.read(incomeInfoProvider.notifier).removeInfoItemAt(selected);
    IncomeInfos updatedSources = ref.read(incomeInfoProvider);

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
    ref.read(incomeInfoProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  void _moveIncomeInfoDown() {
    if (!isSelected) {
      // print('No selection for move down Income Item');
      return;
    }
    int oldIndex = selected;
    if (oldIndex == ref.read(incomeInfoProvider).length - 1) return;
    int newIndex = oldIndex + 1;
    ref.read(incomeInfoProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  Widget buildCard(BuildContext context, IncomeInfos incomeSources, int index) {
    const Widget emptyCell = SizedBox();
    IncomeInfo incomeInfo = incomeSources[index];
    IncomeType incomeType = incomeInfo.type;
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
            //color: selected == index ? selectedCardColor : defaultCardColor,
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
                  0: FixedColumnWidth(110.0),
                  1: FixedColumnWidth(8.0),
                  2: FixedColumnWidth(130.0),
                  3: FixedColumnWidth(20.0),
                  4: FixedColumnWidth(80.0),
                  5: FixedColumnWidth(8.0),
                  6: FixedColumnWidth(110.0),
                  7: FixedColumnWidth(20.0),
                  8: FixedColumnWidth(120.0),
                  9: FixedColumnWidth(8.0),
                  10: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: [
                      const Text(
                        'Income Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(incomeType.label),
                      emptyCell,
                      const Text(
                        'Owner:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(incomeInfo.owner.label),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text(
                        'Yearly Income:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(showDollarString(incomeInfo.yearlyIncome)),
                      emptyCell,
                      const Text(
                        'Start Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(dateToString(incomeInfo.startDate)),
                      emptyCell,
                      if (incomeType == IncomeType.socialSecurity) ...[
                        emptyCell,
                        emptyCell,
                        emptyCell,
                      ] else ...[
                        const Text(
                          'End Date:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        emptyCell,
                        Text(dateToString(incomeInfo.endDate)),
                      ]
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

  @override
  void initState() {
    updateAppBarController(onUpdate: false);
    super.initState();
  }

  void updateAppBarController({required bool onUpdate}) {
    int numIncomeItems = ref.read(incomeInfoProvider).length;
    widget.appBarController.update(
      title: 'Configuration - Income Sources',
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
    final IncomeInfos incomeInfos = ref.watch(incomeInfoProvider);
    if (incomeInfos.isEmpty) {
      return const EmptyList(itemName: 'Income Sources');
    } else {
      return Center(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: incomeInfos.length,
          itemBuilder: (context, index) =>
              buildCard(context, incomeInfos, index),
        ),
      );
    }
  }
}
