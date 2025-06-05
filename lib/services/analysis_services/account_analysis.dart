import 'dart:math';

import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/services/analysis_services/monthly_plan.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

import 'analysis_exceptions.dart';
import 'rmd_estimator.dart';
import 'transaction_log.dart';

typedef AccountState = ({
  // The account end-of-year balance.
  double endingBalance,
  // The current amount of funds deposited.
  double amountDeposited,
  // The current amount of funds withdrawn.
  double amountWithdrawn,
  // The current amount of RMDs taken. (Vlaid only for IRA accounts).
  double rmdsTransferedSoFar,
  // Cost basis for the account.
  double costBasis,
  // The accounts year-to-date income gains accrued during simulation.
  double yearToDateIncomeGain,
  // The previous month ending account balance
  double previousMonthEndingBalance,
  // The year-to-date realized captital gains.
  double realizedCapitalGains,
});

/// Manages the analysis and analysis results for a single account
/// of a given year of a given scenario specified in the plan.
/// [analysisConfig] - The configuration information for the plan analysis
/// [accountInfo] - The as configured accont informstion for this account
/// [ownerInfo] - The person information for the owner of the account
/// [targetYear] - The target year that the account is to be calculated for.
abstract class AccountAnalysis {
  final AnalysisConfig analysisConfig;
  final AccountInfo accountInfo;
  final PersonInfo ownerInfo;
  final int targetYear;
  // State stack that can be
  final List<AccountState> _stateStack = [];
  // The account start-of-year balance.
  double _startingBalance;
  // The account end-of-year balance.
  double _endingBalance = 0.0;
  // The current amount of funds deposited.
  double _amountDeposited = 0.0;
  // The current amount of funds withdrawn.
  double _amountWithdrawn = 0.0;
  // The current amount of RMDs taken. (Vlaid only for IRA accounts).
  double _rmdsTransferedSoFar = 0.0;
  // Cost basis for the account. Except for brokerage accounts costBasis always equals _endingBalance.
  double _costBasis = 0.0;
  // The accounts year-to-date income gains accrued during simulation.
  double _yearToDateIncomeGain = 0.0;
  // The previous month ending account balance
  double _previousMonthEndingBalance = 0.0;
  // The year-to-date realized captital gains.
  double _realizedCapitalGains = 0.0;

  /// Private Constructor
  /// [analysisConfig] - the configuration information for the plan analysis
  /// [accountInfo] - the as configured accont informstion for this account
  /// [targetYear] - the target year that the account is to be calculated for.
  /// [startingBalance] - the account balance, starts out as the previous years balance
  /// [costBasis] - the portion of the account balance which is cost basis
  AccountAnalysis._({
    required this.analysisConfig,
    required this.accountInfo,
    required this.targetYear,
    required double startingBalance,
    required double costBasis,
  })  : _startingBalance = startingBalance,
        _endingBalance = startingBalance,
        _costBasis = costBasis,
        _previousMonthEndingBalance = startingBalance,
        ownerInfo = analysisConfig.personFromOwnerType(accountInfo.owner);

