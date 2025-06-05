import 'dart:math';

import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/services/tax_services/federal_tax.dart';
import 'package:roth_analysis/services/tax_services/fica_tax.dart';
import 'package:roth_analysis/services/tax_services/irmaa_tax.dart';
import 'package:roth_analysis/services/tax_services/local_tax.dart';
import 'package:roth_analysis/services/tax_services/state_tax/state_tax.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

import 'analysis_config.dart';
import 'account_analysis_bin.dart';
import 'account_analysis.dart';
import 'analysis_exceptions.dart';
import 'income_analysis_bin.dart';
import 'person_analysis.dart';
import 'monthly_plan.dart';
import 'rmd_estimator.dart';
import 'transaction_log.dart';

/// Record containing ROTH Constriants for the given Scenario and Year
/// * rothConversionAmount - The configured ROTH conversion amount;
/// returns 0.0, if ROTH conversions not scheduled; returns a positive infinity if no
/// ROTH conversion amount was configured.
/// * configuredMagiLimit - The configured MAGI limit; returns positive infinity if no
/// MAGI limit was configured.
typedef RothConversionConstraints = ({
  double configuredRothConversionAmount,
  double configuredMagiLimit
});

/// Manages the analysis and anlaysis results for one year for one scenario specified in the plan.
/// * [analysisConfig] - The configuration information for the plan analysis
/// * [prevYearsAnalysis] - Link to the previous years [YearAnalysis]. Null for first year's analysis.
/// * [targetYear] - The year for this [YearAnalysis].
///
/// Information and analysis results specific to a person, i.e., either self or spouse.
/// * [selfAnalysis] - Information and analysis results specific to a self.
/// * [spouseAnalysis] - Information and analysis results specific to a spouse.
///
/// Collections that provide collection specific analysis capabilities and results.
/// * [accountAnalysisBin] - Account analysis information for all accounts.
/// * [incomeAnalysisBin] - Income analysis information of all income streams
///
/// Invariant Payment plans, i.e., payment plans that are invariant for the full simulation/analysis year.
/// * [livingExpensePaymentPlan] - Plan for monthly living expense payments.
/// * [ficaTaxPaymenyPlan] - Plan for monthly social security tax payments.
/// * [medicareTaxPaymentPlan] - Plan for monthly medicare tax payments.
/// * [irmaaTaxPaymentPlan] - Plan for additional IRMAA medicare payments.
///
/// Income Tax Payment Plans (can/will be updated during the simulation/analysis year).
/// * [federalIncomeTaxPaymentPlan] - Plan for monthly Federal Income Tax payments.
/// * [stateIncomeTaxPaymentPlan] - Plan for monthly State Income Tax payments.
/// * [localIncomeTaxPaymentPlan] - Plan for monthly Local Income Tax payments.
///
/// Tax filiing interface and respective  services
/// * [_filingSettings] - Tax filing settings to be used by the various tax services to calculate taxes.
/// * [_federalIncomeTaxService] - Tax service used to calculate Federal Taxes for the year.
/// * [_stateIncomeTaxService] - Tax service used to calculate State Taxes for the year.
/// * [_localIncomeTaxService] - Tax service used to calculate Local Taxes for the year.
/// * [_ficaTaxService] - Tax service used to calculate FICA Taxes for the year.
/// * [_irmaaTaxService] - Tax service used to calculate IRMAA Taxes for the year.
///
/// ROTH Conversion Constraint
/// * [_rothConversionConstraints] - ROTH Conversion constraints as related to the target year
///
/// End of simulation information
/// [_monthWhereFundsExausted]
class YearAnalysis {
  AnalysisConfig analysisConfig;
  YearAnalysis? prevYearsAnalysis;
  final int targetYear;

  // Minimum ROTH conversion allowed.  Conversion amount below this will be adjusted to zero.
  final double _minimumRothConversion = 1000.0;

  // Set to true should IRA assets be needed to cover expenses even when no ROTH conversion is performed.
  bool _iraAssetsConsumedWithZeroRothConversion = false;

  // Information and analysis results specific to a person, i.e., either self or spouse
  final PersonAnalysis selfAnalysis;
  final PersonAnalysis spouseAnalysis;

  // Collections that provide collection specific analysis capabilities and results.
  late AccountAnalysisBin accountAnalysisBin;
  late IncomeAnalysisBin incomeAnalysisBin;

  // Invariant Payment plans, i.e., payment plans that are invariant for the full simulation/analysis year.
  final MonthlyPlan livingExpensePaymentPlan = MonthlyPlan();
  final MonthlyPlan ficaTaxPaymenyPlan = MonthlyPlan();
  final MonthlyPlan medicareTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan irmaaTaxPaymentPlan = MonthlyPlan();

  /// Income Tax Payment Plans (can/will be updated during the simulation/analysis year)
  final MonthlyPlan federalIncomeTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan stateIncomeTaxPaymentPlan = MonthlyPlan();
  final MonthlyPlan localIncomeTaxPaymentPlan = MonthlyPlan();

  // Tax Services for target year
  late TaxFilingSettings _filingSettings;
  late FederalTaxByFilingStatus _federalIncomeTaxService;
  late StateTax _stateIncomeTaxService;
  late LocalTax _localIncomeTaxService;
  late FicaTax _ficaTaxService;
  late IrmaaTaxByFilingStatus _irmaaTaxService;

  // Roth Conversion Constraints for target year
  late RothConversionConstraints _rothConversionConstraints;

  // Captures the month whre funds were exausted (if they were exausted).
  int? _monthWhereFundsExausted;

  /// Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [targetYear] - holds the year that this [YearAnalysis] is for.
  /// [prevYearsAnalysis] - holds information from the previous years [YearAnalysis].
  /// Must be specified excpet when the year is for the first year in the plan.
  /// From specified information both the [accountAnalysisBin] and [incomeAnalysisBin] will be inntialized.
  YearAnalysis({
    required this.analysisConfig,
    required this.prevYearsAnalysis,
    required this.targetYear,
  })  : selfAnalysis = PersonAnalysis(),
        spouseAnalysis = PersonAnalysis() {
    // Intialize living expense payment plan using time-adjusted expenses.
    livingExpensePaymentPlan.initialize(adjustForTime(
      valueToAdjust: analysisConfig.planInfo.yearlyExpenses,
      toYear: targetYear,
      fromYear: analysisConfig.planStartYear,
    ));

    // Initialize the accountAnalysisBin
    accountAnalysisBin = _createAccountAnalysisBin();

    // Initalize the incomeAnalysisBin
    incomeAnalysisBin = _createIncomeAnalysisBin();

    // Initilaize tax interface and tax services
    _filingSettings = _createTaxFilingSettings();
    _initalizeIrmaaMagi();
    _federalIncomeTaxService = FederalTaxByFilingStatus(_filingSettings);
    _stateIncomeTaxService = StateTax.getStateSpecifcService(_filingSettings);
    _localIncomeTaxService = LocalTax(_filingSettings);
    _ficaTaxService = FicaTax(_filingSettings);
    _irmaaTaxService = IrmaaTaxByFilingStatus(_filingSettings);

    // Initalize yearly income information for income streams that are invariant over the year's analysys/simulation.
    // Cannot be called before incomeAnalysisBin has been intialized.
    _initializeYearlyInvariantIncome();

    // Initalize yearly taxes that are invariant over the year's analysys/simulation.
    // çannot be called before _initializeYearlyInvariantIncome has been intialized.
    _initializeInvariantTaxes();

    // Initialize ROTH conversion constraints.
    _initializeRothConversionConstraints();

    // Intialize everything else via simulation
    try {
      _simulateYear();
    } on InsufficentAccountAssetException catch (e) {
      _monthWhereFundsExausted = e.monthWhereFundsExausted;
    }
  }

  /// Returns the yearly RMD distribution for both the self and spouse (if married).
  double get yearlyRmdDistribution =>
      selfAnalysis.yearlyRmdDistribution + spouseAnalysis.yearlyRmdDistribution;
  double get yearlyRmdIncome => yearlyRmdDistribution;

  /// Returns the monthly RMD distibution for spcified [month],for both the self and spouse (if married).
  double monthlyRmdDistribution(int month) =>
      selfAnalysis.monthlyRothConversion(month) +
      spouseAnalysis.monthlyRothConversion(month);

