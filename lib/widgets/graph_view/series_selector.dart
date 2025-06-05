import 'package:flutter/material.dart';

/// Supported Graph Series
enum SeriesSelection {
  totalAssets('Total Assets'),
  iraAssets('IRA Assets'),
  rothAssets('Roth Assets'),
  nonIraAssets('Non-IRA Assets'),
  taxableAssets('Taxable Assets'),
  totalTaxes('Yearly Taxes'),
  cumulativeTaxes('Cumulative Taxes');

  final String label;

  const SeriesSelection(this.label);
}

/// Widtget that provides selection of one of N supported series for the graph.
/// * activeSeries - The filseriester that is currently active / selected.
/// * onSelected - Callback that provides the new series was selected.
class SeriesSelector extends StatefulWidget {
  const SeriesSelector({
    super.key,
    required this.activeSeries,
    required this.onSelected,
  });
  final SeriesSelection? activeSeries;
  final Function(SeriesSelection) onSelected;

  @override
  State<SeriesSelector> createState() => _SeriesSelectorState();
}

class _SeriesSelectorState extends State<SeriesSelector> {
  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Select Series',
      child: Row(
        children: [
          Text(
            'Series:  ',
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          DropdownMenu<SeriesSelection>(
            initialSelection: widget.activeSeries,
            controller: controller,
            textStyle: Theme.of(context).textTheme.labelLarge,
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              isDense: true,
            ),
            dropdownMenuEntries: [
              for (final filter in SeriesSelection.values)
                DropdownMenuEntry<SeriesSelection>(
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