  /// Private class factory that constructs the apprpriate type of AccountAnalysis object
  /// based on account type information. I.e., one of.
  /// [SavingsAccountAnalysis] | [BrokerageAccountAnalysis] | [IraAccountAnalysis] | [RothAccountAnalysis].
  /// [analysisConfig] - the configuration information for the plan analysis.
  /// [accountInfo] - the as configured account information for this account.
  /// [targetYear] - the target year that the account is to be calculated for.
  /// [startingBalance] - the account balance, starts out as the previous years balance.
  /// [costBasis] - the portion of the account balance which is cost basis
  factory AccountAnalysis._byAccountType({
    required AnalysisConfig analysisConfig,
    required AccountInfo accountInfo,
    required int targetYear,
    required double startingBalance,
    required double costBasis,
  }) {
    AccountAnalysis accountAnalysis;
    switch (accountInfo.type) {
      case AccountType.taxableSavings:
        accountAnalysis = SavingsAccountAnalysis._(
          analysisConfig: analysisConfig,
          accountInfo: accountInfo,
          targetYear: targetYear,
          startingBalance: startingBalance,
          costBasis: startingBalance,
        );
        break;
      case AccountType.taxableBrokerage:
        accountAnalysis = BrokerageAccountAnalysis._(
          analysisConfig: analysisConfig,
          accountInfo: accountInfo,
          targetYear: targetYear,
          startingBalance: startingBalance,
          costBasis: costBasis,
        );
        break;
      case AccountType.traditionalIRA:
        accountAnalysis = IraAccountAnalysis._(
          analysisConfig: analysisConfig,
          accountInfo: accountInfo,
          targetYear: targetYear,
          startingBalance: startingBalance,
          costBasis: startingBalance,
        );
        break;
      case AccountType.rothIRA:
        accountAnalysis = RothAccountAnalysis._(
          analysisConfig: analysisConfig,
          accountInfo: accountInfo,
          targetYear: targetYear,
          startingBalance: startingBalance,
          costBasis: startingBalance,
        );
        break;
    }
    return accountAnalysis;
  }

  /// Constructor used to create [AccountAnalysis] for the fist year of a plan.
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [accountInfo] - provides the as configured accont informstion for this account
  /// [targetYear] - provides the target year that the account is to be calculated for.
  factory AccountAnalysis.fromAccountInfo({
    required AnalysisConfig analysisConfig,
    required AccountInfo accountInfo,
    required int targetYear,
  }) {
    return AccountAnalysis._byAccountType(
      analysisConfig: analysisConfig,
      accountInfo: accountInfo,
      startingBalance: accountInfo.balance,
      costBasis: accountInfo.costBasis,
      targetYear: targetYear,
    );
  }

  /// Constructor used to create [AccountAnalysis] for the year 2 though n of a plan.
  /// Creating it from the previous years [AccountInfo]
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [previousAccountAnalysis] - provides previous years [AccountAnalysis] for this account
  factory AccountAnalysis.fromPrevAccountAnalysis({
    required AnalysisConfig analysisConfig,
    required AccountAnalysis previousAccountAnalysis,
  }) {
    return AccountAnalysis._byAccountType(
      analysisConfig: previousAccountAnalysis.analysisConfig,
      accountInfo: previousAccountAnalysis.accountInfo,
      targetYear: previousAccountAnalysis.targetYear + 1,
      startingBalance: previousAccountAnalysis._endingBalance,
      costBasis: previousAccountAnalysis._costBasis,
    );
  }

  /// Returns the as configured ID for the account.
  String get id => accountInfo.id;

  /// Returns the as configured name of the account.
  String get name => accountInfo.name;

  /// Returns the as-configured-type pf the account.
  AccountType get type => accountInfo.type;

  /// Returns the yearly roiIncome for the account.
  double get roiIncome => accountInfo.roiIncome;

  /// Returns the yearly roiGain for the account.
  double get roiGain => accountInfo.roiGain;

  /// Returns the yearly total roi for the account.
  double get roiTotal => roiIncome + roiGain;

  /// Returns the ownwer type (self or spouse) for the account.
  OwnerType get ownerType => accountInfo.owner;

  /// Returns starting balance for this account
  double get startingBalance => _startingBalance;

  /// Returns the accounts available balance
  /// Note: month is only relevant for IRA accounts as they may reserve RMD assets.
  double get availableBalance => _endingBalance;

  /// Returns the accounts available cost basis.
  double get availableCostBasis => _costBasis;

  /// Returns starting balance for this account
  double get endingBalance => _endingBalance;

  // Returns the current amount of funds deposited during the year.
  double get amountDeposited => _amountDeposited;

  // Returns the current amount of funds withdrawn during the year.
  double get amountWithdrawn => _amountWithdrawn;

  /// Returns the capital gains that have been realized.
  double get realizedCaptialGains => _realizedCapitalGains;

