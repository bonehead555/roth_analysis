import 'package:flutter/material.dart';
import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/widgets/utility/dollar_input_field.dart';
import 'package:roth_analysis/widgets/utility/padded_text_field.dart';
import 'package:roth_analysis/widgets/utility/percent_input_field.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class AccountEditor extends StatefulWidget {
  const AccountEditor({
    super.key,
    required this.width,
    required this.initialInfo,
    required this.isNew,
    required this.onEditComplete,
  });

  final double width;
  final AccountInfo initialInfo;
  final bool isNew;
  final Function(AccountInfo?) onEditComplete;

  @override
  State<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<AccountEditor> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late AccountInfo accountInfo;
  late AccountType accountType;
  bool _showFieldErrorMesssage = false;

  @override
  void initState() {
    accountInfo = widget.initialInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Widget emptyCell = SizedBox();
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      width: widget.width,
      //height: dialogHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Row(
              children: [
                Text(
                  widget.isNew ? 'New Account' : 'Edit Account',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_showFieldErrorMesssage)
                  Text(
                    WidgetConstants.fieldIsInvalidMsg,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ),
          WidgetConstants.defaultDivider,
          Form(
            key: formKey,
            child: Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: FixedColumnWidth(220.0),
                  1: FixedColumnWidth(40.0),
                  2: FixedColumnWidth(220.0),
                  3: FixedColumnWidth(40.0),
                  4: FixedColumnWidth(220.0),
                  5: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      PaddedTextFormField(
                        label: 'Account Name',
                        initialValue: accountInfo.name,
                        validator: (newValue) {
                          return (newValue == null || newValue.length > 20)
                              ? 'String less than 20 characters'
                              : null;
                        },
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            accountInfo = accountInfo.copyWith(name: newValue);
                          });
                        },
                      ),
                      emptyCell,
                      Padding(
                        padding: WidgetConstants.defaultOtherFieldPadding,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            labelText: 'Account Type',
                            border: OutlineInputBorder(),
                          ),
                          value: accountInfo.type,
                          items: [
                            for (final accountType in AccountType.values)
                              DropdownMenuItem<AccountType>(
                                  value: accountType,
                                  child: Text(accountType.label)),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              accountInfo = accountInfo.copyWith(type: value);
                            });
                          },
                        ),
                      ),
                      emptyCell,
                      Padding(
                        padding: WidgetConstants.defaultOtherFieldPadding,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Owner',
                          ),
                          value: accountInfo.owner,
                          items: [
                            for (final ownerType in OwnerType.values)
                              DropdownMenuItem<OwnerType>(
                                  value: ownerType,
                                  child: Text(ownerType.label)),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              accountInfo =
                                  accountInfo.copyWith(owner: newValue);
                            }
                          },
                        ),
                      ),
                      emptyCell,
                    ],
                  ),
                  TableRow(children: [
                    DollarInputFormField(
                      labelText: 'Account Balance',
                      initialValue: accountInfo.balance,
                      minValue: 0.0,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() {
                          accountInfo = accountInfo.copyWith(balance: newValue);
                        });
                      },
                    ),
                    emptyCell,
                    if (accountInfo.type == AccountType.taxableBrokerage) ...[
                      DollarInputFormField(
                        labelText: 'Cost Basis',
                        initialValue: accountInfo.costBasis,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            accountInfo =
                                accountInfo.copyWith(costBasis: newValue);
                          });
                        },
                      ),
                    ] else ...[
                      emptyCell,
                    ],
                    emptyCell,
                    emptyCell,
                    emptyCell,
                  ]),
                  TableRow(
                    children: [
                      PercentInputFormField(
                        labelText: 'Yearly Gain Percentage',
                        initialValue: accountInfo.roiGain,
                        minValue: 0.0,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            accountInfo =
                                accountInfo.copyWith(roiGain: newValue);
                          });
                        },
                      ),
                      emptyCell,
                      if (accountInfo.type == AccountType.taxableBrokerage) ...[
                        PercentInputFormField(
                          labelText: 'Yearly Income Percentage',
                          initialValue: accountInfo.roiIncome,
                          minValue: 0.0,
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            setState(() {
                              accountInfo =
                                  accountInfo.copyWith(roiIncome: newValue);
                            });
                          },
                        ),
                      ] else ...[
                        emptyCell,
                      ],
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                ]),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    widget.onEditComplete(accountInfo);
                  } else {
                    setState(() {
                      _showFieldErrorMesssage = true;
                    });
                    Future.delayed(const Duration(milliseconds: 2250), () {
                      setState(() {
                        _showFieldErrorMesssage = false;
                      });
                    });
                  }
                },
                child: const Text('Accept'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => widget.onEditComplete(null),
                child: const Text('Cancel'),
              )
            ],
          )
        ],
      ),
    );
  }
}
