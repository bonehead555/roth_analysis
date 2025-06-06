import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roth_analysis/models/data/global_constants.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/widgets/utility/date_field.dart';
import 'package:roth_analysis/widgets/utility/dollar_input_field.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class IncomeSourceEditor extends StatefulWidget {
  const IncomeSourceEditor({
    super.key,
    required this.width,
    required this.initialInfo,
    required this.isNew,
    required this.onEditComplete,
  });

  final double width;
  final IncomeInfo initialInfo;
  final bool isNew;
  final Function(IncomeInfo?) onEditComplete;

  @override
  State<IncomeSourceEditor> createState() => _IncomeSourceEditorState();
}

class _IncomeSourceEditorState extends State<IncomeSourceEditor> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late IncomeInfo incomeInfo;
  bool _showFieldErrorMesssage = false;
  Timer? resetErrorHandler;

  @override
  void initState() {
    incomeInfo = widget.initialInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Widget emptyCell = SizedBox();
    final validDates = GlobalConstants.validDateRange;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
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
                      widget.isNew ? 'New Income Item' : 'Edit Income Item',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (_showFieldErrorMesssage)
                      Text(
                        WidgetConstants.fieldIsInvalidMsg,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
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
                        Padding(
                          padding: WidgetConstants.defaultOtherFieldPadding,
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                              labelText: 'Income Type',
                              border: OutlineInputBorder(),
                            ),
                            value: incomeInfo.type,
                            items: [
                              for (final incomeType in IncomeType.values)
                                DropdownMenuItem<IncomeType>(
                                    value: incomeType,
                                    child: Text(incomeType.label)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                incomeInfo = incomeInfo.copyWith(type: value);
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
                            value: incomeInfo.owner,
                            items: [
                              for (final ownerType in OwnerType.values)
                                DropdownMenuItem<OwnerType>(
                                    value: ownerType,
                                    child: Text(ownerType.label)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                incomeInfo = incomeInfo.copyWith(owner: value);
                              });
                            },
                          ),
                        ),
                        emptyCell,
                        emptyCell,
                        emptyCell,
                      ],
                    ),
                    TableRow(children: [
                      DollarInputFormField(
                        labelText: 'Yearly Income',
                        initialValue: incomeInfo.yearlyIncome,
                        minValue: 0.0,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            incomeInfo =
                                incomeInfo.copyWith(yearlyIncome: newValue);
                          });
                        },
                      ),
                      emptyCell,
                      DateFormField(
                        labelText: 'Start Date',
                        currentDate: incomeInfo.startDate,
                        firstDate: validDates.firstDate,
                        lastDate: validDates.lastDate,
                        onChanged: (dateTime) {
                          setState(() {
                            incomeInfo =
                                incomeInfo.copyWith(startDate: dateTime);
                          });
                        },
                      ),
                      emptyCell,
                      if (incomeInfo.type != IncomeType.socialSecurity) ...[
                        DateFormField(
                          labelText: 'End Date',
                          currentDate: incomeInfo.endDate,
                          firstDate: validDates.firstDate,
                          lastDate: validDates.lastDate,
                          onChanged: (dateTime) {
                            setState(() {
                              incomeInfo =
                                  incomeInfo.copyWith(endDate: dateTime);
                            });
                          },
                        ),
                      ] else ...[
                        emptyCell,
                      ],
                      emptyCell,
                    ]),
                  ],
                ),
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
                        widget.onEditComplete(incomeInfo);
                      } else {
                        setState(() {
                          _showFieldErrorMesssage = true;
                        });
                        resetErrorHandler =
                            Timer(const Duration(milliseconds: 2250), () {
                          resetErrorHandler = null;
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
                    onPressed: () {
                      if (resetErrorHandler != null) {
                        resetErrorHandler!.cancel();
                      }
                      resetErrorHandler = null;
                      widget.onEditComplete(null);
                    },
                    child: const Text('Cancel'),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