  /// Pushes the current state to a [AccountAnalysis] state stack.
  void saveState() {
    _stateStack.add(
      (
        endingBalance: _endingBalance,
        amountWithdrawn: _amountWithdrawn,
        amountDeposited: _amountDeposited,
        rmdsTransferedSoFar: _rmdsTransferedSoFar,
        costBasis: _costBasis,
        yearToDateIncomeGain: _yearToDateIncomeGain,
        previousMonthEndingBalance: _previousMonthEndingBalance,
        realizedCapitalGains: _realizedCapitalGains,
      ),
    );
  }

  /// Pops the [AccountAnalysis] state stack using the result to update the current state
  void restoreState() {
    if (_stateStack.isEmpty) {
      throw EmptyAccountAnalysisStackException();
    }
    final (
      :endingBalance,
      :amountWithdrawn,
      :amountDeposited,
      :rmdsTransferedSoFar,
      :costBasis,
      :yearToDateIncomeGain,
      :previousMonthEndingBalance,
      :realizedCapitalGains,
    ) = _stateStack.removeLast();
    _endingBalance = endingBalance;
    _amountWithdrawn = amountWithdrawn;
    _amountDeposited = amountDeposited;
    _rmdsTransferedSoFar = rmdsTransferedSoFar;
    _costBasis = costBasis;
    _yearToDateIncomeGain = yearToDateIncomeGain;
    _previousMonthEndingBalance = previousMonthEndingBalance;
    _realizedCapitalGains = realizedCapitalGains;
  }

  /// Restores current state from the earliest/first [AccountAnalysis] stack entry. Clears the stack.
  void restoreOriginalState() {
    if (_stateStack.isNotEmpty) {
      _stateStack.removeRange(1, _stateStack.length);
      restoreState();
    }
  }

  /// Adds a [TransactionEntry] to a transaction log,
  /// BUT, only when account is not operating without stacked state informstion.
  /// I.E., not working on temproary state information.
  void _logTransaction(TransactionEntry transactionEntry) {
    if (_stateStack.isNotEmpty) {
      return;
    }
    analysisConfig.transactionLog.add(transactionEntry);
  }

  /// Updates information that has been accrued over the course of one month during simulation.
  ///
  /// Side Effects:
  /// * Updates [_previousMonthEndingBalance]
  void _setMonthAsAccrued() {
    _previousMonthEndingBalance = _endingBalance;
    return;
  }

  /// Returns gains that have been accrued to this account so far.
  /// Returns a record (double yearlyInterest, double yearlyDividends) Where:
  /// * [yearlyInterest] - Returns the portion of the gains resulting from interest.
  /// * [yearlyDividends] - Returns the portion of the gains resulting from dividends.
  /// Always zero, except for objects of type [BrokerageAccountAnalysis].
  (double yearlyInterest, double yearlyDividends) yearToDateGains() {
    return (_yearToDateIncomeGain, 0.0);
  }

  /// Returns price gains that have been accrued to this account so far.
  ///
  /// Notes:
  /// * Price gains are only valid for taxable brokerage accounts, they are zero
  /// for all other account types.
  /// * See [BrokerageAccountAnalysis] for differences.
  double yearToDatePriceGains() => 0.0;

  /// Estimates/Returns yearly capital gains that would be accrued by this account.
  ///
  /// Inputs:
  /// * [month] - The last month that was accrued into the account.
  /// Notes:
  /// * Capital gains are only valid for taxable brokerage accounts, they are zero
  /// for all other account types.
  /// * See [BrokerageAccountAnalysis] for differences.
  double yearlyCapitalGainEstimate(int month) => 0.0;

