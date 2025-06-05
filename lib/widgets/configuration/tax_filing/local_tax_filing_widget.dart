import 'package:flutter/material.dart';
import 'package:roth_analysis/providers/tax_filing_info_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/utility/percent_input_field.dart';
import 'package:roth_analysis/widgets/utility/stock_card.dart';

class LocalTaxFilingWidget extends ConsumerStatefulWidget {
  const LocalTaxFilingWidget({super.key});

  static const double requiredWidth = 400;

  @override
  ConsumerState<LocalTaxFilingWidget> createState() =>
      _LocalTaxFilingWidgetState();
}

class _LocalTaxFilingWidgetState extends ConsumerState<LocalTaxFilingWidget> {
  late TextEditingController ctrlLocalTaxPercent;

  @override
  void initState() {
    super.initState();
    ctrlLocalTaxPercent = TextEditingController(
        text: showPercentage(ref.read(taxFilingInfoProvider).localTaxPercentage,
            showPercentSign: true));
  }

  @override
  Widget build(BuildContext context) {
    final taxFilingInfo = ref.watch(taxFilingInfoProvider);
    const Widget emptyCell = SizedBox();

    return StockCard(
      title: 'Local Tax Filing Information',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(180.0),
          1: FixedColumnWidth(20.0),
          2: FixedColumnWidth(180.0),
          3: FixedColumnWidth(20.0),
          4: FixedColumnWidth(180.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
        children: <TableRow>[
          TableRow(
            children: [
              PercentInputField(
                labelText: 'Local Tax Percentage',
                minValue: 0.0,
                initialValue: taxFilingInfo.localTaxPercentage,
                onChanged: (newValue) {
                  if (newValue == null) return;
                  setState(() {
                    ref
                        .read(taxFilingInfoProvider.notifier)
                        .update(localTaxPercentage: newValue);
                  });
                },
              ),
              emptyCell,
              emptyCell,
              emptyCell,
              emptyCell,
            ],
          ),
        ],
      ),
    );
  }
}
