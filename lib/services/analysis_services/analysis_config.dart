import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/data/plan_info.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/data/tax_filing_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/providers/scenarios_provider.dart';
import 'package:roth_analysis/services/analysis_services/rmd_estimator.dart';
import 'package:roth_analysis/services/analysis_services/transaction_log.dart';
import 'package:roth_analysis/services/message_service.dart';

/// Class that provides configuration information needed ofr the analysis of the overall Roth conversion.
/// [_planInfo] - holds the as configured plan information.
/// [_taxFilingInfo] - holds the as configured tax filing information.
/// [_self] - holds the as configured information about the primary person in the plan.
/// [_spouse] - holds the as configured information for the spouse (if one exists).
/// [_accountInfos] - holds the as configured information for all investment/savings accounts.
/// [_incomeInfos] - holds the as configured information for all souurces of income.
/// [_scenarioInfos] - holds the as configured information for all Roth conversion scenarios to analyze.
/// [_currentScenario] - transient value that holds configured information for a scenario when that
/// scenario is in the process of being analysied.
class AnalysisConfig {
  final PlanInfo _planInfo;
  final TaxFilingInfo _taxFilingInfo;
  final PersonInfo _self;
  final PersonInfo? _spouse;
  final AccountInfos _accountInfos;
  final IncomeInfos _incomeInfos;
  final ScenarioInfos _scenarioInfos;
  late ScenarioInfo? _currentScenario;
  final MessageService _messageService = MessageService();
  final TransactionLog _transactionLog = TransactionLog();

  /// Constructor
  /// [planInfo] - provides the as configured plan information.
  /// [taxFilingInfo] - provides the as configured tax filing information.
  /// [self] - provides the as configured information about the primary person in the plan.
  /// [spouse] - provides the as configured information for the spouse (if one exists).
  /// [accountInfos] - provides the as configured information for all investment/savings accounts.
  /// [incomeInfos] - provides the as configured information for all souurces of income.
  /// [scenarioInfos] - provides the as configured information for all Roth conversion scenarios to analyze.
  /// [currentScenario] - transient value that holds configured information for a scenario when that
  /// scenario is in the process of being analysied.
  /// If no [currentScenario] is provided [scenarioInfos] first element is assumed
  /// Note: Inputs are valdated and an exception is thrown when data is found to be invalid.
  AnalysisConfig({
    required PlanInfo planInfo,
    required TaxFilingInfo taxFilingInfo,
    required PersonInfo self,
    required PersonInfo? spouse,
    required AccountInfos accountInfos,
    required IncomeInfos incomeInfos,
    required ScenarioInfos scenarioInfos,
    ScenarioInfo? currentScenario,
  })  : _planInfo = planInfo,
        _taxFilingInfo = taxFilingInfo,
        _self = self,
        _spouse = spouse,
        _accountInfos = accountInfos,
        _incomeInfos = incomeInfos,
        _scenarioInfos = scenarioInfos {
    _currentScenario =
        currentScenario ?? (scenarioInfos.isEmpty ? null : scenarioInfos[0]);

    // Perform error checks on input data so that we analysis functions can use it safely
    planInfo.validate(_messageService);
    taxFilingInfo.validate(_messageService, isMarried);

    self.validate(_messageService, OwnerType.self);
    if (isMarried && spouse == null) {
      messageService.addError(
          'Person: Filing status of married requires spouse information to be defined.');
    }
    if (isMarried && spouse != null) {
      spouse.validate(_messageService, OwnerType.spouse);
    }

    bool hasSavingsAccount = false;
    bool hasIraAccount = false;
    bool hasRothAccount = false;
    for (final accountInfo in accountInfos) {
      accountInfo.validate(_messageService, isMarried);
      hasSavingsAccount =
          hasSavingsAccount || (accountInfo.type == AccountType.taxableSavings);
      hasIraAccount = hasIraAccount ||
          (accountInfo.type == AccountType.traditionalIRA &&
              accountInfo.owner == OwnerType.self);
      hasRothAccount = hasRothAccount ||
          (accountInfo.type == AccountType.rothIRA &&
              accountInfo.owner == OwnerType.self);
    }
    if (!hasSavingsAccount) {
      messageService.addError(
          'Accounts: At least one taxable savings account is required.');
    }
    if (!hasIraAccount) {
      messageService.addError(
          'Accounts: At least one self-owned traditional IRA account is required.');
    }
    if (!hasRothAccount) {
      messageService.addError(
          'Accounts: At least one self-owned ROTH IRA account is required.');
    }

    int incomeEntryNumber = 1;
    for (final incomeInfo in incomeInfos) {
      incomeInfo.validate(
        _messageService,
        incomeEntryNumber++,
        isMarried: isMarried,
        planStartDate: planInfo.planStartDate,
        planEndDate: planInfo.planEndDate,
      );
    }

    if (scenarioInfos.isEmpty) {
      messageService.addError(
          'Scenarios: At least one ROTH conversion scenario is required.');
    }
    for (final scenarioInfo in scenarioInfos) {
      scenarioInfo.validate(
        messageService: _messageService,
        planStartDate: planInfo.planStartDate,
        planEndDate: planInfo.planEndDate,
        rmdStartDate: selfInfo.birthDate != null ? DateTime(rmdStartYear(selfInfo.birthDate!)) : null,
      );
    }
  }