  /// Returns the ROTH Conversion Plan (can/will be updated during the simulation/analysis year).
  /// * Limitation: At present time this program does not support "married filing jointly".
  /// Therefore, the entire RMD plan is managed within self's plan.
  MonthlyPlan get rothConversionPlan => selfAnalysis.rothConversionPlan;

  /// Returns the yearly ROTH conversions for both self and spouse (if married).
  double get yearlyRothConversion =>
      selfAnalysis.yearlyRothConversion + spouseAnalysis.yearlyRothConversion;

  /// Returns the monthly ROTH conversions amount for both the self and spouse (if married).
  double monthlyRothConversion(int month) =>
      selfAnalysis.monthlyRothConversion(month) +
      spouseAnalysis.monthlyRothConversion(month);

  /// Returns the yearly total income for both self and spouse (if married).
  double get yearlySsIncome =>
      selfAnalysis.yearlySsIncome + spouseAnalysis.yearlySsIncome;

  /// Returns the yearly interest income for both self and spouse (if married).
  double get yearlyInterestIncome =>
      selfAnalysis.yearlyInterestIncome + spouseAnalysis.yearlyInterestIncome;

  /// Returns the yearly dividend income for both self and spouse (if married).
  double get yearlyDividendIncome =>
      selfAnalysis.yearlyDividendIncome + spouseAnalysis.yearlyDividendIncome;

  /// Returns the yearly capital gains income for both self and spouse (if married).
  double get yearlyCapitalGainsIncome =>
      selfAnalysis.yearlyCapitalGainsIncome +
      spouseAnalysis.yearlyCapitalGainsIncome;

  /// Returns the yearly regular income for both self and spouse (if married).
  double get yearlyRegularIncome =>
      selfAnalysis.yearlyRegularIncome + spouseAnalysis.yearlyRegularIncome;

  /// Returns the yearly self-employment income for both self and spouse (if married).
  double get yearlySelfEmploymentIncome =>
      selfAnalysis.yearlySelfEmploymentIncome +
      spouseAnalysis.yearlySelfEmploymentIncome;

  /// Returns the yearly pension income for both self and spouse (if married).
  double get yearlyPensionIncome =>
      selfAnalysis.yearlyPensionIncome + spouseAnalysis.yearlyPensionIncome;

  /// Returns the yearly federal MAGI for both self and spouse (if married).
  double get federalMAGI =>
      selfAnalysis.federalMAGI + spouseAnalysis.federalMAGI;

  /// Returns the yearly federal income tax for both self and spouse (if married).
  double get federalIncomeTax =>
      selfAnalysis.federalIncomeTax + spouseAnalysis.federalIncomeTax;

  /// Returns the monthly federal income tax amount for both the self and spouse (if married).
  double monthlyFederalIncomeTax(int month) =>
      federalIncomeTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the monthly state income tax amount for both the self and spouse (if married).
  double monthlyStateIncomeTax(int month) =>
      stateIncomeTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the monthly local income tax amount for both the self and spouse (if married).
  double monthlyLocalIncomeTax(int month) =>
      localIncomeTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the monthly FICA tax amount for both the self and spouse (if married).
  double monthlyFicaTax(int month) =>
      selfAnalysis.ficaTaxPaymentPlan.getMonthlyAmount(month) +
      spouseAnalysis.ficaTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the monthly Medicare tax amount for both the self and spouse (if married).
  double monthlyMedicareTax(int month) =>
      selfAnalysis.medicareTaxPaymentPlan.getMonthlyAmount(month) +
      spouseAnalysis.medicareTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the monthly IRMAA tax amount for both the self and spouse (if married).
  double monthlyIrmaaTax(int month) =>
      selfAnalysis.irmaaTaxPaymentPlan.getMonthlyAmount(month) +
      spouseAnalysis.irmaaTaxPaymentPlan.getMonthlyAmount(month);

  /// Returns the yearly state income tax for both self and spouse (if married).
  double get stateIncomeTax =>
      selfAnalysis.stateIncomeTax + spouseAnalysis.stateIncomeTax;

  /// Returns the yearly local income tax for both self and spouse (if married).
  double get localIncomeTax =>
      selfAnalysis.localIncomeTax + spouseAnalysis.localIncomeTax;

  /// Returns the yearly living expenses.
  double get yearlyLivingExpenses => livingExpensePaymentPlan.yearlyAmount;

  /// Returns the yearly fica tax for both self and spouse (if married).
  double get ficaTax =>
      selfAnalysis.yearlyFicaTax + spouseAnalysis.yearlyFicaTax;

  /// Returns the yearly medicare income tax for both self and spouse (if married).
  double get medicareTax =>
      selfAnalysis.yearlyMedicareTax + spouseAnalysis.yearlyMedicareTax;

  /// Returns the yearly IRMAA tax for both self and spouse (if married).
  double get irmaaTax =>
      selfAnalysis.yearlyIrmaaTax + spouseAnalysis.yearlyIrmaaTax;

  /// Returns the total income taxes from all taxing agencies, i.e., Federal, State, Local
  double get currentTotalIncomeTaxes =>
      federalIncomeTaxPaymentPlan.yearlyAmount +
      stateIncomeTaxPaymentPlan.yearlyAmount +
      localIncomeTaxPaymentPlan.yearlyAmount;

  /// Returns the remaining income tax balance from all taxing agencies, i.e., Federal, State, Local
  /// staring with and including the specifiied [month].
  double remainingIncomeTaxes(int month) =>
      federalIncomeTaxPaymentPlan.remainingBalance(month) +
      stateIncomeTaxPaymentPlan.remainingBalance(month) +
      localIncomeTaxPaymentPlan.remainingBalance(month);

  /// Returns the yearly federal income tax underpayment for both the self and spouse (if married).
  double get federalIncomeTaxUnderpayment =>
      selfAnalysis.federalIncomeTaxUnderpayment +
      spouseAnalysis.federalIncomeTaxUnderpayment;

  /// Returns the yearly state income tax underpayment for both the self and spouse (if married).
  double get stateIncomeTaxUnderpayment =>
      selfAnalysis.stateIncomeTaxUnderpayment +
      spouseAnalysis.stateIncomeTaxUnderpayment;

  /// Returns the yearly local income tax underpayment for both the self and spouse (if married).
  double get localIncomeTaxUnderpayment =>
      selfAnalysis.localIncomeTaxUnderpayment +
      spouseAnalysis.localIncomeTaxUnderpayment;

  /// Returns the yearly iraDistributions for both the self and spouse (if married).
  double get iraDistributions =>
      selfAnalysis.yearlyIraDistributions +
      spouseAnalysis.yearlyIraDistributions;

  /// Returns the month where funds were exausted (or null) if funds were not exausted.
  int? get monthWhereFundsExausted => _monthWhereFundsExausted;

  /// Returns the transaction log used to log account transactions
  TransactionLog get transactionLog => analysisConfig.transactionLog;

  /// Returns the self [PersonInventory] maintianed in the object's [_filingSettings]
  PersonInventory get selfInventory => _filingSettings.selfInventory;

  /// Returns the spouse [PersonInventory] maintianed in the object's [_filingSettings]
  PersonInventory get spouseInventory => _filingSettings.spouseInventory!;

  /// Returns the [AccountAnalysis] to be used for cash/checking account transactions.
  AccountAnalysis get cashAccount => accountAnalysisBin.cashAccount;

  /// Returns the [AccountAnalysis] to be used for taxable long term savings.
  AccountAnalysis get longTermSavingsAccount =>
      accountAnalysisBin.longTermSavingsAccount;

  /// Returns a valid ROTH Conversion amount, i.e., zero if below minimumRothConversion amount.
  double validRothConversionAmount(double requestedAmount) =>
      requestedAmount < _minimumRothConversion ? 0.0 : requestedAmount;