  /// Accrues monthly account gains for this account for the spcified [month].
  /// Side Effects: See [_setMonthAsAccrued]
  void accrueMonthlyGain(int month) {
    // Accrue monthly income gain
    final double averageMonthlyBalance =
        (_previousMonthEndingBalance + endingBalance) / 2.0;
    final double monthlyIncomeGain =
        (averageMonthlyBalance * roiGain / 12.0).roundToTwoPlaces();
    _yearToDateIncomeGain += monthlyIncomeGain;
    _endingBalance += monthlyIncomeGain;

    // Flag month as accrued.
    _setMonthAsAccrued();

    TransactionDate transactionDate = (year: targetYear, month: month);
    if (monthlyIncomeGain > 0.0) {
      _logTransaction(
        TransactionEntry.gain(
          transactionDate: transactionDate,
          amount: monthlyIncomeGain,
          accountName: name,
          accountBalance: _endingBalance,
          memo: 'Monthly income gain',
        ),
      );
    }
    return;
  }

  /// Validates the month number in [month].
  /// Throws an [InvalidMonthNumberException] if the value is not not between 1 and 12.
  void _validateMonth(int month) {
    if (month < 1 || month > 12) {
      throw (InvalidMonthNumberException(month));
    }
  }

  /// Estimates/Accrues the remaining account gains beginning with [month] through the remainder of the year.
  void accrueRemainingAccountGains(int month) {
    // This method can only be called when the account state has been saved.
    if (_stateStack.isEmpty) {
      throw AccureRemainingMisuseException();
    }
    _validateMonth(month);
    final int remainingMonths = 13 - month;
    final double averageMonthlyBalance =
        (_previousMonthEndingBalance + endingBalance) / 2.0;
    final double averageMonthlyGain = averageMonthlyBalance * roiGain / 12.0;
    final double remainingIncomeGain =
        (averageMonthlyGain * remainingMonths).roundToTwoPlaces();
    _yearToDateIncomeGain += remainingIncomeGain;
    _endingBalance += remainingIncomeGain;
  }

  /// Returns amount withdrawn so far.
  double yearToDateWithdrawn() {
    return _amountWithdrawn;
  }

  /// Attempts to withdraw the specified [requestedWithdrawAmount].
  /// Returns the amount withdrawn.
  ///
  /// Inputs:
  /// * [requestedWithdrawAmount] - Amount of assets to withdraw.
  /// * [month] - Month the withdraw occured.
  /// * [memo] - Memo to use on the transaction log.
  /// * [partialWithDrawAllowed] - True if it is ok to partially fulfill the withdraw.
  /// * [isPayment] - True if this withdraw should be looged as a payment,
  ///  Otherwise, the entire [requestedWithdrawAmount] must be avalible.
  ///
  /// Notes:
  /// * Tracks any captial gains that are realized as a result of the withdraw.
  /// This is only true for accounts of type [BrokerageAccountAnalysis].
  /// * Throws an [InsufficentAccountAssetException] when there there are insufficient available assets in the account.
  double withdraw(double requestedWithdrawAmount, int month, String memo,
      {bool partialWithDrawAllowed = false, bool isPayment = false}) {
    if (requestedWithdrawAmount <= 0.0) {
      return 0.0;
    }
    final double amountThatCanBeWithdrawn =
        min(requestedWithdrawAmount, availableBalance);
    // The following check is performed in a way to avoid rounding errors.
    if ((amountThatCanBeWithdrawn - requestedWithdrawAmount).abs() >= 0.01 &&
        !partialWithDrawAllowed) {
      throw (InsufficentAccountAssetException(
          'In account ${accountInfo.name} for withdraw of \$$requestedWithdrawAmount',
          month));
    }
    _endingBalance -= amountThatCanBeWithdrawn;
    _costBasis -= amountThatCanBeWithdrawn;
    _amountWithdrawn += amountThatCanBeWithdrawn;

    TransactionDate td = (year: targetYear, month: month);
    TransactionEntry te = isPayment
        ? TransactionEntry.payment(
            transactionDate: td,
            amount: amountThatCanBeWithdrawn,
            accountName: name,
            accountBalance: _endingBalance,
            memo: memo,
          )
        : TransactionEntry.withdraw(
            transactionDate: td,
            amount: amountThatCanBeWithdrawn,
            accountName: name,
            accountBalance: _endingBalance,
            memo: memo,
          );
    _logTransaction(te);
    return amountThatCanBeWithdrawn;
  }

