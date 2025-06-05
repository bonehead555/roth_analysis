import 'package:flutter/material.dart';

/// Widget used to indicate that there are no items to display.
/// * [itemName] - Name of the type of item that should be displayed.
class EmptyList extends StatelessWidget {
  final String itemName;
  const EmptyList({required this.itemName, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64),
      child: Text(
        'No "$itemName" currently exist. \n\nUse the "+" button in the AppBar above to create one or more "$itemName".',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
