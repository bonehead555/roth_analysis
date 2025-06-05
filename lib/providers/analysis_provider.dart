import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/services/analysis_services/plan_analysis.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'accounts_provider.dart';
import 'income_sources_provider.dart';
import 'person_provider.dart';
import 'scenarios_provider.dart';
import 'tax_filing_info_provider.dart';
import 'plan_provider.dart';

/// Typedef for a record that returns useful state regarding the current configuration.
/// * configChnaged - since the last time the reset method was called.
/// * configErrors - MessageService holding errors from the last checked configuration.
/// * planResults - Analysis results for the last valid configuration.  If NOT valid, null is returned.
typedef AnalysisConfigState = ({
  bool configChanged,
  MessageService configErrors,
  PlanResult? planResults
});

/// Riverpod provider that is updated if any of the various configuration providers.
/// When updated, it is determined whether the configuration is valid and if valid
/// an anlysis is run for the plan.
///
/// Returns
class AnalysisProvider extends StateNotifier<AnalysisConfigState> {
  AnalysisProvider(super.newState);
  MessageService latestMessageService = MessageService();
  PlanResult? latesPlanResults;

  AnalysisConfigState validateConfiguration(WidgetRef ref) {
    // If configuration has not been chnaged since the last validation, take no action and return previous state.
    if (!ref.read(configChangedProvider)) {
      return state;
    }
    // Collect modified configuration information.
    final planInfo = ref.read(planProvider);
    final self = ref.read(selfProvider);
    final spouse = ref.read(spouseProvider);
    final taxFilingInfo = ref.read(taxFilingInfoProvider);
    final accountInfos = ref.read(accountInfoProvider);
    final incomeInfos = ref.read(incomeInfoProvider);
    final scenarioInfos = ref.read(scenarioInfosProvider);
    PlanResult? planResult;
    // Initalize an analysis configuration and check if errors.
    final analysisConfig = AnalysisConfig(
        planInfo: planInfo,
        taxFilingInfo: taxFilingInfo,
        self: self,
        spouse: spouse,
        accountInfos: accountInfos,
        incomeInfos: incomeInfos,
        scenarioInfos: scenarioInfos);
    final messageService = analysisConfig.messageService;
    // If there were nor errors, run the plan anlysis
    if (messageService.counts == 0) {
      planResult = PlanAnalysis(analysisConfig: analysisConfig).planResults;
    }
    // We've processed the configuration so it is not longer new / changed.
    ref.read(configChangedProvider.notifier).state = false;
    // Create new state information, update the provider state and also return it.
    final AnalysisConfigState newState = (
      configChanged: true,
      configErrors: messageService,
      planResults: planResult
    );
    state = newState;
    return newState;
  }
}

typedef AnalysisNotifierProvider
    = StateNotifierProvider<AnalysisProvider, AnalysisConfigState>;

  final analysisProvider = AnalysisNotifierProvider((ref) {
   return AnalysisProvider((
    configChanged: true,
    configErrors: MessageService(),
    planResults: null
  ));
});


/// Simple provider that is chnaged to true if any of the configurtion providers is set to true.
/// Should be reset to false, whenever the configuration is validated.
class ConfigChangedProvider extends StateNotifier<bool> {
  ConfigChangedProvider() : super(true);
}
typedef ConfigChangedNotifierProvider
    = StateNotifierProvider<ConfigChangedProvider, bool>;

final configChangedProvider = ConfigChangedNotifierProvider((ref) {
  ref.watch(planProvider);
  ref.watch(selfProvider);
  ref.watch(spouseProvider);
  ref.watch(taxFilingInfoProvider);
  ref.watch(accountInfoProvider);
  ref.watch(incomeInfoProvider);
  ref.watch(scenarioInfosProvider);
  return ConfigChangedProvider();
});