  /// Attempts to pay the specified [paymentAmount] and returns the amountPaid.
  /// Records payement in a transaction log.
  ///
  /// Inputs:
  /// * [paymentAmount] - Amount that whould be paid by this account.
  /// * [paymentMonth] - Month that the payement was made.
  /// * [memo] - Text to record as part of the corresponding transaction log.
  /// * [partialWithDrawAllowed] - True if it is ok to partially fulfill the payment.
  ///  Otherwise, the entire [paymentAmount] must be avalible or an [InsufficentAccountAssetException] is thrown.
  double pay({
    required double paymentAmount,
    required int paymentMonth,
    required String memo,
    bool partialWithDrawAllowed = false,
  }) {
    if (paymentAmount < 0.0) {
      return 0.0;
    }
    double amountWithdrawn = withdraw(paymentAmount, paymentMonth, memo,
        partialWithDrawAllowed: partialWithDrawAllowed, isPayment: true);
    return amountWithdrawn;
  }

  /// Deposits [depositAmount] into the account.
  /// Logs deposit with the provided memo.
  void deposit(double depositAmount, int month, String memo) {
    if (depositAmount <= 0.0) {
      return;
    }
    _endingBalance += depositAmount;
    _costBasis += depositAmount;
    _amountDeposited += depositAmount;
    _logTransaction(TransactionEntry.deposit(
        transactionDate: (year: targetYear, month: month),
        amount: depositAmount,
        accountName: name,
        accountBalance: _endingBalance,
        memo: memo));
  }
}

/// Manages the analysis for accounts of type [AccountType.taxableSavings]
class SavingsAccountAnalysis extends AccountAnalysis {
  /// Private constructor for [SavingsAccountAnalysis] objects
  /// [analysisConfig] - provides the configuration information for the plan analysis.
  /// [accountInfo] - provides the as configured account information for this account.
  /// [targetYear] - provides the target year that the account is to be calculated for.
  /// [startingBalance] - provides the account balance, starts out as the previous years balance.
  /// [costBasis] -  the protion of the account balance thay is cost basis.
  SavingsAccountAnalysis._({
    required super.analysisConfig,
    required super.accountInfo,
    required super.targetYear,
    required super.startingBalance,
    required super.costBasis,
  }) : super._();
}

/// Manages the analysis for accounts of type [AccountType.taxableBrokerage]
/// [_yearToDatePriceGain] - Used during simulation to accumulate the tears price gains.
class BrokerageAccountAnalysis extends AccountAnalysis {
  // The accounts year-to-date accrued price gains.
  double _yearToDatePriceGain = 0;

  /// Private constructor for [BrokerageAccountAnalysis] objects
  /// [analysisConfig] - provides the configuration information for the plan analysis.
  /// [accountInfo] - provides the as configured account information for this account.
  /// [targetYear] - provides the target year that the account is to be calculated for.
  /// [startingBalance] - provides the account balance, starts out as the previous years balance.
  /// [costBasis] -  the protion of the account balance thay is cost basis.
  BrokerageAccountAnalysis._({
    required super.analysisConfig,
    required super.accountInfo,
    required super.targetYear,
    required super.startingBalance,
    required super.costBasis,
  }) : super._();

  /// Returns gains that have been accrued by this account to date.
  /// Returns a record (double yearlyInterest, double yearlyDividends) Where:
  /// * [yearlyInterest] - Returns the portion of the gains resulting from interest.
  /// * [yearlyDividends] - Returns the portion of the gains resulting from dividends.
  /// Always zero, except for objects of type [BrokerageAccountAnalysis].
  ///
  /// Notes:
  /// * Income gains are assumed to be split 50/50 between [yearlyInterest] and [yearlyDividends]
  @override
  (double yearlyInterest, double yearlyDividends) yearToDateGains() {
    var (interestGain, dividendGain) = super.yearToDateGains();
    dividendGain = (interestGain / 2.0).roundToTwoPlaces();
    interestGain = (interestGain - dividendGain).roundToTwoPlaces();
    return (interestGain, dividendGain);
  }

