import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/providers/analysis_provider.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/services/analysis_services/transaction_log.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/utility/scenario_selector.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Returns a TransactionView widget.
/// * [appBarController] - Provides ability for this widget to modify the parents [AppBar].
class TransactionView extends ConsumerStatefulWidget {
  const TransactionView({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends ConsumerState<TransactionView> {
  PlanResult? planResults;
  ScenarioResult? selectedScenarioResult;
  final TextEditingController scenarioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // The screen needes to be updated any time configuration is changed and a new valid Plan ANlysis is generated.
    final analysisConfigState = ref.watch(analysisProvider);
    planResults = analysisConfigState.planResults;
    // planResults could temporarily be null as the parent widget can be created before
    // a valid configuration exists.
    if (planResults == null) {
      return Container();
    }
    // Validate that the selectedScenarioResult is still valid in the context of the plan's
    // scenario results which could have changed in the ref.watch above.
    selectedScenarioResult = ScenarioSelector.validateScenarioResult(
        planResults!.scenarioResults, selectedScenarioResult);

    updateAppBar();
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      child: SfDataGridTheme(
        data: SfDataGridThemeData(
          headerColor: Theme.of(context).colorScheme.primary,
          //gridLineColor: Theme.of(context).colorScheme.primary,
        ),
        child: SfDataGrid(
          source: TransactionLogDataSource(
              transactionLog: selectedScenarioResult!.transactionLog),
          columnWidthMode: ColumnWidthMode.auto,
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
          frozenColumnsCount: 1,
          onQueryRowHeight: (details) {
            //return details.getIntrinsicRowHeight(details.rowIndex);
            return 30;
          },
          /*onQueryRowHeight: (details) {
                  // Set the row height as 70.0 to the column header row.
                  return details.rowIndex == 0 ? 50.0 : 30.0;
                },*/
          columns: buildColumnList(),
        ),
      ),
    );
  }

  /// Returns a widget intended to be used as a label for the SyncFusion [SfDataGrid].
  /// * [text] - String to be used for the label.
  /// * [horizontalPad] - Amount of hotzontal pad to be used around the [text].
  /// * [alignment] - How the label should be aligned with the table column header.
  Widget makeLabel(
    String text, {
    double horizontalPad = 16.0,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      alignment: alignment,
      child: Text(text,
          overflow: TextOverflow.clip,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
    );
  }

  /// Returns a list of [GridColumn] to be used for the tables column headers.
  List<GridColumn> buildColumnList() {
    const double commonWidth = 120;
    return [
      GridColumn(
        columnName: 'date',
        minimumWidth: 70,
        label: makeLabel('Date'),
      ),
      GridColumn(
        columnName: 'type',
        minimumWidth: commonWidth,
        label: makeLabel('Activity'),
      ),
      GridColumn(
        columnName: 'account',
        minimumWidth: commonWidth,
        label: makeLabel('Account'),
      ),
      GridColumn(
        columnName: 'amount',
        minimumWidth: commonWidth,
        label: makeLabel('Amount'),
      ),
      GridColumn(
        columnName: 'balance',
        minimumWidth: commonWidth,
        label: makeLabel('Balance'),
      ),
      GridColumn(
        columnName: 'memo',
        width: 300,
        label: makeLabel(
          'Memo',
          horizontalPad: 8.0,
          alignment: Alignment.centerLeft,
        ),
      ),
    ];
  }

  /// Updates the provided [AppBarController] with the required widgets.
  void updateAppBar() {
    if (selectedScenarioResult == null) {
      return;
    }
    widget.appBarController.update(
      title: 'Results - Transaction Log',
      actionAdditions: [
        ScenarioSelector(
          activeScenario: selectedScenarioResult,
          scenarioResults: planResults!.scenarioResults,
          onSelected: (scenarioResult) => {
              setState(() {
                selectedScenarioResult = scenarioResult;
              })},          
        )
      ],
    );
  }
}

/// [SfDataGrid] requires class that derived fom [DataGridSource] to provide the data for the 
/// rows of the grid.
class TransactionLogDataSource extends DataGridSource {
  TransactionLogDataSource({required TransactionLog transactionLog}) {
    dataGridRows = transactionLog.entries
        .map<DataGridRow>((logEntry) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'date', value: logEntry.when),
              DataGridCell<String>(
                  columnName: 'type', value: logEntry.transactionType.label),
              DataGridCell<String>(
                  columnName: 'account', value: logEntry.accountName),
              DataGridCell<String>(
                  columnName: 'amount',
                  value: logEntry.amount.isNaN
                      ? ''
                      : showDollarString(logEntry.amount,
                          showCents: true, showDollarSign: true)),
              DataGridCell<String>(
                  columnName: 'balance',
                  value: showDollarString(logEntry.accountBalance,
                      showCents: true, showDollarSign: true)),
              DataGridCell<String>(columnName: 'memo', value: logEntry.memo),
            ]))
        .toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: dataGridCell.columnName == 'memo'
            ? Alignment.centerLeft
            : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          dataGridCell.value.toString(),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.0),
        ),
      );
    }).toList());
  }
}