  /// Creates/Returns a [TaxFilingSettings] object.
  /// Used for initializtion inside the constructor.
  ///
  /// Note: Even when not married, a dummy/placeholder spouseInventory object is created.
  TaxFilingSettings _createTaxFilingSettings() {
    // Initialize a PersonRecord for self.
    PersonInventory selfInventory = PersonInventory(
      age: targetYear - analysisConfig.selfInfo.birthDate!.year,
      isBlind: analysisConfig.selfInfo.isBlind,
    );
    // Initialize a PersonRecord for spouse.
    PersonInventory spouseInventory;
    if (analysisConfig.isMarried) {
      spouseInventory = PersonInventory(
        age: targetYear - analysisConfig.spouseInfo.birthDate!.year,
        isBlind: analysisConfig.spouseInfo.isBlind,
      );
    } else {
      // When single we still create a default PersonInventory.
      spouseInventory = PersonInventory(age: 20);
    }

    // Intialize/Return a [TaxFilingSettings] record to be used for tax calculations
    return TaxFilingSettings(
      targetYear: targetYear,
      filingState: analysisConfig.taxFilingInfo.filingState,
      filingStatus: analysisConfig.taxFilingInfo.filingStatus,
      stateTaxPercentage:
          analysisConfig.taxFilingInfo.stateTaxPercentage * 100.0,
      stateStandardDeduction:
          analysisConfig.taxFilingInfo.stateStandardDeduction,
      localTaxPercentage:
          analysisConfig.taxFilingInfo.localTaxPercentage * 100.0,
      selfInventory: selfInventory,
      spouseInventory: spouseInventory,
    );
  }

  /// Creates/Returns an [AccountAnalysisBin] object.
  /// Used for intializtion inside the constructor.
  AccountAnalysisBin _createAccountAnalysisBin() {
    AccountAnalysisBin bin;
    if (analysisConfig.isStartYear(targetYear)) {
      // This is the first year of the plan, create the AccountAnalysisBin from AccountInfo.
      bin = AccountAnalysisBin.fromAccountInfo(
          analysisConfig: analysisConfig, targetYear: targetYear);
    } else if (prevYearsAnalysis == null) {
      // This is not the first years analysis; so there must be a previous year's analysis avalible.
      throw (Exception('Previous Years Analysis not provided'));
    } else {
      // Create this years AccountAnalysisBin from the previous years AccountAnalysisBin
      bin = AccountAnalysisBin.fromPrevAccountAnalysisBin(
        prevAccountAnalysisBin: prevYearsAnalysis!.accountAnalysisBin,
        targetYear: targetYear,
      );
    }
    return bin;
  }

  /// Creates/Returns an [IncomeAnalysisBin] object.
  /// Used for intializtion inside the constructor.
  IncomeAnalysisBin _createIncomeAnalysisBin() {
    IncomeAnalysisBin bin;
    if (analysisConfig.isStartYear(targetYear)) {
      // This is the first year of the plan, create the IncomeAnalysisBin from IncomeInfo.
      bin = IncomeAnalysisBin.fromIncomeInfo(
        analysisConfig: analysisConfig,
        targerYear: targetYear,
      );
    } else if (prevYearsAnalysis == null) {
      // This is not the first years analysis; so there must be a previous year's analysiss avalible.
      throw (Exception('Previous Years Analysis not provided'));
    } else {
      // Create this years AccountAnalysisBin from the previous years AccountAnalysisBin
      bin = IncomeAnalysisBin.fromPrevIncomeAnalyisBin(
        prevIncomeAnalysisBin: prevYearsAnalysis!.incomeAnalysisBin,
        targetYear: targetYear,
      );
    }
    return bin;
  }

  /// Intializes IRMAA MAGI so that IRMAA tax can be calculated.
  /// IRMAA MAGI is the MAGI from the analysis two years prior.
  ///
  /// Side Effects:
  /// * Modifies filingSettings.selfInventory.prevPrevYearsMAGI
  /// * Modifies filingSettings.spouseInventory.prevPrevYearsMAGI
  _initalizeIrmaaMagi() {
    // Before we can caluclate IRMAA taxes we must get MAGI values for two years prior.
    if (prevYearsAnalysis != null &&
        prevYearsAnalysis!.prevYearsAnalysis != null) {
      // We have a year analysis from two years prior; use it to intialize prevPrevYearsMAGI
      // fields for selfInventory and spouseInventory.
      selfInventory.prevPrevYearsMAGI =
          prevYearsAnalysis!.prevYearsAnalysis!.selfAnalysis.federalMAGI;
      spouseInventory.prevPrevYearsMAGI =
          prevYearsAnalysis!.prevYearsAnalysis!.spouseAnalysis.federalMAGI;
    } else {
      // Otherwise we assume that the MAGI was irrelevant to the IRMAA calculation
      selfInventory.prevPrevYearsMAGI = 0;
      spouseInventory.prevPrevYearsMAGI = 0;
    }
  }

  /// Initalizes Roth Conversion Constraints [_rothConversionConstraints] for the [targetYear].
  void _initializeRothConversionConstraints() {
    double configuredRothConversionAmount = double.infinity;
    double configuredMagiLimit = double.infinity;

    var (int rothConversionStartingYear, int rothConversionStartingMonth) =
        _rothConversionStartingYearAndMonth;
    var (int rothConversionEndingYear, int rothConversionEndingMonth) =
        _rothConversionEndingYear;

    if (targetYear < rothConversionStartingYear ||
        targetYear > rothConversionEndingYear) {
      // Not a year where user scheduled ROTH Conversions.
      configuredRothConversionAmount = 0.0;
    } else if (analysisConfig.currentScenario.amountConstraint.type ==
        AmountConstraintType.amount) {
      // The user specified a fixed amount to convert per year.
      configuredRothConversionAmount =
          analysisConfig.currentScenario.amountConstraint.fixedAmount;
    } else {
      // Configured Roth Conversion Amount is MAGI limited; its the only option left …
      // Get the configured MAGI limit, adjusted for time.
      configuredMagiLimit = adjustForTime(
          valueToAdjust:
              analysisConfig.currentScenario.amountConstraint.fixedAmount,
          toYear: targetYear,
          fromYear: rothConversionStartingYear);
    }
    _rothConversionConstraints = (
      configuredRothConversionAmount: configuredRothConversionAmount,
      configuredMagiLimit: configuredMagiLimit
    );

    int thisYearsStartingMonth = targetYear == rothConversionStartingYear
        ? rothConversionStartingMonth
        : 1;
    int thisYearsEndingMonfth =
        targetYear == rothConversionEndingYear ? rothConversionEndingMonth : 12;

    rothConversionPlan.initialize(0,
        beginMonth: thisYearsStartingMonth, finalMonth: thisYearsEndingMonfth);
  }