  /// Returns price gains that have accrued by this account to date.
  @override
  double yearToDatePriceGains() {
    return _yearToDatePriceGain;
  }

  /// Estimates/Returns yearly capital gains that would be accrued by this account.
  ///
  /// Inputs:
  /// * [month] - The number of the first month that has not yet been accrued into the account.
  /// Notes:
  /// * Capital gains are only valid for taxable brokerage accounts, they are zero
  /// for all other account types.
  /// * See [BrokerageAccountAnalysis] for differences.
  @override
  double yearlyCapitalGainEstimate(int month) {
    _validateMonth(month);
    return _realizedCapitalGains / month * 12.0;
  }

  /// Accrues monthly gains for this account, for this [month].
  /// Returns a record of ([priceGain], [incomeGain])
  /// Where:
  /// * [priceGain] - Returns the monthly gain from price for this account.
  /// * [incomeGain] - Returns the monthly taxable income gains for this account.
  ///
  /// Side Effects: See [_setMonthAsAccrued]
  @override
  (double priceGain, double incomeGain) accrueMonthlyGain(int month) {
    // Accrue monthly price gain.
    final averageMonthlyBalance =
        (_previousMonthEndingBalance + endingBalance) / 2.0;
    final double priceGain =
        (averageMonthlyBalance * roiGain / 12.0).roundToTwoPlaces();
    _yearToDatePriceGain += priceGain;
    _endingBalance += priceGain;

    TransactionDate transactionDate = (year: targetYear, month: month);
    if (priceGain > 0.0) {
      _logTransaction(
        TransactionEntry.gain(
          transactionDate: transactionDate,
          amount: priceGain,
          accountName: name,
          accountBalance: _endingBalance,
          memo: 'Monthly price gain',
        ),
      );
    }

    // Accrue monthly income gain
    final double incomeGain =
        (averageMonthlyBalance * roiIncome / 12.0).roundToTwoPlaces();
    _yearToDateIncomeGain += incomeGain;
    _endingBalance += incomeGain;

    if (incomeGain > 0.0) {
      _logTransaction(
        TransactionEntry.gain(
          transactionDate: transactionDate,
          amount: incomeGain,
          accountName: name,
          accountBalance: _endingBalance,
          memo: 'Monthly income gain',
        ),
      );
    }

    // Flag month as accrued.
    _setMonthAsAccrued();
    return (priceGain, incomeGain);
  }

  /// Estimates/Accrues the reamining account gains starting with [month] through the remainder of the year.
  @override
  void accrueRemainingAccountGains(int month) {
    // This method can only be called when the account state has been saved.
    if (_stateStack.isEmpty) {
      throw AccureRemainingMisuseException();
    }
    _validateMonth(month);
    final int remainingMonths = 13 - month;
    final double averageMonthlyBalance =
        (_previousMonthEndingBalance + endingBalance) / 2.0;

    // Accrue monthly price gain.
    final averageMonthlyPriceGain = averageMonthlyBalance * roiGain / 12.0;
    final double remainingPriceGain =
        (averageMonthlyPriceGain * remainingMonths).roundToTwoPlaces();
    _yearToDatePriceGain += remainingPriceGain;
    _endingBalance += remainingPriceGain;

    // Accrue monthly income gain
    final averageMonthlyIncomeGain = averageMonthlyBalance * roiIncome / 12.0;
    final double remainingIncomeGain =
        (averageMonthlyIncomeGain * remainingMonths).roundToTwoPlaces();
    _yearToDateIncomeGain += remainingIncomeGain;
    _endingBalance += remainingIncomeGain;
  }

