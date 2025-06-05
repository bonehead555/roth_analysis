import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/global_constants.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/providers/person_provider.dart';
import 'package:roth_analysis/widgets/utility/date_field.dart';
import 'package:roth_analysis/widgets/utility/stock_card.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class Person extends ConsumerStatefulWidget {
  const Person({super.key, required this.isSelf});

  final bool isSelf;

  static const double requiredWidth = 700;

  @override
  ConsumerState<Person> createState() => _PersonState();
}

class _PersonState extends ConsumerState<Person> {
  late PersonNotifierProvider personProvider;

  void _onBirthDateSelected(DateTime pickedDate) {
    ref.read(personProvider.notifier).update(birthDate: pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    personProvider = widget.isSelf ? selfProvider : spouseProvider;
    PersonInfo personInfo = ref.watch(personProvider);
    const Widget emptyCell = SizedBox();
    final validDates = GlobalConstants.validDateRange;

    return StockCard(
      title: widget.isSelf ? 'Self' : 'Spouse',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(220.0),
          1: FixedColumnWidth(20.0),
          2: FixedColumnWidth(220.0),
          3: FixedColumnWidth(20.0),
          4: FixedColumnWidth(220.0),
          //5: FixedColumnWidth(20.0),
          //6: FixedColumnWidth(180.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
        children: <TableRow>[
          TableRow(
            children: [
              DateField(
                labelText: 'Birthdate',
                currentDate: personInfo.birthDate,
                firstDate: validDates.firstDate,
                lastDate: validDates.lastDate,
                onChanged: _onBirthDateSelected,
              ),
              emptyCell,
              Padding(
                padding: WidgetConstants.defaultOtherFieldPadding,
                child: CheckboxListTile(
                  title: const Text('Blind'),
                  controlAffinity: ListTileControlAffinity.leading,
                  //subtitle: const Text('Check if Filing Blind on Taxes'),
                  value: personInfo.isBlind,
                  onChanged: (bool? value) {
                    ref.read(personProvider.notifier).update(isBlind: value);
                  },
                ),
              ),
              emptyCell,
              if (widget.isSelf) ...[
                Padding(
                  padding: WidgetConstants.defaultOtherFieldPadding,
                  child: CheckboxListTile(
                    title: const Text('Married'),
                    controlAffinity: ListTileControlAffinity.leading,
                    //subtitle: const Text('Check if Filing Blind on Taxes'),
                    value: personInfo.isMarried,
                    onChanged: (bool? value) {
                      ref
                          .read(personProvider.notifier)
                          .update(isMarried: value);
                    },
                  ),
                ),
              ] else ...[
                emptyCell,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
