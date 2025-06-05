import 'package:flutter/material.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/providers/person_provider.dart';
import 'package:roth_analysis/providers/tax_filing_info_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/widgets/utility/stock_card.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class FederalTaxFilingWidget extends ConsumerStatefulWidget {
  const FederalTaxFilingWidget({super.key});

  static const double requiredWidth = 500;

  @override
  ConsumerState<FederalTaxFilingWidget> createState() =>
      _FederalTaxFilingWidgetState();
}

class _FederalTaxFilingWidgetState
    extends ConsumerState<FederalTaxFilingWidget> {
  bool useFederalStandardDeduction = true;

  String? _getFederalFilingStatusError(
      bool isMarried, FilingStatus filingStatusToCheck) {
    if (isMarried && filingStatusToCheck != FilingStatus.marriedFilingJointly) {
      // || filingStatusToCheck == FilingStatus.marriedFilingSeparately;
      return 'Invalid option for married tax filer.';
    }
    if (!isMarried && filingStatusToCheck.isMarried) {
      return 'Invalid option for single tax filer.';
    }
    return null;
  }

  bool isValidFederalFilingStatus(
      bool isMarried, FilingStatus filingStatusToCheck) {
    if (isMarried) {
      return filingStatusToCheck == FilingStatus.marriedFilingJointly;
      // || filingStatusToCheck == FilingStatus.marriedFilingSeparately;
    }
    return filingStatusToCheck == FilingStatus.single ||
        filingStatusToCheck == FilingStatus.headOfHousehold;
  }

  @override
  Widget build(BuildContext context) {
    final taxFilingInfo = ref.watch(taxFilingInfoProvider);
    final selfInfo = ref.watch(selfProvider);

    const Widget emptyCell = SizedBox();
    FilingStatus filingStatus = taxFilingInfo.filingStatus;

    return StockCard(
      title: 'Federal Tax Filing Information',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FixedColumnWidth(260.0),
          1: FixedColumnWidth(20.0),
          2: FixedColumnWidth(180.0),
          3: FixedColumnWidth(20.0),
          4: FixedColumnWidth(220.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: <TableRow>[
          TableRow(
            children: [
              Padding(
                padding: WidgetConstants.defaultOtherFieldPadding,
                child: DropdownMenu(
                  label: Text(
                    'Federal Filing Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  initialSelection: filingStatus,
                  errorText: _getFederalFilingStatusError(
                    selfInfo.isMarried,
                    filingStatus,
                  ),
                  dropdownMenuEntries: [
                    for (final filingStatus in FilingStatus.values)
                      DropdownMenuEntry<FilingStatus>(
                        value: filingStatus,
                        label: filingStatus.label,
                        enabled: isValidFederalFilingStatus(
                          selfInfo.isMarried,
                          filingStatus,
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    setState(() {
                      ref
                          .read(taxFilingInfoProvider.notifier)
                          .update(filingStatusEnum: value);
                      filingStatus = value!;
                    });
                  },
                ),
              ),
              emptyCell,
              Padding(
                padding: WidgetConstants.defaultOtherFieldPadding,
                child: CheckboxListTile(
                  title: Text(
                    'Use Standard Deduction',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  value: useFederalStandardDeduction,
                  onChanged: null,
                  tileColor: const Color.fromARGB(60, 166, 166, 166),
                ),
              ),
              emptyCell,
              emptyCell,
            ],
          ),
        ],
      ),
    );
  }
}