  /// Attempts to withdraw the specified [requestedWithdrawAmount].
  /// Returns the amount withdrawn.
  ///
  /// Inputs:
  /// * [requestedWithdrawAmount] - Amount of assets to withdraw.
  /// * [month] - Month the withdraw occured.
  /// * [memo] - Memo to use on the transaction log.
  /// * [partialWithDrawAllowed] - True if it is ok to partially fulfill the withdraw.
  /// * [isPayment] - True if this withdraw should be looged as a payment,
  ///  Otherwise, the entire [requestedWithdrawAmount] must be avalible.
  ///
  /// Notes:
  /// * Tracks any captial gains that are realized as a result of the withdraw.
  /// * Throws an [InsufficentAccountAssetException] when there there are insufficient available assets in the account.
  @override
  double withdraw(double requestedWithdrawAmount, int month, String memo,
      {bool partialWithDrawAllowed = false, bool isPayment = false}) {
    if (requestedWithdrawAmount <= 0.0 || availableBalance <= 0.0) {
      return 0.0;
    }
    final double amountThatCanBeWithdrawn =
        min(requestedWithdrawAmount, availableBalance);
    if (amountThatCanBeWithdrawn != requestedWithdrawAmount &&
        !partialWithDrawAllowed) {
      throw (InsufficentAccountAssetException(
          'In account ${accountInfo.name} for withdraw of \$$requestedWithdrawAmount',
          month));
    }
    final double costBasisPartOfWithdraw =
        (_costBasis / _endingBalance * amountThatCanBeWithdrawn)
            .roundToTwoPlaces();
    final double capitalGainsPartOfWithdraw =
        amountThatCanBeWithdrawn - costBasisPartOfWithdraw;
    _costBasis -= costBasisPartOfWithdraw;
    _endingBalance -= amountThatCanBeWithdrawn;
    _realizedCapitalGains += capitalGainsPartOfWithdraw;
    _amountWithdrawn += amountThatCanBeWithdrawn;

    TransactionDate td = (year: targetYear, month: month);
    TransactionEntry te = isPayment
        ? TransactionEntry.payment(
            transactionDate: td,
            amount: amountThatCanBeWithdrawn,
            accountName: name,
            accountBalance: _endingBalance,
            memo: memo,
          )
        : TransactionEntry.withdraw(
            transactionDate: td,
            amount: amountThatCanBeWithdrawn,
            accountName: name,
            accountBalance: _endingBalance,
            memo: memo,
          );
    _logTransaction(te);
    return amountThatCanBeWithdrawn;
  }
}

/// Manages the analysis for accounts of type [AccountType.traditionalIRA]
class IraAccountAnalysis extends AccountAnalysis {
  // The monthly RMD distribution plan.
  final MonthlyPlan _rmdDistributionPlan = MonthlyPlan();

  /// Private constructor for [IraAccountAnalysis] objects
  /// [analysisConfig] - provides the configuration information for the plan analysis.
  /// [accountInfo] - provides the as configured account information for this account.
  /// [targetYear] - provides the target year that the account is to be calculated for.
  /// [startingBalance] - provides the account balance, starts out as the previous years ending balance.
  /// [costBasis] -  the protion of the account balance thay is cost basis.
  IraAccountAnalysis._({
    required super.analysisConfig,
    required super.accountInfo,
    required super.targetYear,
    required super.startingBalance,
    required super.costBasis,
  }) : super._() {
    // Initilaize the RMD distribution plan, which will be invariant for the full year's analysis/simulation.
    _rmdDistributionPlan.initialize(
        rmdEstimator(startingBalance, ownerInfo.birthDate!, targetYear));
  }

  /// Returns the RMD distribution plan for the IRA account.
  MonthlyPlan get rmdDistributionPlan => _rmdDistributionPlan;

