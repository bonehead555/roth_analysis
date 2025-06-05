import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/providers/analysis_provider.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/table_view/filter_selector.dart';
import 'package:roth_analysis/widgets/utility/app_bar_divider.dart';
import 'package:roth_analysis/widgets/utility/scenario_selector.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Returns a [TableView] widget.
/// * [appBarController] - Provides ability for this widget to modify the parents [AppBar].

class TableView extends ConsumerStatefulWidget {
  const TableView({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<TableView> createState() => _TableViewState();
}

class _TableViewState extends ConsumerState<TableView> {
  PlanResult? planResults;
  ScenarioResult? selectedScenarioResult;
  TableViewFilter selectedFilter = TableViewFilter.overview;

  @override
  Widget build(BuildContext context) {
    // The screen needs to be updated any time configuration is changed and a new valid Plan ANlysis is generated.
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
          source: TableViewDataSource(
            scenarioResult: selectedScenarioResult!,
            activeFilter: selectedFilter,
          ),
          columnWidthMode: ColumnWidthMode.none,
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
          frozenColumnsCount: 1,
          onQueryRowHeight: (details) {
            // Set the row height as 70.0 to the column header row.
            return details.rowIndex == 0 ? 44.0 : 30.0;
          },
          /*onQueryRowHeight: (details) {
                  // Set the row height as 70.0 to the column header row.
                  return details.rowIndex == 0 ? 50.0 : 30.0;
                },*/
          columns: buildColumnList(selectedFilter),
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
      child: Text(
        text,
        overflow: TextOverflow.clip,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Returns a list of [GridColumn] to be used for the tables column headers.
  /// Returned list will be the appropriate hearders for the specified [activeFilter].
  List<GridColumn> buildColumnList(TableViewFilter activeFilter) {
    switch (activeFilter) {
      case TableViewFilter.taxDetails:
        return _buildTaxDetailsColumnList();
      case TableViewFilter.accountDetails:
        return _buildAccountDetailsColumnList();
      case TableViewFilter.overview:
        return _buildOverviewColumnList();
    }
  }

  /// Returns a list of [GridColumn] to be used for the tables column headers for overview table.
  List<GridColumn> _buildOverviewColumnList() {
    const double commonWidth = 120;
    return [
      GridColumn(
        columnName: 'year',
        width: 70,
        label: makeLabel('Year'),
      ),
      GridColumn(
        columnName: 'totalAssets',
        width: commonWidth,
        label: makeLabel('Total Assets'),
      ),
      GridColumn(
        columnName: 'savingsAssets',
        width: commonWidth,
        label: makeLabel('Savings Assets'),
      ),
      GridColumn(
        columnName: 'brokerageAssets',
        width: commonWidth,
        label: makeLabel('Brokerage Assets'),
      ),
      GridColumn(
        columnName: 'iraAssets',
        width: commonWidth,
        label: makeLabel('IRA Assets'),
      ),
      GridColumn(
        columnName: 'rothAssets',
        width: commonWidth,
        label: makeLabel('Roth Assets'),
      ),
      GridColumn(
        columnName: 'totalIncome',
        width: commonWidth,
        label: makeLabel('Total Income'),
      ),
      GridColumn(
        columnName: 'rmds',
        width: commonWidth,
        label: makeLabel('RMDs'),
      ),
      GridColumn(
        columnName: 'rothConverstions',
        width: commonWidth,
        label: makeLabel('Roth Conversions'),
      ),
      GridColumn(
        columnName: 'totalTaxes',
        width: commonWidth,
        label: makeLabel('Yearly Taxes'),
      ),
    ];
  }

  /// Returns a list of [GridColumn] to be used for the tables column headers for tax details table.
  List<GridColumn> _buildTaxDetailsColumnList() {
    const double commonWidth = 120;
    return [
      GridColumn(
        columnName: 'year',
        width: 70,
        label: makeLabel('Year'),
      ),
      GridColumn(
        columnName: 'magi',
        width: commonWidth,
        label: makeLabel('Federal MAGI'),
      ),
      GridColumn(
        columnName: 'cumulativeTaxes',
        width: commonWidth,
        label: makeLabel('Cumulative Taxes'),
      ),
      GridColumn(
        columnName: 'totalTaxes',
        width: commonWidth,
        label: makeLabel('Total Taxes'),
      ),
      GridColumn(
        columnName: 'federalTaxes',
        width: commonWidth,
        label: makeLabel('Federal Taxes'),
      ),
      GridColumn(
        columnName: 'stateTaxes',
        width: commonWidth,
        label: makeLabel('State Taxes'),
      ),
      GridColumn(
        columnName: 'localTaxes',
        width: commonWidth,
        label: makeLabel('Local Taxes'),
      ),
      GridColumn(
        columnName: 'ficaTaxes',
        width: commonWidth,
        label: makeLabel('FICA Taxes'),
      ),
      GridColumn(
        columnName: 'medicareTaxes',
        width: commonWidth,
        label: makeLabel('Medicare Taxes'),
      ),
      GridColumn(
        columnName: 'irmaaTaxes',
        width: commonWidth,
        label: makeLabel('IRMAA Taxes'),
      ),
    ];
  }

  /// Returns a list of [GridColumn] to be used for the tables column headers for account details table.
  List<GridColumn> _buildAccountDetailsColumnList() {
    const double commonWidth = 130;
    // First add a column for year.
    List<GridColumn> gridCols = [
      GridColumn(
        columnName: 'year',
        width: 70,
        label: makeLabel('Year'),
      ),
      GridColumn(
        columnName: 'totalAssets',
        width: commonWidth,
        label: makeLabel('All Account Total'),
      ),
    ];
    // Now add another column for each account.
    int columnNumber = 1;
    for (final account in planResults!.analysisConfig.accountInfos) {
      NumberFormat formatter = NumberFormat('0000');
      final String columnName = 'Acct${formatter.format(columnNumber++)}';
      gridCols.add(
        GridColumn(
          columnName: columnName,
          width: commonWidth,
          label: makeLabel(account.name),
        ),
      );
    }
    return gridCols;
  }

  /// Updates the provided [AppBarController] with the required widgets.
  void updateAppBar() {
    if (selectedScenarioResult == null) {
      return;
    }
    widget.appBarController.update(
      title: 'Results - Tabular',
      actionAdditions: [
        FilterSelector(
          activeFilter: selectedFilter,
          onSelected: (newSelectedFilter) {
            setState(() {
              selectedFilter = newSelectedFilter;
            });
          },
        ),
        const AppBarDivider(),
        ScenarioSelector(
          activeScenario: selectedScenarioResult,
          scenarioResults: planResults!.scenarioResults,
          onSelected: (newScenario) {
            setState(() {
              selectedScenarioResult = newScenario;
            });
          },
        )
      ],
    );
  }
}

/// [SfDataGrid] requires class that derived fom [DataGridSource] to provide the data for the
/// rows of the grid.
class TableViewDataSource extends DataGridSource {
  final TableViewFilter activeFilter;
  TableViewDataSource(
      {required ScenarioResult scenarioResult, required this.activeFilter}) {
    switch (activeFilter) {
      case TableViewFilter.taxDetails:
        dataGridRows = _buildTaxDetailsDataGridRows(scenarioResult);
        break;
      case TableViewFilter.accountDetails:
        dataGridRows = _buildAccountDetailsDataGridRows(scenarioResult);
      case TableViewFilter.overview:
        dataGridRows = _buildOverviewDataGridRows(scenarioResult);
        break;
    }
  }

  /// Returns row data for the overview table.
  static List<DataGridRow> _buildOverviewDataGridRows(
      ScenarioResult scenarioResult) {
    return scenarioResult.yearlyResults
        .map<DataGridRow>(
          (yearResults) => DataGridRow(
            cells: [
              DataGridCell<String>(
                columnName: 'date',
                value: showYyyy(
                  yearResults.targetYear,
                ),
              ),
              DataGridCell<String>(
                columnName: 'totalAssets',
                value: showDollarString(
                  yearResults.totalAssets,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'savingsAssets',
                value: showDollarString(
                  yearResults.savingsAssets,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'brokerageAssets',
                value: showDollarString(
                  yearResults.brokerageAssets,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'iraAssets',
                value: showDollarString(
                  yearResults.iraAssets,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'rothAssets',
                value: showDollarString(
                  yearResults.rothAssets,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'totalIncome',
                value: showDollarString(
                  yearResults.totalIncome,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'rmds',
                value: showDollarString(
                  yearResults.rmdDistribution,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'rothConversions',
                value: showDollarString(
                  yearResults.rothConversion,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'totalTaxes',
                value: showDollarString(
                  yearResults.totalTaxes,
                  showDollarSign: true,
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  /// Returns row data for the tax details table.
  static List<DataGridRow> _buildTaxDetailsDataGridRows(
      ScenarioResult scenarioResult) {
    return scenarioResult.yearlyResults
        .map<DataGridRow>(
          (yearResults) => DataGridRow(
            cells: [
              DataGridCell<String>(
                columnName: 'date',
                value: showYyyy(
                  yearResults.targetYear,
                ),
              ),
              DataGridCell<String>(
                columnName: 'magi',
                value: showDollarString(
                  yearResults.federalMAGI,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'cumulativeTaxes',
                value: showDollarString(
                  yearResults.cumulativeTaxes,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'totalTaxes',
                value: showDollarString(
                  yearResults.totalTaxes,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'federalTaxes',
                value: showDollarString(
                  yearResults.federalIncomeTax,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'stateTaxes',
                value: showDollarString(
                  yearResults.stateIncomeTax,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'localTaxes',
                value: showDollarString(
                  yearResults.localIncomeTax,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'ficaTaxes',
                value: showDollarString(
                  yearResults.ficaTax,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'medicareTaxes',
                value: showDollarString(
                  yearResults.medicareTax,
                  showDollarSign: true,
                ),
              ),
              DataGridCell<String>(
                columnName: 'irmaaTaxes',
                value: showDollarString(
                  yearResults.irmaaTax,
                  showDollarSign: true,
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  /// Returns row data for the account details table.
  static List<DataGridRow> _buildAccountDetailsDataGridRows(
      ScenarioResult scenarioResult) {
    return scenarioResult.yearlyResults.map<DataGridRow>((yearResults) {
      List<DataGridCell<dynamic>> dataGridCells = [
        DataGridCell<String>(
          columnName: 'date',
          value: showYyyy(
            yearResults.targetYear,
          ),
        ),
        DataGridCell<String>(
            columnName: 'totalAssets',
            value: showDollarString(
              yearResults.totalAssets,
              showDollarSign: true,
            )),
      ];
      // Now add another column for each account.
      int columnNumber = 1;
      for (final accountBalance in yearResults.accountBalances) {
        NumberFormat formatter = NumberFormat('0000');
        final String columnName = 'Acct${formatter.format(columnNumber++)}';
        dataGridCells.add(
          DataGridCell<String>(
            columnName: columnName,
            value: showDollarString(
              accountBalance,
              showDollarSign: true,
            ),
          ),
        );
      }
      return DataGridRow(cells: dataGridCells);
    }).toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: Alignment.center,
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
