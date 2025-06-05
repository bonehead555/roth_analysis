import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/configuration/tax_filing/federal_tax_filing_widget.dart';
import 'package:roth_analysis/widgets/configuration/tax_filing/local_tax_filing_widget.dart';
import 'package:roth_analysis/widgets/configuration/tax_filing/state_filing_widget.dart';

class TaxFilingWidget extends ConsumerStatefulWidget {
  const TaxFilingWidget({super.key, required this.appBarController});

  final AppBarController appBarController;

   @override
  ConsumerState<TaxFilingWidget> createState() => _TaxFilingWidgetState();
}

class _TaxFilingWidgetState extends ConsumerState<TaxFilingWidget> {
   static const List<double> childRequiredWidths = [
    FederalTaxFilingWidget.requiredWidth,
    StateTaxFilingWidget.requiredWidth,
    LocalTaxFilingWidget.requiredWidth,
  ];

  @override
  void initState() {
    widget.appBarController.update(
      title: 'Configuration - Tax Filing',
      actionAdditions: [],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Widget cardGap = SizedBox(height: 8);
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: childRequiredWidths.reduce(max),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FederalTaxFilingWidget(),
              cardGap,
              StateTaxFilingWidget(),
              cardGap,
              LocalTaxFilingWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
