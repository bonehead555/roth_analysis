import 'package:flutter/material.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';

/// Widget that can deisplay the contents of a [MessageService].
/// * [header] - Header text to be displayed at the top of the dialog.
/// * [messageService] - Contains any errors/warnings/info that should be displayed.
/// * [width] - Width of the widget.
class MessagesView extends StatefulWidget {
  const MessagesView({
    super.key,
    required this.header,
    required this.messageService,
    required this.width,
  });
  final String header;
  final MessageService messageService;
  final double width;

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  late MessageDataSource _messageDataSource;

  @override
  void initState() {
    super.initState();
    _messageDataSource =
        MessageDataSource(messageService: widget.messageService);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      height: 500,
      width: widget.width,
      //height: dialogHeight,
      child: Column(
        children: [
          Text(widget.header,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.primary)),
          SfDataGridTheme(
            data: SfDataGridThemeData(
                headerColor: Theme.of(context).colorScheme.inversePrimary),
            child: Expanded(
              child: SfDataGrid(
                source: _messageDataSource,
                columnWidthMode: ColumnWidthMode.lastColumnFill,
                gridLinesVisibility: GridLinesVisibility.both,
                headerGridLinesVisibility: GridLinesVisibility.both,
                onQueryRowHeight: (details) {
                  return details.getIntrinsicRowHeight(details.rowIndex);
                },
                /*onQueryRowHeight: (details) {
                  // Set the row height as 70.0 to the column header row.
                  return details.rowIndex == 0 ? 50.0 : 30.0;
                },*/
                columns: [
                  GridColumn(
                      columnName: 'type',
                      minimumWidth: 100,
                      label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.center,
                          child: const Text(
                            'Type',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'message',
                      label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Message',
                            overflow: TextOverflow.ellipsis,
                          ))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageDataSource extends DataGridSource {
  MessageDataSource({required MessageService messageService}) {
    dataGridRows = messageService
        .getMessages()
        .map<DataGridRow>((message) => DataGridRow(cells: [
              DataGridCell<String>(
                  columnName: 'type', value: message.severity.label),
              DataGridCell<String>(
                  columnName: 'message', value: message.message),
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
        alignment: dataGridCell.columnName == 'type'
            ? Alignment.center
            : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: dataGridCell.columnName == 'message'
            ? Text(dataGridCell.value.toString())
            : Text(
                dataGridCell.value.toString(),
                overflow: TextOverflow.ellipsis,
              ),
      );
    }).toList());
  }
}