  /// Creates a copy of the current Analysis but with a different [currentScenario]
  AnalysisConfig copyWithCurrentScenario(ScenarioInfo currentScenario) {
    return AnalysisConfig(
      planInfo: _planInfo,
      taxFilingInfo: _taxFilingInfo,
      self: _self,
      spouse: _spouse,
      accountInfos: _accountInfos,
      incomeInfos: _incomeInfos,
      scenarioInfos: _scenarioInfos,
      currentScenario: currentScenario,
    );
  }

  /// Returns as configured [PlanInfo].
  PlanInfo get planInfo => _planInfo;

  /// Returns as configured plan start year.
  int get planStartYear => planInfo.planStartDate!.year;

  /// Returns as configured plan start month.
  int get planStartMonth => planInfo.planStartDate!.month;

  /// Returns true if specified year matches the plan start year.
  bool isStartYear(int year) => year == planStartYear;

  /// Returns as configured plan end year.
  int get planEndYear => planInfo.planEndDate!.year;

  /// Returns as configured plan end month.
  int get planEndMonth => planInfo.planEndDate!.month;

  /// Returns true if specified year match the plan end year.
  bool isEndYear(int year) => year == planEndYear;

  /// Retunrs as configured [TaxFilingInfo].
  TaxFilingInfo get taxFilingInfo => _taxFilingInfo;

  /// Returns true if filing married
  bool get isMarried => taxFilingInfo.filingStatus.isMarried;

  /// Returns as configured [PersonInfo] about self.
  PersonInfo get selfInfo => _self;

  /// Returns as configured [PersonInfo] about self.
  PersonInfo get spouseInfo => _spouse!;

  /// Returns as configured [AccountInfo] list.
  AccountInfos get accountInfos => _accountInfos;

  /// Returns as configured [IncomeInfo] list.
  IncomeInfos get incomeInfos => _incomeInfos;

  /// Returns as configured [ScenarioInfo] list.
  ScenarioInfos get scenarioInfos => _scenarioInfos;

  /// Returns the scenario information matching the the corresponding ID
  /// Throws an expeption when no match is found.
  ScenarioInfo scenarioByID(String id) {
    return scenarioInfos.firstWhere((scenario) => scenario.id == id,
        orElse: () {
      throw (Exception('Request for non-existent scenarioInfo'));
    });
  }

  /// Returns the transient scenario information for the scenario currently under analysis.
  ScenarioInfo get currentScenario {
    return _currentScenario!;
  }

  /// Returns the person information for the specified ownwer type.
  /// If spouse information is requested and it does not exist, an exception is thrown.
  PersonInfo personFromOwnerType(OwnerType ownerType) {
    return ownerType == OwnerType.self ? selfInfo : spouseInfo;
  }

  /// Returns the [MessageService] that holds validation messages for the current [AnalysisConfig] object.
  /// Note: Any chnage to the [AnalysisConfig] object results in a clean [MessageService] object.
  MessageService get messageService => _messageService;

  /// Returns the [TransactionLog] that holds anlysis results for the current [AnalysisConfig] object.
  /// Note: Any chnage to the [AnalysisConfig] object results in a clean [TransactionLog] object.
  TransactionLog get transactionLog => _transactionLog;
}
