import 'package:flutter/material.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/graph_view/build_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Record containing normilization factors for Traditonal IRA and Taxable assets
/// when compared to Roth IRA Assets.
/// * iraNormalizationFactor - Factor to normalize Traditonal IRA assets to Roth IRA assets.
/// * taxableNormalizationFactor - Factor to normalize Taxable assets to Roth IRA assets.
/// MAGI limit was configured.
typedef NormilizationFactors = ({
  double iraNormalizationFactor,
  double taxableNormalizationFactor,
});

NormilizationFactors getNorimilaztionFactors(
    {required int targetYear, required double iraValue}) {
  // The result matrix below was designed for 2025 values
  iraValue = adjustForTime(
      valueToAdjust: iraValue, toYear: 2025, fromYear: targetYear);

  // Now determine which normilization factors to use based on the size of the iraValue
  switch (iraValue) {
    case < 600000:
      return (
        iraNormalizationFactor: 0.6880,
        taxableNormalizationFactor: 0.8622
      ); // 26%
    case < 1000000:
      return (
        iraNormalizationFactor: 0.6768,
        taxableNormalizationFactor: 0.8573
      ); // 27%
    case < 1300000:
      return (
        iraNormalizationFactor: 0.6656,
        taxableNormalizationFactor: 0.8523
      ); // 28%
    case < 1700000:
      return (
        iraNormalizationFactor: 0.6546,
        taxableNormalizationFactor: 0.8475
      ); // 29%
    case < 2100000:
      return (
        iraNormalizationFactor: 0.6436,
        taxableNormalizationFactor: 0.8426
      ); // 30%
    case < 2500000:
      return (
        iraNormalizationFactor: 0.6326,
        taxableNormalizationFactor: 0.8378
      ); // 31%
    case < 3100000:
      return (
        iraNormalizationFactor: 0.6217,
        taxableNormalizationFactor: 0.8329
      ); // 32%
    case < 3800000:
      return (
        iraNormalizationFactor: 0.6109,
        taxableNormalizationFactor: 0.8282
      ); // 33%
    case < 4900000:
      return (
        iraNormalizationFactor: 0.6001,
        taxableNormalizationFactor: 0.8234
      ); // 34%
    case < 6100000:
      return (
        iraNormalizationFactor: 0.5893,
        taxableNormalizationFactor: 0.8186
      ); // 35%
    case < 8000000:
      return (
        iraNormalizationFactor: 0.5787,
        taxableNormalizationFactor: 0.8139
      ); // 36%
    case < 11000000:
      return (
        iraNormalizationFactor: 0.5680,
        taxableNormalizationFactor: 0.8092
      ); // 37%
    case < 19000000:
      return (
        iraNormalizationFactor: 0.5575,
        taxableNormalizationFactor: 0.8046
      ); // 38%
    case < 55000000:
      return (
        iraNormalizationFactor: 0.5470,
        taxableNormalizationFactor: 0.7999
      ); // 39%
    default:
      return (
        iraNormalizationFactor: 0.5365,
        taxableNormalizationFactor: 0.7953
      ); // 40%
  }
}

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
      yValueMapper: (YearResult yearResult, _) {
        var (:iraNormalizationFactor, :taxableNormalizationFactor) =
            getNorimilaztionFactors(
                targetYear: yearResult.targetYear,
                iraValue: yearResult.iraAssets);
        return (yearResult.rothAssets +
            yearResult.taxableAssets * taxableNormalizationFactor +
            yearResult.iraAssets * iraNormalizationFactor);
      },
    );
  }
}
