import 'package:flutter/material.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/providers/tax_filing_info_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/utility/percent_input_field.dart';
import 'package:roth_analysis/widgets/utility/stock_card.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class StateTaxFilingWidget extends ConsumerStatefulWidget {
  const StateTaxFilingWidget({super.key});

  static const double requiredWidth = 800;

  @override
  ConsumerState<StateTaxFilingWidget> createState() => _PlanInfoState();
}

class _PlanInfoState extends ConsumerState<StateTaxFilingWidget> {
  bool useFederalStandardDeduction = false;
  late TextEditingController ctrlStateTaxPercent;

  @override
  void initState() {
    super.initState();
    ctrlStateTaxPercent = TextEditingController(
        text: showPercentage(
            ref.read(taxFilingInfoProvider).stateTaxPercentage,
            showPercentSign: true));
  }

  @override
  Widget build(BuildContext context) {
    final taxFilingInfo = ref.watch(taxFilingInfoProvider);
    const Widget emptyCell = SizedBox();

    return StockCard(
      title: 'State Tax Filing Information',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(180.0),
          1: FixedColumnWidth(20.0),
          2: FixedColumnWidth(180.0),
          3: FixedColumnWidth(10.0),
          4: FixedColumnWidth(180.0),
          5: FixedColumnWidth(5.0),
          6: FixedColumnWidth(200.0)
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
        children: <TableRow>[
          TableRow(
            children: [
              Padding(
                padding: WidgetConstants.defaultOtherFieldPadding,
                child: DropdownMenu(
                  width: 180,
                  label: Text(
                    'Filing State',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  initialSelection: taxFilingInfo.filingState,
                  dropdownMenuEntries: [
                    for (final filingState in FilingState.values)
                      DropdownMenuEntry<FilingState>(
                          value: filingState, label: filingState.label),
                  ],
                  onSelected: (value) {
                    setState(() {
                      ref
                          .read(taxFilingInfoProvider.notifier)
                          .update(filingStateEnum: value);
                    });
                  },
                ),
              ),
              emptyCell,
              if (taxFilingInfo.filingState == FilingState.other) ...[
                PercentInputField(
                  labelText: 'State Tax Percentage',
                  minValue: 0.0,
                  initialValue: taxFilingInfo.stateTaxPercentage,
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    setState(() {
                      ref
                          .read(taxFilingInfoProvider.notifier)
                          .update(otherStateTaxPercentage: newValue);
                    });
                  },
                ),
                emptyCell,
                Padding(
                  padding: WidgetConstants.defaultOtherFieldPadding,
                  child: CheckboxListTile(
                    title: Text(
                      'Social Security Taxable',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    value: taxFilingInfo.stateTaxesSS,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        ref
                            .read(taxFilingInfoProvider.notifier)
                            .update(otherStateTaxableSS: newValue);
                      }
                    },
                  ),
                ),
                emptyCell,
                Padding(
                  padding: WidgetConstants.defaultOtherFieldPadding,
                  child: CheckboxListTile(
                    title: Text(
                      'Retirement Income Taxable?',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    value: taxFilingInfo.stateTaxesRetirementIncome,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        ref.read(taxFilingInfoProvider.notifier).update(
                            otherStateTaxableRetirementIncome: newValue);
                      }
                    },
                  ),
                ),
              ] else ...[
                emptyCell,
                emptyCell,
                emptyCell,
                emptyCell,
                emptyCell,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
