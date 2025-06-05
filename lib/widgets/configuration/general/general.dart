import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/providers/person_provider.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'person.dart';
import 'plan_info.dart';

class General extends ConsumerStatefulWidget {
  const General({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  ConsumerState<General> createState() => _GeneralState();
}

class _GeneralState extends ConsumerState<General> {
  double requiredWidth = <double>[Person.requiredWidth, PlanInfoWidget.requiredWidth].reduce(max);

  @override
  void initState() {
    widget.appBarController.update(
      title: 'Configuration - General',
      actionAdditions: [],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const double interCardHeightGap = 8;
    final PersonInfo selfInfo = ref.watch(selfProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: requiredWidth,
        child: Padding(
          padding: const EdgeInsets.all(interCardHeightGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Person(isSelf: true),
              const SizedBox(height: interCardHeightGap),
              if (selfInfo.isMarried) ...[
                const Person(isSelf: false),
                const SizedBox(height: interCardHeightGap),
              ],
              const PlanInfoWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
