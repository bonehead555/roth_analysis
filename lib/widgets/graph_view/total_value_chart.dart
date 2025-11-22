import 'package:flutter/material.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/widgets/graph_view/build_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const double iraNormalizationFactor = 0.6656;
const double taxableNormalizationFactor = 0.8523;

class TotalValueChart extends StatefulWidget {
  final String chartTitle;
  final List<ScenarioResult> scenarioResults;
  const TotalValueChart(
      {required this.chartTitle, required this.scenarioResults, super.key});

  @override
  State<TotalValueChart> createState() => _NonIraAssetsChartState();
}

class _NonIraAssetsChartState extends State<TotalValueChart> {
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
      yValueMapper: (YearResult yearResult, _) => (yearResult.rothAssets +
          yearResult.taxableAssets * taxableNormalizationFactor +
          yearResult.iraAssets * iraNormalizationFactor),
    );
  }
}
