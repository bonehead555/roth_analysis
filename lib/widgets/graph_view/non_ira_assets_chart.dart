import 'package:flutter/material.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/widgets/graph_view/build_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NonIraAssetsChart extends StatefulWidget {
  final String chartTitle;
  final List<ScenarioResult> scenarioResults;
  const NonIraAssetsChart(
      {required this.chartTitle, required this.scenarioResults, super.key});

  @override
  State<NonIraAssetsChart> createState() => _NonIraAssetsChartState();
}

class _NonIraAssetsChartState extends State<NonIraAssetsChart> {
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    _trackballBehavior = buildTrackball();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildChart(
      chartTitle: widget.chartTitle,
      scenarioResults: widget.scenarioResults,
      trackballBehavior: _trackballBehavior,
      yValueMapper: (YearResult yearResult, _) => (yearResult.taxableAssets + yearResult.rothAssets),
    );
  }
}
