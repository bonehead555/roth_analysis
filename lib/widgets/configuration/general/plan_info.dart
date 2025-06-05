import 'package:flutter/material.dart';
import 'package:roth_analysis/models/data/global_constants.dart';
import 'package:roth_analysis/providers/plan_provider.dart';
import 'package:roth_analysis/widgets/utility/date_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/widgets/utility/dollar_input_field.dart';
import 'package:roth_analysis/widgets/utility/percent_input_field.dart';
import 'package:roth_analysis/widgets/utility/stock_card.dart';

class PlanInfoWidget extends ConsumerStatefulWidget {
  const PlanInfoWidget({super.key});

  static const double requiredWidth = 500;

  @override
  ConsumerState<PlanInfoWidget> createState() => _PlanInfoWidgetState();
}

class _PlanInfoWidgetState extends ConsumerState<PlanInfoWidget> {
  void _onStartDateSelected(DateTime selectedDate) {
    ref.read(planProvider.notifier).update(planStartDate: selectedDate);
  }

  void _onEndDateSelected(DateTime selectedDate) {
    ref.read(planProvider.notifier).update(planEndDate: selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final planInfo = ref.watch(planProvider);
    const Widget emptyCell = SizedBox();
    final validDates =  GlobalConstants.validDateRange;

    return StockCard(
      title: 'Plan Information',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(220.0),
          1: FixedColumnWidth(20.0),
          2: FixedColumnWidth(220.0),
          3: FixedColumnWidth(20.0),
          4: FixedColumnWidth(220.0),
          //5: FixedColumnWidth(40.0),
          //6: FixedColumnWidth(220.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
        children: <TableRow>[
          TableRow(
            children: [
              DateField(
                labelText: 'Plan Start Date',
                currentDate: planInfo.planStartDate,
                firstDate: validDates.firstDate,
                lastDate: validDates.lastDate,
                onChanged: _onStartDateSelected,
              ),
              emptyCell,
              DateField(
                labelText: 'Plan End Date',
                currentDate: planInfo.planEndDate,
                firstDate: validDates.firstDate,
                lastDate: validDates.lastDate,
                onChanged: _onEndDateSelected,
              ),
              emptyCell,
              emptyCell,
            ],
          ),
          TableRow(children: [
            DollarInputField(
              labelText: 'Yearly Expenses',
              initialValue: planInfo.yearlyExpenses,
              minValue: 0.0,
              onChanged: (newValue) {
                ref
                    .read(planProvider.notifier)
                    .update(yearlyExpenses: newValue);
              },
            ),
            emptyCell,
            PercentInputField(
              labelText: 'Cost of Living Adjustment',
              initialValue: planInfo.cola,
              minValue: 0.0,
              onChanged: (newValue) {
                if (newValue != null) {
                  ref.read(planProvider.notifier).update(cola: newValue);
                }
              },
            ),
            emptyCell,
            emptyCell,
          ])
        ],
      ),
    );
  }
}
