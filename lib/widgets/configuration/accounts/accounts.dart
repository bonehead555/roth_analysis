import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/providers/accounts_provider.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/configuration/accounts/account_editor.dart';
import 'package:roth_analysis/widgets/utility/empty_list.dart';

class Accounts extends ConsumerStatefulWidget {
  const Accounts({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<Accounts> createState() => _AccountsState();
}

class _AccountsState extends ConsumerState<Accounts> {
  int selected = -1;

  bool get isSelected {
    return selected >= 0;
  }

  @override
  void initState() {
    updateAppBarController(onUpdate: false);
    super.initState();
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
      insertAt = ref.read(accountInfoProvider).length;
    }
    AccountInfo oldInfo = AccountInfo(type: AccountType.taxableSavings);
    AccountInfo? newInfo = await _editInfoDialog(oldInfo, true);
    if (newInfo == null) return;
    bool wasAdded =
        ref.read(accountInfoProvider.notifier).addInfoItem(newInfo, insertAt);
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
    AccountInfo? oldInfo = ref.read(accountInfoProvider).elementAtOrNull(index);
    if (oldInfo == null) return;
    AccountInfo? newInfo = await _editInfoDialog(oldInfo, false);
    if (newInfo == null) return;
    ref.read(accountInfoProvider.notifier).updateInfoItem(oldInfo, newInfo);
    if (index != selected) {
      setState(() {
        selected = index;
      });
    }
  }

  Future<AccountInfo?> _editInfoDialog(
      AccountInfo initialInfo, bool isNew) async {
    double dialogHeight = context.size!.height * 0.9;
    double dialogWidth = min(context.size!.width * 0.9, 800);
    Offset parentOffset =
        (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    double dialogX = parentOffset.dx + dialogWidth * 0.1 / 2;
    double dialogY = parentOffset.dy + dialogHeight * 0.1 / 2;

    AccountInfo? updatedInfo = await showDialog<AccountInfo?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        alignment: Alignment.topLeft,
        insetPadding: EdgeInsets.only(top: dialogY, left: dialogX),
        child: AccountEditor(
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

    ref.read(accountInfoProvider.notifier).removeInfoItemAt(selected);
    AccountInfos updatedSources = ref.read(accountInfoProvider);

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
    ref.read(accountInfoProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  void _moveIncomeInfoDown() {
    if (!isSelected) {
      // print('No selection for move down Income Item');
      return;
    }
    int oldIndex = selected;
    if (oldIndex == ref.read(accountInfoProvider).length - 1) return;
    int newIndex = oldIndex + 1;
    ref.read(accountInfoProvider.notifier).moveInfoItem(oldIndex, newIndex);
    setSelected(newIndex);
  }

  Widget buildCard(BuildContext context, AccountInfos accountInfos, int index) {
    const Widget emptyCell = SizedBox();
    AccountInfo accountInfo = accountInfos[index];
    String name = accountInfo.name;
    AccountType accountType = accountInfo.type;
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
                  0: FixedColumnWidth(130.0),
                  1: FixedColumnWidth(8.0),
                  2: FixedColumnWidth(130.0),
                  3: FixedColumnWidth(20.0),
                  4: FixedColumnWidth(130.0),
                  5: FixedColumnWidth(8.0),
                  6: FixedColumnWidth(130.0),
                  7: FixedColumnWidth(20.0),
                  8: FixedColumnWidth(60.0),
                  9: FixedColumnWidth(8.0),
                  10: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: [
                      const Text(
                        'Account Name:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(name),
                      emptyCell,
                      const Text(
                        'Account Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(accountType.label),
                      emptyCell,
                      const Text(
                        'Owner:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(accountInfo.owner.label),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text(
                        'Account Balance:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(showDollarString(accountInfo.balance)),
                      emptyCell,
                      if (accountInfo.type == AccountType.taxableBrokerage) ...[
                        const Text(
                          'Cost Basis:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        emptyCell,
                        Text(showDollarString(accountInfo.costBasis)),
                      ] else ...[
                        emptyCell,
                        emptyCell,
                        emptyCell,
                      ],
                      emptyCell,
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text(
                        'Yearly Gain %:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      emptyCell,
                      Text(showPercentage(accountInfo.roiGain)),
                      emptyCell,
                      if (accountInfo.type == AccountType.taxableBrokerage) ...[
                        const Text(
                          'Yearly Income %:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        emptyCell,
                        Text(showPercentage(accountInfo.roiIncome)),
                      ] else ...[
                        emptyCell,
                        emptyCell,
                        emptyCell,
                      ],
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
    int numIncomeItems = ref.read(accountInfoProvider).length;
    widget.appBarController.update(
      title: 'Configuration - Accounts',
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
    final AccountInfos accountInfos = ref.watch(accountInfoProvider);
    if (accountInfos.isEmpty) {
      return const EmptyList(itemName: 'Accounts');
    } else {
      return Center(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: accountInfos.length,
          itemBuilder: (context, index) =>
              buildCard(context, accountInfos, index),
        ),
      );
    }
  }
}
