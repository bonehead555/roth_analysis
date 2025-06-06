import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roth_analysis/models/data/global_constants.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/enums/color_option.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';
import 'package:roth_analysis/widgets/utility/date_field.dart';
import 'package:roth_analysis/widgets/utility/dollar_input_field.dart';
import 'package:roth_analysis/widgets/utility/padded_text_field.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class ScenarioEditor extends StatefulWidget {
  const ScenarioEditor({
    super.key,
    required this.width,
    required this.initialInfo,
    required this.isNew,
    required this.onEditComplete,
  });

  final double width;
  final ScenarioInfo initialInfo;
  final bool isNew;
  final Function(ScenarioInfo?) onEditComplete;

  @override
  State<ScenarioEditor> createState() => _ScenarioEditorState();
}

class _ScenarioEditorState extends State<ScenarioEditor> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late ScenarioInfo scenarioInfo;
  bool _showFieldErrorMesssage = false;
  Timer? resetErrorHandler;

  @override
  void initState() {
    scenarioInfo = widget.initialInfo;
    super.initState();
  }

  Widget getAmountContraintEditWidget() {
    return DollarInputFormField(
      labelText: 'Fixed Amount',
      initialValue: scenarioInfo.amountConstraint.fixedAmount,
      minValue: 0.0,
      onChanged: (newValue) {
        if (newValue == null) return;
        setState(
          () {
            scenarioInfo = scenarioInfo.copyWith(
                amountConstraint: scenarioInfo.amountConstraint
                    .copyWith(fixedAmount: newValue));
          },
        );
      },
    );
  }

  Widget getStartDateContraintEditWidget() {
    final validDates = GlobalConstants.validDateRange;
    if (scenarioInfo.startDateConstraint ==
        ConversionStartDateConstraint.onPlanStart) {
      return const SizedBox();
    }
    // scenarioInfo.startDateConstraint == ConversionStartDateConstraint.onFixedDate
    return DateFormField(
      labelText: 'Start Date',
      currentDate: scenarioInfo.specificStartDate,
      firstDate: validDates.firstDate,
      lastDate: validDates.lastDate,
      onChanged: (dateTime) {
        setState(() {
          scenarioInfo = scenarioInfo.copyWith(specificStartDate: dateTime);
        });
      },
    );
  }

  Widget getEndDateContraintEditWidget() {
    final validDates = GlobalConstants.validDateRange;
    if (scenarioInfo.endDateConstraint ==
            ConversionEndDateConstraint.onEndOfPlan ||
        scenarioInfo.endDateConstraint ==
            ConversionEndDateConstraint.onRmdStart) {
      return const SizedBox();
    }
    // scenarioInfo.endDateConstraint == ConversionEndDateConstraint.onFixedDate
    return DateFormField(
      labelText: 'End Date',
      currentDate: scenarioInfo.specificEndDate,
      firstDate: validDates.firstDate,
      lastDate: validDates.lastDate,
      onChanged: (dateTime) {
        setState(() {
          scenarioInfo = scenarioInfo.copyWith(specificEndDate: dateTime);
        });
      },
    );
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
                  widget.isNew ? 'New Scenario' : 'Edit Scenario',
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
                        label: 'Scenario Name',
                        initialValue: scenarioInfo.name,
                        validator: (newValue) {
                          return (newValue == null || newValue.length > 20)
                              ? 'String less than 20 characters'
                              : null;
                        },
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            scenarioInfo =
                                scenarioInfo.copyWith(name: newValue);
                          });
                        },
                      ),
                      emptyCell,
                      Padding(
                        padding: WidgetConstants.defaultOtherFieldPadding,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            labelText: 'Plot Color',
                            border: OutlineInputBorder(),
                          ),
                          value: scenarioInfo.colorOption,
                          items: [
                            for (final colorOption in ColorOption.values)
                              DropdownMenuItem<ColorOption>(
                                  value: colorOption,
                                  child: Text(
                                    colorOption.label,
                                    style: TextStyle(color: colorOption.color),
                                  )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              scenarioInfo =
                                  scenarioInfo.copyWith(colorOption: value);
                            });
                          },
                        ),
                      ),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: WidgetConstants.defaultOtherFieldPadding,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Amount Constraint Type',
                          ),
                          value: scenarioInfo.amountConstraint.type,
                          items: [
                            for (final amountConstraintType
                                in AmountConstraintType.values)
                              DropdownMenuItem<AmountConstraintType>(
                                  value: amountConstraintType,
                                  child: Text(amountConstraintType.label)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              scenarioInfo = scenarioInfo.copyWith(
                                  amountConstraint: scenarioInfo
                                      .amountConstraint
                                      .copyWith(type: value));
                            });
                          },
                        ),
                      ),
                      emptyCell,
                      getAmountContraintEditWidget(),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(children: [
                    Padding(
                      padding: WidgetConstants.defaultOtherFieldPadding,
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Start Date Constraint Type',
                        ),
                        value: scenarioInfo.startDateConstraint,
                        items: [
                          for (final startDateConstraintType
                              in ConversionStartDateConstraint.values)
                            DropdownMenuItem<ConversionStartDateConstraint>(
                                value: startDateConstraintType,
                                child: Text(startDateConstraintType.label)),
                        ],
                        onChanged: (value) {
                          setState(() {
                            scenarioInfo = scenarioInfo.copyWith(
                                startDateConstraint: value);
                          });
                        },
                      ),
                    ),
                    emptyCell,
                    getStartDateContraintEditWidget(),
                    emptyCell,
                    emptyCell,
                    emptyCell,
                  ]),
                  TableRow(
                    children: [
                      Padding(
                        padding: WidgetConstants.defaultOtherFieldPadding,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'End Date Constraint Type',
                          ),
                          value: scenarioInfo.endDateConstraint,
                          items: [
                            for (final endDateConstraintType
                                in ConversionEndDateConstraint.values)
                              DropdownMenuItem<ConversionEndDateConstraint>(
                                  value: endDateConstraintType,
                                  child: Text(endDateConstraintType.label)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              scenarioInfo = scenarioInfo.copyWith(
                                  endDateConstraint: value);
                            });
                          },
                        ),
                      ),
                      emptyCell,
                      getEndDateContraintEditWidget(),
                      emptyCell,
                      emptyCell,
                      emptyCell,
                    ],
                  ),
                  TableRow(
                    children: [
                      CheckboxListTile(
                          shape: const OutlineInputBorder(),
                          title: const Text(
                              'Checked when allowed to use pre-tax dollars for taxes'),
                          value: !scenarioInfo.stopWhenTaxableIncomeUnavailible,
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            setState(() {
                              scenarioInfo = scenarioInfo.copyWith(
                                  stopWhenTaxableIncomeUnavailible: !newValue);
                            });
                          }),
                      emptyCell,
                      emptyCell,
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
                    widget.onEditComplete(scenarioInfo);
                  } else {
                    resetErrorHandler =
                        Timer(const Duration(milliseconds: 2250), () {
                      resetErrorHandler = null;
                      setState(() {
                        _showFieldErrorMesssage = false;
                      });
                    });
                    setState(() {
                      _showFieldErrorMesssage = true;
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