  /// Intializes yearly income for the specified [ownerType].
  /// that is, income that is invariant over the year's analysys/simulation.
  ///
  /// Notes:
  /// * If [ownerType] is omitted, then income is intialized for both self and spouse (if married)
  ///
  /// Side Effects:
  /// * A number of object fields will be intialized / updated based on the reuslts of the estimate, e.g.,
  /// [yearlyRmdDistribution], [yearlyRegularIncome], [yearlySelfEmploymentIncome], [yearlySsIncome], [yearlyPensionIncome]
  void _initializeYearlyInvariantIncome({OwnerType? ownerType}) {
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;

      personAnalysis.yearlyRmdDistribution =
          accountAnalysisBin.remainingRmd(ownerType: ownerType);
      personAnalysis.yearlyRegularIncome =
          incomeAnalysisBin.estimateRemainingIncomeByOwnerAndIncomeType(
        month: 1,
        ownerType: ownerType,
        incomeType: IncomeType.employment,
      );
      personAnalysis.yearlySelfEmploymentIncome =
          incomeAnalysisBin.estimateRemainingIncomeByOwnerAndIncomeType(
        month: 1,
        ownerType: ownerType,
        incomeType: IncomeType.selfEmployment,
      );
      personAnalysis.yearlySsIncome =
          incomeAnalysisBin.estimateRemainingIncomeByOwnerAndIncomeType(
        month: 1,
        ownerType: ownerType,
        incomeType: IncomeType.socialSecurity,
      );
      personAnalysis.yearlyPensionIncome =
          incomeAnalysisBin.estimateRemainingIncomeByOwnerAndIncomeType(
        month: 1,
        ownerType: ownerType,
        incomeType: IncomeType.pension,
      );
    } else {
      _initializeYearlyInvariantIncome(ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        _initializeYearlyInvariantIncome(ownerType: OwnerType.spouse);
      }
    }
  }

  /// Intializes yearly fixed taxes for the specified [ownerType].
  /// That is, taxes that are fixed / guaranteed not to be depenent on other analysis variables.
  ///
  /// Notes:
  /// * If no [ownerType] is specified then taxes are initialized for both self and spouse (if married)
  /// * Assumes invariant/guaranteed income was estimated prior to this method being called.
  ///
  /// Side Effects:
  /// * A number of object fileds will be intialized / updated based on the reuslts of the estimate.
  /// * See [_initializeFicaTax], [_initializeMedicareTax], [_estimateIrmaTax]
  _initializeInvariantTaxes({OwnerType? ownerType}) {
    // Assume tax service interface must be updated for updated tax estimations.
    _updateTaxServiceSettings();
    _initializeFicaTax(ownerType: ownerType);
    _initializeMedicareTax(ownerType: ownerType);
    _initializeIrmaaTax(ownerType: ownerType);
  }

  /// Estimates the montly invariant taxes for the specified [month] and [ownerType].
  ///
  /// Notes:
  /// * Only covers so-called invariant taxes, FICA, Medicare and IRMAA
  /// * If no [ownerType] is specified then taxes are payed for both self and spouse (if married)
  /// * Assumes monthly payment plans have been developed.
  double _estimateRemainingInvariantTaxes(int month, {OwnerType? ownerType}) {
    double reaminingInvariantTaxes = 0.0;
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      reaminingInvariantTaxes =
          personAnalysis.ficaTaxPaymentPlan.remainingBalance(month);
      reaminingInvariantTaxes +=
          personAnalysis.medicareTaxPaymentPlan.remainingBalance(month);
      reaminingInvariantTaxes +=
          personAnalysis.irmaaTaxPaymentPlan.remainingBalance(month);
    } else {
      reaminingInvariantTaxes =
          _estimateRemainingInvariantTaxes(month, ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        reaminingInvariantTaxes += _estimateRemainingInvariantTaxes(month,
            ownerType: OwnerType.spouse);
      }
    }
    return reaminingInvariantTaxes;
  }

  /// Pays the specified [amountToPay] taxes, for the specififled [month],
  /// for the specified [taxTypeName] for the specified person [forWhom] (self or spouse)
  /// * If [forWhom] is omitted and the user is married, forWhom deaults to 'self/spouse'.
  /// * If [forWhom] is omitted and the user is not married, forWhom defauslts to 'self'.
  void _payTaxes(
      {required int month,
      required double amountToPay,
      required String taxTypeName,
      String? forWhom}) {
    final AccountAnalysis cashAccount = this.cashAccount;
    if (amountToPay > 0.0) {
      if (forWhom == null) {
        if (analysisConfig.isMarried) {
          forWhom = 'self/spouse';
        } else {
          forWhom = OwnerType.self.label;
        }
      }
      cashAccount.pay(
          paymentAmount: amountToPay,
          paymentMonth: month,
          memo: '$taxTypeName taxes for $forWhom');
    }
  }

  /// Pay monthly FICA taxes for the [month]
  void _payFicaTaxes(int month) {
    _payTaxes(
      month: month,
      amountToPay: monthlyFicaTax(month),
      taxTypeName: 'FICA',
    );
  }

  /// Pay monthly Medicare taxes for the [month]
  void _payMedicareTaxes(int month) {
    _payTaxes(
      month: month,
      amountToPay: monthlyMedicareTax(month),
      taxTypeName: 'Medicare',
    );
  }

  /// Pay monthly IRMAA taxes for the [month]
  void _payIrmaaTaxes(int month) {
    _payTaxes(
      month: month,
      amountToPay: monthlyIrmaaTax(month),
      taxTypeName: 'IRMAA',
    );
  }

  /// Estimates / updates yearly income, dividend and capital gains for all accounts owned by the specified [ownerType].
  ///
  /// Inputs:
  /// [month] - Must be set to the first month where gains have yet to be accrued into the accounts.
  /// [ownerType] - Specifes the owner of the accounts to be estimated. If no [ownerType] is specified
  /// [fullYearCapGains] - Indiactes that capital gains must be assumed to be for the full year.
  /// then income is estimated for both self and spouse (if married)
  ///
  /// Side Effects:
  /// * Updates the corresponding [PersonResult], i.e. [selfResult] or/and [spouseResult] fields
  /// ,i.e., for yearlyInterestIncome, yearlyDividendIncome, and yearlyCapitalGainsIncome
  void _updateTaxableGains(int month,
      {OwnerType? ownerType, bool fullYearCapGains = false}) {
    final int capGainsMonth = fullYearCapGains ? 12 : month;
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      final (double totalInterest, double totalDividends) =
          accountAnalysisBin.yearToDateTaxableGainsByOwner(ownerType);
      personAnalysis.yearlyInterestIncome = totalInterest;
      personAnalysis.yearlyDividendIncome = totalDividends;
      personAnalysis.yearlyCapitalGainsIncome = accountAnalysisBin
          .estimateYearlyCapitalGainsByOwner(capGainsMonth, ownerType);
    } else {
      _updateTaxableGains(month,
          ownerType: OwnerType.self, fullYearCapGains: fullYearCapGains);
      if (analysisConfig.isMarried) {
        _updateTaxableGains(month,
            ownerType: OwnerType.spouse, fullYearCapGains: fullYearCapGains);
      }
    }
  }

  /// Estimates [PersonAnalysis] for self and (if married) spouse yearlyIraWithdraws
  /// with year to date withdraw information.
  ///
  /// Inputs:
  /// [ownerType] - Specifes the owner of the accounts to be estimated. If no [ownerType] is specified
  /// [fullYearCapGains] - Indiactes that capital gains must be assumed to be for the full year.
  /// then income is estimated for both self and spouse (if married)
  ///
  /// Side Effects:
  /// * Updates the corresponding [PersonResult], i.e. [selfResult] or/and [spouseResult] fields
  /// ,i.e., for yearlyInterestIncome, yearlyDividendIncome, and yearlyCapitalGainsIncome
  void _updateYearlyIraWithdraws([OwnerType? ownerType]) {
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      personAnalysis.yearlyIraWithdraws =
          accountAnalysisBin.yearToDateWithdrawnByAccountType(
              AccountType.traditionalIRA, ownerType);
    } else {
      _updateYearlyIraWithdraws(OwnerType.self);
      if (analysisConfig.isMarried) {
        _updateYearlyIraWithdraws(OwnerType.spouse);
      }
    }
  }

  /// Estimates yearly Local tax for the specified [ownerType]
  /// If no [ownerType] is specified then taxes are estimated for both self and spouse (if married)
  ///
  /// Side Effects:
  /// * Updates the corresponding [PersonResult], i.e. [selfResult] or/and [spouseResult] fileds
  /// * Updated fields [localIncomeTax]
  void _estimateLocalTax({OwnerType? ownerType}) {
    if (ownerType != null) {
      PersonAnalysis personResult =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      personResult.localIncomeTax =
          _localIncomeTaxService.calcTaxes(ownerType: ownerType);
    } else {
      _estimateLocalTax(ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        _estimateLocalTax(ownerType: OwnerType.spouse);
      }
    }
  }

  /// Initializes yearly FICA tax for the specified [ownerType]
  /// If no [ownerType] is specified then income is estimated for both self and spouse (if married)
  void _initializeFicaTax({OwnerType? ownerType}) {
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      PersonInventory personInventory =
          ownerType.isSelf ? selfInventory : spouseInventory;
      final (int beginMonth, int finalMonth) =
          incomeAnalysisBin.getIncomeMonthRange(ownerType);
      personAnalysis.ficaTaxPaymentPlan.initialize(
          _ficaTaxService.ficaTax(person: personInventory),
          beginMonth: beginMonth,
          finalMonth: finalMonth,
          adjustForFractionalYear: false);
    } else {
      _initializeFicaTax(ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        _initializeFicaTax(ownerType: OwnerType.spouse);
      }
    }
  }

  /// Estimates yearly Medicare tax for the specified [ownerType]
  /// If no [ownerType] is specified then income is estimated for both self and spouse (if married)
  void _initializeMedicareTax({OwnerType? ownerType}) {
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      PersonInventory personInventory =
          ownerType.isSelf ? selfInventory : spouseInventory;
      final (int beginMonth, int finalMonth) =
          incomeAnalysisBin.getIncomeMonthRange(ownerType);
      personAnalysis.medicareTaxPaymentPlan.initialize(
          _ficaTaxService.medicareTax(person: personInventory),
          beginMonth: beginMonth,
          finalMonth: finalMonth,
          adjustForFractionalYear: false);
    } else {
      _initializeMedicareTax(ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        _initializeMedicareTax(ownerType: OwnerType.spouse);
      }
    }
  }

  /// Initialize yearly IRRMA tax for the specified [ownerType]
  /// If no [ownerType] is specified then income is estimated for both self and spouse (if married)
  ///
  /// Notes:
  /// * Assumes irmaaTaxService has been intialized.
  void _initializeIrmaaTax({OwnerType? ownerType}) {
    if (ownerType != null) {
      PersonAnalysis personAnalysis =
          ownerType.isSelf ? selfAnalysis : spouseAnalysis;
      personAnalysis.irmaaTaxPaymentPlan
          .initialize(_irmaaTaxService.calcTaxes(ownerType: ownerType));
    } else {
      _initializeIrmaaTax(ownerType: OwnerType.self);
      if (analysisConfig.isMarried) {
        _initializeIrmaaTax(ownerType: OwnerType.spouse);
      }
    }
  }

  /// Estimates/Tracks yearly taxes (Federal, State, and Local) for the [targetYear].
  /// Note: It is expected that a full year's updates have been made and/or estimated/simulated,
  /// such that income, account gains, IRA withdraws, etc are alread for the full year.
  ///
  /// Side Effects:
  /// * Updates the corresponding [PersonResult], i.e. [selfResult] or/and [spouseResult] fileds
  /// * Updated fields [federalIncomeTax], [stateIncomeTax], [localIncomeTax],
  ///
  /// Limitation: At present time this function does not fully support a federal filing status
  /// of marriedFilingSeperately
  void _estimateIncomeTaxes() {
    // Update yearly taxable (interest, dividend, capital) gains.
    _updateTaxableGains(12);
    // Update yearly IRA distributions
    _updateYearlyIraWithdraws();
    // Assume tax service interface must be updated to get updated investment account gains.
    _updateTaxServiceSettings();
    selfAnalysis.federalIncomeTax = _federalIncomeTaxService.calcIncomeTax();
    selfAnalysis.federalMAGI =
        _federalIncomeTaxService.modifiedAdjustedGrossIncome;
    selfAnalysis.stateIncomeTax = _stateIncomeTaxService.calcTaxes();
    _estimateLocalTax();
  }

  /// Returns the year and month for which Roth Conversions can start.
  (int year, int month) get _rothConversionStartingYearAndMonth {
    int startYear;
    int startMonth;
    switch (analysisConfig.currentScenario.startDateConstraint) {
      case ConversionStartDateConstraint.onFixedDate:
        startYear = analysisConfig.currentScenario.specificStartDate!.year;
        startMonth = analysisConfig.currentScenario.specificStartDate!.month;
        break;
      case ConversionStartDateConstraint.onPlanStart:
        startYear = analysisConfig.planStartYear;
        startMonth = analysisConfig.planStartMonth;
        break;
    }
    return (startYear, startMonth);
  }

  /// Returns the year and month for which Roth Conversions will end.
  (int year, int month) get _rothConversionEndingYear {
    int endYear;
    int endMonth;
    switch (analysisConfig.currentScenario.endDateConstraint) {
      case ConversionEndDateConstraint.onFixedDate:
        endYear = analysisConfig.currentScenario.specificEndDate!.year;
        endMonth = analysisConfig.currentScenario.specificEndDate!.month;
        break;
      case ConversionEndDateConstraint.onEndOfPlan:
        endYear = analysisConfig.planEndYear;
        endMonth = analysisConfig.planEndMonth;
        break;
      case ConversionEndDateConstraint.onRmdStart:
        endYear = rmdStartYear(analysisConfig.selfInfo.birthDate!) - 1;
        endMonth = 12;
        break;
    }
    return (endYear, endMonth);
  }

  /// Returns updated tax filing [PersonInventory] settings with any estimated income results.
  /// [PersonInventory] informatiom to update is specified in [ownerType]
  PersonInventory _getUpdatedPersonInventoryFromPersonResults(
      OwnerType ownerType) {
    final PersonAnalysis personAnalysis =
        ownerType.isSelf ? selfAnalysis : spouseAnalysis;
    PersonInventory personInventory =
        ownerType.isSelf ? selfInventory : spouseInventory;
    personInventory = personInventory.copyWith(
      ssIncome: personAnalysis.yearlySsIncome,
      regularIncome: personAnalysis.yearlyRegularIncome,
      selfEmploymentIncome: personAnalysis.yearlySelfEmploymentIncome,
      pensionIncome: personAnalysis.yearlyPensionIncome,
      iraDistributions: personAnalysis.yearlyIraDistributions,
      interestIncome: personAnalysis.yearlyInterestIncome,
      dividendIncome: personAnalysis.yearlyDividendIncome,
      capitalGainsIncome: personAnalysis.yearlyCapitalGainsIncome,
    );
    return personInventory;
  }

  /// Updates [_filingSettings] with any estimated income results.
  void _updateTaxServiceSettings() {
    _filingSettings = _filingSettings.copyWith(
      selfInventory:
          _getUpdatedPersonInventoryFromPersonResults(OwnerType.self),
      spouseInventory:
          _getUpdatedPersonInventoryFromPersonResults(OwnerType.spouse),
    );
    _federalIncomeTaxService.filingSettings = _filingSettings;
    _stateIncomeTaxService.filingSettings = _filingSettings;
    _localIncomeTaxService.filingSettings = _filingSettings;
    _ficaTaxService.filingSettings = _filingSettings;
    _irmaaTaxService.filingSettings = _filingSettings;
  }

  // Returns the total avalible assets across all taxable savings accounts.
  double get totalAvailibleCash {
    return accountAnalysisBin
        .availibeBalanceByAccountType(AccountType.taxableSavings);
  }

  // Returns the total avalible assets across all taxable brokerage accounts.
  double get totalAvailibleBrokerageAssets {
    return accountAnalysisBin
        .availibeBalanceByAccountType(AccountType.taxableBrokerage);
  }

  // Returns the total avalible assets across all traditional IRA accounts.
  double get totalAvailibleIraAssets {
    return accountAnalysisBin
        .availibeBalanceByAccountType(AccountType.traditionalIRA);
  }

  // Returns the total avalible assets across all ROTH IRA accounts.
  double get totalAvailibleRothAssets {
    return accountAnalysisBin.availibeBalanceByAccountType(AccountType.rothIRA);
  }

  /// Moves up to [requiredAssets] from accounts of type [accountType] to the [cashAccount].
  /// * [memo] - Memo to be used on the transaction log for the transfers.
  ///
  /// Returns the total assets that were moved. Which may be less than [requiredAssets].
  double _moveAssetsFromAccoutTypeToCashAccount(
      double requiredAssets, int month, AccountType accountType, String memo) {
    double totalAmountWithdrawn = 0.0;
    double remainingAssets = requiredAssets;
    for (final account
        in accountAnalysisBin.filteredAccounts(accountType: accountType)) {
      if (account != cashAccount) {
        final amountWithdrawn = account.withdraw(remainingAssets, month, memo,
            partialWithDrawAllowed: true);
        cashAccount.deposit(amountWithdrawn, month, memo);
        remainingAssets -= amountWithdrawn;
        totalAmountWithdrawn += amountWithdrawn;
        if (remainingAssets <= 0.0) {
          break;
        }
      }
    }
    return totalAmountWithdrawn;
  }

  /// Moves [totalAssetsNeeded] to the [cashAccount].
  /// * [totalAssetsNeeded] - Amount of assets to move to cash.
  /// * [month] - Month the transfer is occuring.
  /// * [memo] - Memo to log for the transfer.
  ///
  /// Note: If avalible assets are less than [totalAssetsNeeded],
  /// the smaller amount will still be transferred.
  void _moveAssetsFromAnyToCashAccount(
      double totalAssetsNeeded, int month, String memo) {
    double requiredAssets = totalAssetsNeeded;
    if (requiredAssets <= 0.0) {
      return;
    }
    requiredAssets -= _moveAssetsFromAccoutTypeToCashAccount(
        requiredAssets, month, AccountType.taxableSavings, memo);
    if (requiredAssets <= 0.0) {
      return;
    }
    requiredAssets -= _moveAssetsFromAccoutTypeToCashAccount(
        requiredAssets, month, AccountType.taxableBrokerage, memo);
    if (requiredAssets <= 0.0) {
      return;
    }
    requiredAssets -= _moveAssetsFromAccoutTypeToCashAccount(
        requiredAssets, month, AccountType.traditionalIRA, memo);
    if (requiredAssets <= 0.0) {
      return;
    }
    requiredAssets -= _moveAssetsFromAccoutTypeToCashAccount(
        requiredAssets, month, AccountType.rothIRA, memo);
  }

  /// Logs summary/yearly tax information to the transaction log.
  _logTaxInfo() {
    TransactionDate transactionDate = (year: targetYear, month: 0);
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'FICA',
        value: ficaTax,
        memo: 'FICA Tax'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'Medicare',
        value: medicareTax,
        memo: 'Medicare Tax'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'IRMAA',
        value: irmaaTax,
        memo: 'IRMAA Tax'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'CapGins',
        value: yearlyCapitalGainsIncome,
        memo: 'Capital Gains Income'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'AGI',
        value: federalMAGI,
        memo: 'Adjusted Gross Income'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'FederalTax',
        value: federalIncomeTax,
        memo: 'Federal income tax'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'StateTax',
        value: stateIncomeTax,
        memo: 'State income tax'));
    transactionLog.add(TransactionEntry.info(
        transactionType: TransactionType.taxInfo,
        transactionDate: transactionDate,
        extraInfo: 'LocalTax',
        value: localIncomeTax,
        memo: 'Local income tax'));
  }

  /// Logs summary/yearly account information to the transaction log.
  _logAccountInfo() {
    accountAnalysisBin.logAccountBalances();
  }

  void stop() {}

  // Analyze / Simulate  a full year.
  ///
  /// Exceptions:
  /// * [InsufficentAccountAssetException] should we exceed available funds.
  void _simulateYear() {
    for (int month = 1; month <= 12; month++) {
      if (targetYear >= 2026 && month == 3) {
        stop();
      }

      _simulateMonth(month);
    }

    //_estimateIncomeTaxes(fullYear: true, month: 12);
    _logAccountInfo();
    _estimateIncomeTaxes();
    _logTaxInfo();
  }

  /// Analyze / Simulate the specified simulation [month].
  ///
  /// Exceptions:
  /// * [InsufficentAccountAssetException] should we exceed available funds.
  void _simulateMonth(int month) {
    _adjustPaymentPlans(month);

    // Deposit month's income into cash account and pay FICA and Medicare taxes on that income.
    // Note: FICA and Medicare taxes can be paid here as they must be less than the income we just deposited.
    incomeAnalysisBin.monthlyIncomeToAccount(cashAccount, month);
    _payFicaTaxes(month);
    _payMedicareTaxes(month);

    // Accure investment gains to all accounts.
    accountAnalysisBin.accrueMonthAccountGains(month);

    // Collect some values needed below.
    // Including an estimate for total monthly expenses which must include any unpaid taxes.
    final double thisMonthsLivingExpense =
        livingExpensePaymentPlan.getMonthlyAmount(month);
    final double thisMonthsFederalIncomeTax = monthlyFederalIncomeTax(month);
    final double thisMonthsStateIncomeTax = monthlyStateIncomeTax(month);
    final double thisMonthsLocalIncomeTax = monthlyLocalIncomeTax(month);
    final double thisMonthsTotalExpenses = thisMonthsLivingExpense +
        thisMonthsFederalIncomeTax +
        thisMonthsStateIncomeTax +
        thisMonthsLocalIncomeTax +
        monthlyIrmaaTax(month);

    // Calculate the RMD amount that should be allocated to the cashAccount incluing a small buffer.
    // Take RMDs allocating

    final double avalibleCashAssets = cashAccount.availableBalance;
    double cashNeeded = max(0.0, thisMonthsTotalExpenses - avalibleCashAssets)
        .roundToTwoPlaces();

    // Transfer the RMD allocating it to the proper accounts, e.g. cashNeeded to cashAccount.
    // And transfer the balance of casNeeded from other accounts to cashAccount (as needed).
    cashNeeded = accountAnalysisBin.transferRmds(
        month, cashNeeded, longTermSavingsAccount);
    _moveAssetsFromAnyToCashAccount(
        cashNeeded, month, 'Cover monthly taxes & living expenses');

    // Pay IRMAA taxes.
    _payIrmaaTaxes(month);

    // Perform ROTH converson.
    double conversionAmount = rothConversionPlan.getMonthlyAmount(month);
    const String memo = 'Monthly ROTH conversion';
    final (amountWithdrawnFromSelf, amountWithDrawnFromSpouse) =
        rothConversionWithdraw(conversionAmount, month, memo);
    final double amountWithdrawn =
        amountWithdrawnFromSelf + amountWithDrawnFromSpouse;
    accountAnalysisBin.rothAccountForSelf
        .deposit(amountWithdrawnFromSelf, month, memo);
    if (amountWithDrawnFromSpouse > 0.0) {
      accountAnalysisBin.rothAccountForSpouse!
          .deposit(amountWithDrawnFromSpouse, month, memo);
    }
    if (amountWithdrawn != conversionAmount) {
      rothConversionPlan.updateMonthlyAmount(month, amountWithdrawn);
    }
    // Pay monthly expenses.
    _payTaxes(
        month: month,
        amountToPay: thisMonthsFederalIncomeTax,
        taxTypeName: 'Federal Income');
    _payTaxes(
        month: month,
        amountToPay: thisMonthsStateIncomeTax,
        taxTypeName: 'State Income');
    _payTaxes(
        month: month,
        amountToPay: thisMonthsLocalIncomeTax,
        taxTypeName: 'Local Income');
    cashAccount.pay(
        paymentAmount: thisMonthsLivingExpense,
        paymentMonth: month,
        memo: 'Monthly living expenses');
  }

  /// Modifies the ROTH conversion plan and income tax payment plans to insure that execution of the ROTH conversion plan ...
  /// * will not result in the MAGI constraint being exceeded (should one have been configured).
  /// * will not result in an overdraft of the IRA accounts
  /// * can be executed within the available income and account assets.
  ///
  /// Side Affects:
  /// * [rothConversionPlan]
  /// * [simulationIraDistribution]
  /// * [federalIncomeTaxPaymentPlan]
  /// * [stateIncomeTaxPaymentPlan]
  /// * [localIncomeTaxPaymentPlan]
  /// * Also see [_estimateIncomeTaxes]
  ///
  void _adjustPaymentPlans(int month) {
    double allowedUpperLowerGapPercentage = 0.5; // percent
    double rothConversionAmount = 0.0;
    bool iraAssetUseAllowed =
        !analysisConfig.currentScenario.stopWhenTaxableIncomeUnavailible;

    // The process below runs a simulation that modifies account balances;  therefore, we save account state before beginning.
    accountAnalysisBin.saveState();

    // Getting ROTH conversion constraints established by the user.
    var (:configuredMagiLimit, :configuredRothConversionAmount) =
        _rothConversionConstraints;

    // Accure any account changes that will be invarient throughout this part of the simulation.
    // I.e., remaining account investment gains/income, remaining income
    // sands (FICA, Mediacre, IRMAA taxes), remaining RMDs
    accountAnalysisBin.accrueRemainingAccountGains(month);
    cashAccount.deposit(
        incomeAnalysisBin.remainingIncome(month: month) -
            _estimateRemainingInvariantTaxes(month),
        month,
        '');

    // Determine if there is a need to consume IRA assets for expenses, even without any ROTH conversion.
    // Note: This is performed by deposit the RMDs into a ROTH account (instead of cash) to prevent the use of
    // the RMD assets to cover expenses which would mask the need for IRA assets,
    // Note: This is performed with saved account state because RMDs deposits into a ROTH account
    // is not allowed by th IRA and we must restore the accounts after.
    if (month == 1) {
      accountAnalysisBin.saveState();
      accountAnalysisBin.transferRmds(
          month, 0.0, accountAnalysisBin.rothAccountForSelf,
          transferRmdBalance: true);
      final (
        :expensesWereMet,
        :assetsRemain,
        :rothConversionPlanIsViable,
        :iraAssetsWereConsumed
      ) = _validateRemainingYearlyExpenses(month, 0.0);
      _iraAssetsConsumedWithZeroRothConversion = iraAssetsWereConsumed;
      accountAnalysisBin.restoreState();
    }

    // If IRA assets are needed even with zero ROTH conversion and if configuration is such that
    // use of IRA assets for conversion expenses is not allowed.  Then we cannot ROTH conversion
    // is not allowed for this year.
    if (_iraAssetsConsumedWithZeroRothConversion && !iraAssetUseAllowed) {
      configuredRothConversionAmount = 0.0;
    }

    // Deposit the balance of the RMDs to either the cashAccount or the ROTH account.
    // Note: That transfering RMDs to a ROTH account is not legal per the IRS, however we are doing this to
    // accounts thant have been saved and will be restore later, so it is not a concern here.
    //
    accountAnalysisBin.transferRmds(month, 0.0, cashAccount,
        transferRmdBalance: true);

    // When the rothConversionAmount constraint for the year is below minimum allowed amount, we can shortcut the process.
    if (validRothConversionAmount(configuredRothConversionAmount) == 0.0) {
      rothConversionPlan.updateYearlyAmount(0.0, month: month);
      _validateRemainingYearlyExpenses(month, 0.0);
      _updateIncomeTaxPaymentPlans(month);
      accountAnalysisBin.restoreState();
      return;
    }

    // Establish initial upper and lower bound for ROTH conversion amount.
    // * lowerBound establishes a lower bound for selecting an optimal Roth conversion amount.  Intially, zero.
    // * upperrBound establishes an upper bound for selecting an optimal Roth conversion amount. Initially, either
    // (a) The user configured ROTH conversion amount (if no MAGI limit configured).
    // (b) The user configured MAGI limit (if a MAGI limit was configured).
    double lowerBound = 0.0;
    double upperBound = configuredMagiLimit == double.infinity
        ? configuredRothConversionAmount
        : configuredMagiLimit;

    // If a fixed Roth conversion constraint was chosen, check if it can succeed and if so,
    // shortcut the remaining selection algorithm.
    if (configuredMagiLimit == double.infinity) {
      rothConversionAmount = configuredRothConversionAmount;
      final double rothConversionBalance = max(
          0.0, rothConversionAmount - rothConversionPlan.accruedAmount(month));
      final (
        :expensesWereMet,
        :assetsRemain,
        :rothConversionPlanIsViable,
        :iraAssetsWereConsumed,
      ) = _validateRemainingYearlyExpenses(month, rothConversionBalance);
      if (rothConversionPlanIsViable) {
        rothConversionPlan.updateYearlyAmount(rothConversionAmount,
            month: month);
        _updateIncomeTaxPaymentPlans(month);
        accountAnalysisBin.restoreState();
        return;
      }
    }

    // Calculate an acceptible gap between upper and lower bounds, i.e., needed to estabish an
    // exit criteria for the loop below. Note: Keeping this gap below the minimumRothConversion amount
    // assures that the algorithm will converge to zero.
    double allowedUpperLowerGap =
        (upperBound - lowerBound) * allowedUpperLowerGapPercentage / 100.0;
    allowedUpperLowerGap = min(allowedUpperLowerGap, _minimumRothConversion);

    // Below we iterate adjusting upperBound and lowerBound based on the results of _valdiateRemainingYearlyExpenses.
    // Note: The loop is desiged to insure that it executed at least once.
    bool moreIterationsAllowed = true;
    while (moreIterationsAllowed) {
      rothConversionAmount = (lowerBound + upperBound) / 2.0;
      moreIterationsAllowed = (upperBound - lowerBound) >= allowedUpperLowerGap;
      final double rothConversionAccrued =
          rothConversionPlan.accruedAmount(month);
      final double rothConversionBalance =
          max(0.0, rothConversionAmount - rothConversionAccrued);
      final (
        :expensesWereMet,
        :assetsRemain,
        :rothConversionPlanIsViable,
        :iraAssetsWereConsumed,
      ) = _validateRemainingYearlyExpenses(month, rothConversionBalance);
      final bool magiConstraitExceeded = federalMAGI > configuredMagiLimit;

      if (!rothConversionPlanIsViable | magiConstraitExceeded) {
        // Failed to meet expense constraint OR Failed to meet MAGI contraint.
        // As long as more iterations are allowed, lower the next guess by lowering the upperBound.
        if (moreIterationsAllowed) {
          upperBound = rothConversionAmount;
        } else {
          // No more iterations are allowed.  Use lowerBound (validated) as the final rothConversionAmount.
          rothConversionAmount = validRothConversionAmount(lowerBound);
          _validateRemainingYearlyExpenses(
              month, max(0.0, rothConversionAmount - rothConversionAccrued));
          break;
        }
      } else if (assetsRemain && moreIterationsAllowed) {
        // Met the constraints, but assets remain. As long as more iterations are allowed,
        // there is still room to improve the estimate. Increase the next guess by raising the lowerBound.
        lowerBound = rothConversionAmount;
      } else {
        // Met the constraints, and no more assets remain. Use current rothConversionAmount (validated)
        // as the final rothConversionAmount.
        if (rothConversionAmount !=
            validRothConversionAmount(rothConversionAmount)) {
          rothConversionAmount =
              validRothConversionAmount(rothConversionAmount);
          _validateRemainingYearlyExpenses(
              month, max(0.0, rothConversionAmount - rothConversionAccrued));
        }
        break;
      }
    }

    // A viable ROTH conversion plan amount has been determined.
    rothConversionPlan.updateYearlyAmount(rothConversionAmount, month: month);
    _updateIncomeTaxPaymentPlans(month);
    accountAnalysisBin.restoreState();
    return;
  }

  /// Updates Income Tax Payement plans
  /// Side Affects:
  /// * [federalIncomeTaxPaymentPlan]
  /// * [stateIncomeTaxPaymentPlan]
  /// * [localIncomeTaxPaymentPlan]
  void _updateIncomeTaxPaymentPlans(int month) {
    federalIncomeTaxPaymentPlan.updateYearlyAmount(federalIncomeTax,
        month: month);
    stateIncomeTaxPaymentPlan.updateYearlyAmount(stateIncomeTax, month: month);
    localIncomeTaxPaymentPlan.updateYearlyAmount(localIncomeTax, month: month);
  }

  /// Validates any remaining yearly expenses.
  /// Returns a record ({bool expensesWereMet, bool assetsRemain, bool iraAssetsWereConsumed}).
  /// * [expensesWereMet] - true if expenses could be met.
  /// * [assetsRemain] - true when expenses could be met but more assets are availible to be utilized.
  /// * [iraAssetsWereConsumed] - true if IRA assets were consumed while attempting to meet expenses.
  ///
  /// Inputs:
  /// * [month] - Month number being simulated (1 - 12)
  /// * [rothConversionBalance] - Amounrt of Roth conversions that must still be met, i.e., from [month] through 12
  ///
  /// Prerequisites:
  /// * Remaining account gains have bee estiamted and accrued to accounts.
  /// * Remaining income minus (FICA, Mediacre, IRMAA) taxes have been estimated and deposited into accounts
  /// * Remaining RMDs have bee tranferred to appropriate accounts???
  ///
  /// Notes:
  /// * Inaccuracies exist in this estimate! We only know starting balances for accounts.  The actual account balance fluctuates over
  /// the year as deposits, withdraws and gains are accumulated. Thus the ability to cover expenses from a particular account is not certain.
  /// Accuracy improves as the [month] gets closer to 12.
  ({
    bool expensesWereMet,
    bool assetsRemain,
    bool rothConversionPlanIsViable,
    bool iraAssetsWereConsumed,
  }) _validateRemainingYearlyExpenses(int month, double rothConversionBalance) {
    double allowedRemainingTaxes = 10.0;
    double totalExpenses;
    double lastTotalExpenses = double.infinity;
    bool iraAssetsWereConsumed = false;
    bool assetsRemain = true;
    bool expensesWereMet = false;
    bool iraAssetUseAllowed =
        !analysisConfig.currentScenario.stopWhenTaxableIncomeUnavailible;

    // The algorithm below modifies account balances, therefore,
    // save account info here so that it can be restored before returning.
    accountAnalysisBin.saveState();

    // Perform remainingRothConversion (if possible).
    // Limitation: Because of current restrictions, conversions are only performed in accounts owned by self.
    final (amountWithdrawnFromSelf, amountWithDrawnFromSpouse) =
        rothConversionWithdraw(rothConversionBalance, month);
    final assetsWithdrawn = amountWithdrawnFromSelf + amountWithDrawnFromSpouse;

    // Shortcut if insufficient IRA funds were availible for ROTH conversion
    if (assetsWithdrawn < rothConversionBalance) {
      _estimateIncomeTaxes();
      accountAnalysisBin.restoreState();
      return (
        expensesWereMet: false,
        assetsRemain: true,
        rothConversionPlanIsViable: false,
        iraAssetsWereConsumed: false,
      );
    }

    // Otherwise, we can deposit the withdraw into the ROTH account and continue checking to see if
    // other expenses can be met.
    accountAnalysisBin.rothAccountForSelf
        .deposit(rothConversionBalance, month, '');

    // Collect some accrued values that are invariant for the remainder of the algoritm.
    double livingExpenseBalance =
        livingExpensePaymentPlan.remainingBalance(month);
    double accuredFederalIncomeTax =
        federalIncomeTaxPaymentPlan.accruedAmount(month);
    double accuredStateIncomeTax =
        stateIncomeTaxPaymentPlan.accruedAmount(month);
    double accuredLocalIncomeTax =
        localIncomeTaxPaymentPlan.accruedAmount(month);

    // Estimate income taxes before additional taxable withdraws are taken below
    // and calculate the intial value for the remaining total expenses.
    _estimateIncomeTaxes();
    totalExpenses = livingExpenseBalance +
        federalIncomeTax -
        accuredFederalIncomeTax +
        stateIncomeTax -
        accuredStateIncomeTax +
        localIncomeTax -
        accuredLocalIncomeTax;

    while ((totalExpenses - lastTotalExpenses).abs() > allowedRemainingTaxes) {
      expensesWereMet = true;
      iraAssetsWereConsumed = false;
      bool taxableAssetsWereConsumed = false;
      accountAnalysisBin.saveState();
      // Can savings assets cover the total expenses?
      // That is, allowing for a cash buffer.
      var assetsWithdrawn = accountAnalysisBin.withdraw(
          totalExpenses, AccountType.taxableSavings, month);
      double remainingExpenses = max(0.0, totalExpenses - assetsWithdrawn);
      if (remainingExpenses != 0.0) {
        // Savings assets cannot cover total expenses! Can taxable brokerage assets cover the remaining expenses?
        var assetsWithdrawn = accountAnalysisBin.withdraw(
            remainingExpenses, AccountType.taxableBrokerage, month);
        remainingExpenses = max(0.0, remainingExpenses - assetsWithdrawn);
        taxableAssetsWereConsumed = assetsWithdrawn != 0.0;
      }
      if (remainingExpenses != 0.0) {
        // Taxable brokerage assets cannot cover remaining expenses! Can IRA assets cover the remaining expenses?
        var assetsWithdrawn = accountAnalysisBin.withdraw(
            remainingExpenses, AccountType.traditionalIRA, month);
        remainingExpenses = max(0.0, remainingExpenses - assetsWithdrawn);
        iraAssetsWereConsumed = assetsWithdrawn != 0.0;
        taxableAssetsWereConsumed |= iraAssetsWereConsumed;
      }
      if (remainingExpenses != 0.0) {
        expensesWereMet = false;
      }

      _estimateIncomeTaxes();

      assetsRemain = accountAnalysisBin.hasAssets(AccountType.taxableSavings);
      assetsRemain |=
          accountAnalysisBin.hasAssets(AccountType.taxableBrokerage);
      assetsRemain |= accountAnalysisBin.hasAssets(AccountType.traditionalIRA);

      // Check if either ...
      // (a) We were not able to meet expenseBalance  OR
      // (b) expenseBalance was met without consuming taxable assets, in either case we're done.
      if (!expensesWereMet || !taxableAssetsWereConsumed) {
        accountAnalysisBin.restoreState();
        break;
      }
      // Othewise, the expenseBalance was covered but taxable assets were consumed.
      // As a result, additional income taxes were realized, therefore, totalExpenses has increased.
      // Save the previous loop's totalExpenses as lastTotalExpenses.
      // Calculate a new totalExpenses for the next loop iteration and allow the loop to conntinue.
      lastTotalExpenses = totalExpenses;
      totalExpenses = livingExpenseBalance +
          federalIncomeTax -
          accuredFederalIncomeTax +
          stateIncomeTax -
          accuredStateIncomeTax +
          localIncomeTax -
          accuredLocalIncomeTax;
      // Restore account state and rerun the loop.
      accountAnalysisBin.restoreState();
    }
    // loop has been exited!
    accountAnalysisBin.restoreState();

    bool rothConversionPlanIsViable =
        (expensesWereMet && (!iraAssetsWereConsumed || iraAssetUseAllowed)) ||
            rothConversionBalance == 0;

    return (
      expensesWereMet: expensesWereMet,
      assetsRemain: assetsRemain,
      rothConversionPlanIsViable: rothConversionPlanIsViable,
      iraAssetsWereConsumed: iraAssetsWereConsumed,
    );
  }

  /// Returns a [YearResult] derived from this [YearAnalysis].
  YearResult yearResult({required double prevCumulativeTaxes}) {
    return YearResult(
      targetYear: targetYear,
      expenses: yearlyLivingExpenses,
      totalIncome: yearlySsIncome +
          yearlyRegularIncome +
          yearlySelfEmploymentIncome +
          yearlyPensionIncome,
      savingsAssets: totalAvailibleCash,
      brokerageAssets: totalAvailibleBrokerageAssets,
      iraAssets: totalAvailibleIraAssets,
      rothAssets: totalAvailibleRothAssets,
      accountBalances: accountAnalysisBin.allAccountBalances(),
      selfResult: selfAnalysis.personResult(),
      spouseResult: spouseAnalysis.personResult(),
      prevCumulativeTaxes: prevCumulativeTaxes,
    );
  }

  /// Withdraws as much of the requested [iraConvertAmount] as possible
  /// WIthdraws logged agaist month [month] with a memo of [memo]
  /// i.e., given the availile self-owned IRA accounts and if married, spouse-owned IRA accounts.
  (double amountFromSelfOwnedAccounts, double amountFromSpouseOwnedAccounts)
      rothConversionWithdraw(double iraConvertAmount, int month,
          [String memo = '']) {
    // Withdraw as much as needed and possible from self-owned IRA accounts.
    final double assetsWithdrawnFromSelfOwnedIraAccounts = accountAnalysisBin
        .withdraw(iraConvertAmount, AccountType.traditionalIRA, month,
            ownerType: OwnerType.self, memo: memo);

    // Determine if there is ROTH conversion balance and whether it is possible to convert
    // from spousal accounts.
    final double rothConversionBalance =
        iraConvertAmount - assetsWithdrawnFromSelfOwnedIraAccounts;
    final bool canConvertFromSpousalIraAxccounts = analysisConfig.isMarried &&
        accountAnalysisBin.hasIraAccountForSelf &&
        accountAnalysisBin.rothAccountForSpouse != null;

    // If there is a ROTH conversion balance and spousal conversion id pssoible/
    // Withdraw as much as needed and possible from spouse-owned IRA accounts.
    double assetsWithdrawnFromSpouseOwnedIraAccounts = 0.0;
    if (rothConversionBalance > 0.0 && canConvertFromSpousalIraAxccounts) {
      assetsWithdrawnFromSpouseOwnedIraAccounts = accountAnalysisBin.withdraw(
          rothConversionBalance, AccountType.traditionalIRA, month,
          ownerType: OwnerType.spouse, memo: memo);
    }
    // Return the amount withdrawn from self ans spouspe owned IRA accounts.
    return (
      assetsWithdrawnFromSelfOwnedIraAccounts,
      assetsWithdrawnFromSpouseOwnedIraAccounts
    );
  }
}
