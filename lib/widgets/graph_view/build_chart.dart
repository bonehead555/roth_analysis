import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

typedef YValueMapper = num? Function(YearResult, int);

TrackballBehavior buildTrackball() {
  return TrackballBehavior(
    enable: true,
    hideDelay: 15000.0,
    tooltipSettings: const InteractiveTooltip(
        enable: true, color: Color.fromARGB(255, 141, 198, 244)),
  );
}

Widget buildChart(
    {required String chartTitle,
    required List<ScenarioResult> scenarioResults,
    required TrackballBehavior trackballBehavior,
    required YValueMapper yValueMapper,
    required}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 16.0),
      child: SfCartesianChart(
        trackballBehavior: trackballBehavior,
        title: ChartTitle(text: chartTitle),
        primaryXAxis: const NumericAxis(
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          title: AxisTitle(
              text: 'Year', textStyle: TextStyle(fontWeight: FontWeight.bold)),
        ),
        primaryYAxis: NumericAxis(
          title: const AxisTitle(
            text: 'Dollars',
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          numberFormat: NumberFormat.compactCurrency(
              locale: 'en_US', symbol: '\$', decimalDigits: 0),
        ),
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true, duration: 1000),
        series: _chartSeries(scenarioResults, yValueMapper),
      ),
    ),
  );
}

List<CartesianSeries> _chartSeries(
    List<ScenarioResult> scenarioResults, YValueMapper yValueMapper) {
  return scenarioResults.map<LineSeries<YearResult, int>>((scenarioResult) {
    return LineSeries<YearResult, int>(
      animationDuration: 1000.0,
      color: scenarioResult.colorOption.color,
      name: scenarioResult.scenarioName,
      dataLabelSettings: const DataLabelSettings(isVisible: false),
      markerSettings: const MarkerSettings(
          isVisible: true,
          // Marker shape is set to diamond
          shape: DataMarkerType.invertedTriangle),
      enableTooltip: true,
      xValueMapper: (YearResult yearResult, _) => yearResult.targetYear,
      yValueMapper: yValueMapper,
      dataSource: scenarioResult.yearlyResults,
    );
  }).toList();
}
