import 'package:flutter/material.dart';

/// Divide widget to be used to seperate groups of items in the AppBar.
class AppBarDivider extends StatelessWidget {
  const AppBarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    const double extraSpace = 15;
    return Row(
      children: [
        const SizedBox(width: extraSpace),
        VerticalDivider(
          thickness: 1,
          width: 1,
          indent: 5,
          endIndent: 5,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: extraSpace),
      ],
    );
  }
}
