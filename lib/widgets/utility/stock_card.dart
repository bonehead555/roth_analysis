import 'package:flutter/material.dart';

class StockCard extends StatelessWidget {
  const StockCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Colors.grey,
          width: 2,
        ),
      ),
      //color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 5),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Divider(
                thickness: 2,
                height: 5.0,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
