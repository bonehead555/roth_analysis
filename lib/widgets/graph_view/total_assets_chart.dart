import 'package:flutter/material.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/widgets/graph_view/build_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TotalAssetsChart extends StatefulWidget {
  final String chartTitle;
  final List<ScenarioResult> scenarioResults;
  const TotalAssetsChart(
      {required this.chartTitle, required this.scenarioResults, super.key});

  @override
  State<TotalAssetsChart> createState() => _TotalAssetsChartState();
}

class _TotalAssetsChartState extends State<TotalAssetsChart> {
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
      yValueMapper: (YearResult yearResult, _) => yearResult.totalAssets,
    );
  }
}
