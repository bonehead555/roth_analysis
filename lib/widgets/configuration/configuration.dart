import 'package:flutter/material.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:roth_analysis/widgets/scenarios/roth_scenarios.dart';
import 'accounts/accounts.dart';
import '../income_sources/income_sources.dart';
import 'general/general.dart';
import 'tax_filing/tax_filing_widget.dart';

class Configuration extends StatefulWidget {
  const Configuration({super.key, required this.appBarController});

  final AppBarController appBarController;

  @override
  State<Configuration> createState() => _ConfigurationState();
}

class _ConfigurationState extends State<Configuration> {
  ActionAdditions appBarAdditions = [];
  String appBarTitle = '';



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              children: [
                General(appBarController: widget.appBarController),
                TaxFilingWidget(appBarController: widget.appBarController),
                IncomeSources(appBarController: widget.appBarController),
                Accounts(appBarController: widget.appBarController),
                RothScenarios(appBarController: widget.appBarController),
              ],
            ),
          ),
          const TabBar(
            indicatorPadding: EdgeInsets.only(bottom: 10),
            //textScaler: TextScaler.linear(0.9),
            tabs: [
              Tooltip(
                message: 'Information regarding Self & Spouse',
                child: Tab(
                  text: 'General',
                  //icon: Icon(Icons.ac_unit),
                  height: 40,
                ),
              ),
              Tooltip(
                message: 'Information regarding Filing Taxes',
                child: Tab(
                  text: 'Tax Filing',
                  //icon: Icon(Icons.access_alarm_outlined),
                  height: 40,
                ),
              ),
              Tooltip(
                message: 'Information regarding Sources of Income',
                child: Tab(
                  text: 'Income Sources',
                  //icon: Icon(Icons.access_alarm_outlined),
                  height: 40,
                ),
              ),
              Tooltip(
                message: 'Information regarding Savings and Brokerage Accounts',
                child: Tab(
                  text: 'Accounts',
                  //icon: Icon(Icons.ac_unit),
                  height: 40,
                ),
              ),
              Tooltip(
                message: 'Information regarding the Roth Conversiion Scenarios to Test',
                child: Tab(
                  text: 'Roth Scenarios',
                  //icon: Icon(Icons.ac_unit),
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
