import 'package:flutter/material.dart';

/// Supported Filters for the TableView Widget
enum TableViewFilter {
  overview('Overview'),
  taxDetails('Tax Details'),
  accountDetails('Account Details');

  final String label;

  const TableViewFilter(this.label);
}

/// Widtget that provides selection of one of N supported TableView filters.
/// * activeFilter - The filter that is currently active / selected.
/// * onSelected - Callback that provides the new filter that was selected.
class FilterSelector extends StatefulWidget {
  const FilterSelector({
    super.key,
    required this.activeFilter,
    required this.onSelected,
  });
  final TableViewFilter? activeFilter;
  final Function(TableViewFilter) onSelected;

  @override
  State<FilterSelector> createState() => _FilterSelectorState();
}

class _FilterSelectorState extends State<FilterSelector> {
  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Select Filter',
      child: Row(
        children: [
          Text(
            'Filter:  ',
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          DropdownMenu<TableViewFilter>(
            initialSelection: widget.activeFilter,
            controller: controller,
            textStyle: Theme.of(context).textTheme.labelLarge,
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              isDense: true,
            ),
            dropdownMenuEntries: [
              for (final filter in TableViewFilter.values)
                DropdownMenuEntry<TableViewFilter>(
                  value: filter,
                  label: filter.label,
                ),
            ],
            onSelected: (selection) {
              if (selection != null) {
                widget.onSelected(selection);
              }
            },
          ),
        ],
      ),
    );
  }
}