  /// Transfer monthly [or remaing] RMD for the target [month] to the specified accounts.
  /// * [month] - Month that the transfer is being perfromed for or starting at.
  /// * [reserveAmount] - Amount of the RMD that should be diverted to the specified [reserveAccount].
  /// * [reserveAccount] - Account to be used to transfer the [reserveAmount].
  /// Generally this is an account reserved for cash transactions.
  /// * [toAccount] - Account to transfer the balance of the RMD.
  /// * [transferRmdBalance] - When true, the remaining RMD balance
  /// will be transferred instead of just the RMD for the month.
  ///
  /// Returns the amount actually transferred to the [reserveAccount];
  /// This could be less than the [reserveAmount], if the RMD withdraw was insufficient.
  ///
  /// Side Effects:
  /// * Adjusts ending balance by the monthy RMD distribution amount.
  /// * Throws an exception if an invalid [month] number is specified.
  double transferRmd({
    required int month,
    required double reserveAmount,
    required AccountAnalysis reserveAccount,
    required AccountAnalysis toAccount,
    required bool transferRmdBalance,
  }) {
    _validateMonth(month);
    final TransactionDate transactionDate = (year: targetYear, month: month);
    final double rmdTransferAmount = transferRmdBalance
        ? _rmdDistributionPlan.remainingBalance(month)
        : _rmdDistributionPlan.getMonthlyAmount(month);
    if (rmdTransferAmount == 0.0) {
      return 0.0;
    }
    _endingBalance -= rmdTransferAmount;
    _amountWithdrawn += rmdTransferAmount;
    _rmdsTransferedSoFar += rmdTransferAmount;

    // The code above perfromed an under-the-hood withdraw, so log the withdraw transaction.
    _logTransaction(TransactionEntry.withdraw(
      transactionDate: transactionDate,
      amount: rmdTransferAmount,
      accountName: name,
      accountBalance: _endingBalance,
      memo: 'RMD Withdraw',
    ));

    // Determine the portion of the RMD that will go to the reserveAccount and deposit it.
    final double reservedAmount = min(reserveAmount, rmdTransferAmount);
    String memo = reservedAmount == rmdTransferAmount
        ? 'RMD fully allocated into savings for monthly expenses'
        : 'Portion of RMD allocated into savings for monthly expenses';
    reserveAccount.deposit(reservedAmount, month, memo);

    // Determine the remaining portion of the RMD that will go to the toAccount and deposit it.
    final double remainingAmount = rmdTransferAmount - reserveAmount;
    memo = reserveAmount == 0.0
        ? 'RMD fully allocated into long-term investments'
        : 'Portion of RMD allocated into long-term investments';
    toAccount.deposit(remainingAmount, month, memo);

    // Return the amount deposited to the reserveAccount.
    return reservedAmount;
  }

  /// Returns the balance of the IRA account that is avalible for utilization.
  /// Note: Because this is an IRA account, adjustments to the account balance must be made
  /// for RMD assets that may still be reserved.
  @override
  double get availableBalance {
    // An IRA Accounts avalible balance is the standard account avalible balance
    // adjusted down by the total amount of RMDs to be taken durng the year.
    // adjusted up by the RMDs that have already been transfered.
    return super.availableBalance -
        _rmdDistributionPlan.yearlyAmount +
        _rmdsTransferedSoFar;
  }
}

/// Manages the analysis for accounts of type [AccountType.rothIRA]
class RothAccountAnalysis extends AccountAnalysis {
  /// Private constructor for [RothAccountAnalysis] objects
  /// [analysisConfig] - provides the configuration information for the plan analysis.
  /// [accountInfo] - provides the as configured account information for this account.
  /// [targetYear] - provides the target year that the account is to be calculated for.
  /// [startingBalance] - provides the account balance, starts out as the previous years balance.
  /// [costBasis] -  the protion of the account balance thay is cost basis.
  RothAccountAnalysis._({
    required super.analysisConfig,
    required super.accountInfo,
    required super.targetYear,
    required super.startingBalance,
    required super.costBasis,
  }) : super._();
}
