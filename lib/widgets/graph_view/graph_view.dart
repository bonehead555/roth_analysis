import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/providers/analysis_provider.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/graph_view/cumulative_taxes_chart.dart';
import 'package:roth_analysis/widgets/graph_view/ira_assets_chart.dart';
import 'package:roth_analysis/widgets/graph_view/non_ira_assets_chart.dart';
import 'package:roth_analysis/widgets/graph_view/roth_assets_chart.dart';
import 'package:roth_analysis/widgets/graph_view/series_selector.dart';
import 'package:roth_analysis/widgets/graph_view/taxable_assets_chart.dart';
import 'package:roth_analysis/widgets/graph_view/total_assets_chart.dart';
import 'package:roth_analysis/widgets/graph_view/total_taxes_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphView extends ConsumerStatefulWidget {
  final AppBarController appBarController;
  const GraphView({super.key, required this.appBarController});

  @override
  ConsumerState<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  PlanResult? planResults;
  SeriesSelection selectedSeries = SeriesSelection.totalAssets;
  SfCartesianChart? totalAssetsChart;
  SfCartesianChart? iraAssetsChart;
  SfCartesianChart? rothAssetsChart;
  SfCartesianChart? nonIraAssetsChart;
  SfCartesianChart? taxableAssetsChart;
  SfCartesianChart? totalTaxesChart;

  @override
  Widget build(BuildContext context) {
    // The screen needs to be updated any time configuration is changed and a new valid Plan ANlysis is generated.
    final analysisConfigState = ref.watch(analysisProvider);
    planResults = analysisConfigState.planResults;
    if (planResults == null) {
      return Container();
    }
    updateAppBar();
    return selectedChart;
  }

  String get chartTitle {
    return selectedSeries.label;
  }

  Widget get selectedChart {
   switch (selectedSeries) {
      case SeriesSelection.totalAssets:
        return TotalAssetsChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.iraAssets:
        return IraAssetsChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.rothAssets:
        return RothAssetsChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.nonIraAssets:
        return NonIraAssetsChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.taxableAssets:
        return TaxableAssetsChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.totalTaxes:
        return TotalTaxesChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
      case SeriesSelection.cumulativeTaxes:
        return CumulativeTaxesChart(chartTitle: chartTitle, scenarioResults: planResults!.scenarioResults);
    }
  }

  List<CartesianSeries> chartSeries(SeriesSelection selectedSeries) {
    return planResults!.scenarioResults
        .map<SplineSeries<YearResult, int>>((scenarioResult) {
      return SplineSeries<YearResult, int>(
        color: scenarioResult.colorOption.color,
        name: scenarioResult.scenarioName,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        enableTooltip: true,
        xValueMapper: (YearResult yearResult, _) => yearResult.targetYear,
        yValueMapper: yValueMapper(selectedSeries),
        dataSource: scenarioResult.yearlyResults,
      );
    }).toList();
  }

  num? Function(YearResult, int) yValueMapper(SeriesSelection selectedSeries) {
    switch (selectedSeries) {
      case SeriesSelection.totalAssets:
        return (YearResult yearResult, _) => yearResult.totalAssets;
      case SeriesSelection.iraAssets:
        return (YearResult yearResult, _) => yearResult.iraAssets;
      case SeriesSelection.rothAssets:
        return (YearResult yearResult, _) => yearResult.rothAssets;
      case SeriesSelection.nonIraAssets:
        return (YearResult yearResult, _) => (yearResult.taxableAssets + yearResult.rothAssets);
      case SeriesSelection.taxableAssets:
        return (YearResult yearResult, _) => yearResult.taxableAssets;
      case SeriesSelection.totalTaxes:
        return (YearResult yearResult, _) => yearResult.totalTaxes;
      case SeriesSelection.cumulativeTaxes:
        return (YearResult yearResult, _) => yearResult.cumulativeTaxes;
    }
  }

  void updateAppBar() {
    if (planResults == null) {
      return;
    }
    widget.appBarController.update(
      title: 'Results - Graphical',
      actionAdditions: [
        SeriesSelector(
          activeSeries: selectedSeries,
          onSelected: (newSelectedFilter) {
            setState(() {
              selectedSeries = newSelectedFilter;
            });
          },
        ),
      ],
    );
  }
}
