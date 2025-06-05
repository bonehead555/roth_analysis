import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';

import 'account_analysis.dart';
import 'analysis_config.dart';
import 'transaction_log.dart';

/// Manages the analysis and analysis results for all accounts
/// of a given year of a given scenario.
/// [analysisConfig] - holds the configuration information for the plan analysis
/// [accountAnalyses] - holds the the analysis and analysis results for all accounts
class AccountAnalysisBin {
  final AnalysisConfig analysisConfig;
  final int targetYear;
  final List<AccountAnalysis> accountAnalyses;
  late AccountAnalysis? _cashAccount;
  late AccountAnalysis? _longTermSavingsAccount;
  late bool _hasIraAccountForSelf;
  late bool _hasIraAccountForSpouse;
  late AccountAnalysis? _rothAccountForSelf;
  late AccountAnalysis? _rothAccountForSpouse;
  double rmdConversionSelf = 0;
  double rmdConversionSpouse = 0;

  /// Private Constructor
  /// [analysisConfig] - provides the configuration information for the plan analysis
  /// [accountAnalyses] - provides the list of account analysis to manage
  AccountAnalysisBin._({
    required this.analysisConfig,
    required this.targetYear,
    required this.accountAnalyses,
  }) {
    // Initalize variables for frequently accessed accounts
    _cashAccount = _lowestEarningTaxableSavingsAccount;
    _longTermSavingsAccount = _highestEarningTaxableAccount;
    var (selfAccount, spouseAccount) =
        _highestEarningAccountByType(AccountType.traditionalIRA);
    _hasIraAccountForSelf = selfAccount != null;
    _hasIraAccountForSpouse = spouseAccount != null;
    (selfAccount, spouseAccount) =
        _highestEarningAccountByType(AccountType.rothIRA);
    _rothAccountForSelf = selfAccount;
    _rothAccountForSpouse = spouseAccount;
  }

  /// Constructor used to create [AccountAnalysisBin] for the first year of a plan.
  /// From [AccountInfo], for the start year,
  /// an inital [AccountAnalysis] will be created for every account in the bin.
  factory AccountAnalysisBin.fromAccountInfo({
    required AnalysisConfig analysisConfig,
    required int targetYear,
  }) {
    List<AccountAnalysis> accountAnalyses = [];
    for (var accountInfo in analysisConfig.accountInfos) {
      accountAnalyses.add(AccountAnalysis.fromAccountInfo(
        analysisConfig: analysisConfig,
        accountInfo: accountInfo,
        targetYear: targetYear,
      ));
    }
    var accountAnalysis = AccountAnalysisBin._(
        analysisConfig: analysisConfig,
        targetYear: targetYear,
        accountAnalyses: accountAnalyses);
    return accountAnalysis;
  }

  /// Constructor used to create an [AccountAnalysisBin] for the year 2 though n of a plan.
  /// [prevAccountAnalysisBin] - provides previous years [AccountAnalysisBin]
  /// From [prevAccountAnalysisBin], for a subsequent year,
  /// an inital [AccountAnalysis] will be created for every account in the bin.
  factory AccountAnalysisBin.fromPrevAccountAnalysisBin({
    required AccountAnalysisBin prevAccountAnalysisBin,
    required int targetYear,
  }) {
    List<AccountAnalysis> accountAnalyses = [];
    for (var prevAccountAnalysis in prevAccountAnalysisBin.accountAnalyses) {
      accountAnalyses.add(AccountAnalysis.fromPrevAccountAnalysis(
        analysisConfig: prevAccountAnalysisBin.analysisConfig,
        previousAccountAnalysis: prevAccountAnalysis,
      ));
    }
    var accountAnalysisBin = AccountAnalysisBin._(
      analysisConfig: prevAccountAnalysisBin.analysisConfig,
      targetYear: targetYear,
      accountAnalyses: accountAnalyses,
    );
    return accountAnalysisBin;
  }

  /// Returns the most optimal [AccountAnalysis] to use as a checking account.
  /// Throws an exception if a taxable savings account does not exist.
  AccountAnalysis get cashAccount {
    if (_cashAccount != null) {
      return _cashAccount!;
    }
    throw (Exception(
        'Attempt to access non-existent short-term savings account'));
  }

  /// Returns the most optimal [AccountAnalysis] to use as a long-term savings.
  AccountAnalysis get longTermSavingsAccount {
    if (_longTermSavingsAccount != null) {
      return _longTermSavingsAccount!;
    }
    throw (Exception(
        'Attempt to access non-existent long-term savings account'));
  }

  /// Returns true if at least one IRA account exists for [OwnerType.self].
  bool get hasIraAccountForSelf => _hasIraAccountForSelf;

  /// Returns true if at least one IRA account exists for [OwnerType.spouse].
  bool get hasIraAccountForSpouse => _hasIraAccountForSpouse;

  /// Returns the most optimal [AccountAnalysis] to use as the target for Roth Conversions for self.
  /// Throws an exception if a Roth account does not exist for the spouse.
  AccountAnalysis get rothAccountForSelf {
    if (_rothAccountForSelf != null) {
      return _rothAccountForSelf!;
    }
    throw (Exception('Attempt to access non-existent self ROTH account'));
  }

  /// Returns the most optimal [AccountAnalysis] to use as the target for Roth Conversions for spouse,
  /// or null, if not ROTH account exists for [OwnerType.spouse].
  AccountAnalysis? get rothAccountForSpouse {
    return _rothAccountForSpouse!;
  }

  /// Returns the lowest earning taxable savings account.
  AccountAnalysis? get _lowestEarningTaxableSavingsAccount {
    AccountAnalysis? lowestEarningAccount;
    for (final accountAnalysis in accountAnalyses) {
      if (accountAnalysis.type == AccountType.taxableSavings &&
          (lowestEarningAccount == null ||
              lowestEarningAccount.roiTotal > accountAnalysis.roiTotal)) {
        lowestEarningAccount = accountAnalysis;
      }
    }
    if (lowestEarningAccount == null) {
      throw (Exception(
          'Analysis requires at least one taxable savings account.'));
    }
    return lowestEarningAccount;
  }

  /// Returns the highest earning taxable savings or brokerage account.
  AccountAnalysis? get _highestEarningTaxableAccount {
    AccountAnalysis? highestEarningAccount;
    for (final accountAnalysis in accountAnalyses) {
      if (accountAnalysis.type.isTaxable &&
          (highestEarningAccount == null ||
              highestEarningAccount.roiTotal < accountAnalysis.roiTotal)) {
        highestEarningAccount = accountAnalysis;
      }
    }
    if (highestEarningAccount == null) {
      throw (Exception(
          'Analysis requires at least one taxable savings or brokerage account.'));
    }
    return highestEarningAccount;
  }

  /// Returns the highest earning accounts for [selfAccount] and [spouseAccount] for the specified [accountType].
  (AccountAnalysis? selfAccount, AccountAnalysis? spouseAccount)
      _highestEarningAccountByType(AccountType accountType) {
    AccountAnalysis? selfAccount;
    AccountAnalysis? spouseAccount;
    for (final accountAnalysis in accountAnalyses) {
      if (accountAnalysis.type == accountType) {
        if (accountAnalysis.ownerType == OwnerType.self &&
            (selfAccount == null ||
                selfAccount.roiTotal < accountAnalysis.roiTotal)) {
          selfAccount = accountAnalysis;
        }
        if (accountAnalysis.ownerType == OwnerType.spouse &&
            (spouseAccount == null ||
                spouseAccount.roiTotal < accountAnalysis.roiTotal)) {
          spouseAccount = accountAnalysis;
        }
      }
    }
    return (selfAccount, spouseAccount);
  }

  /// Pushes the current state of all [AccountAnalysis] to state stacka.
  void saveState() {
    for (final accountAnalysis in accountAnalyses) {
      accountAnalysis.saveState();
    }
  }

  /// Pops all [AccountAnalysis] state stacks using the result to update their current state
  void restoreState() {
    for (final accountAnalysis in accountAnalyses) {
      accountAnalysis.restoreState();
    }
  }

  /// Restores current state from the earliest/first stack entry of all [AccountAnalysis]. Clears thier stack.
  void restoreOriginalState() {
    for (final accountAnalysis in accountAnalyses) {
      accountAnalysis.restoreOriginalState();
    }
  }

  /// Returns a list [AccountAnalysis] for all accounts of type [accountType] and owned by [ownerType].
  /// If [ownerType] is omitted accounts for both self and (if married) spouse is returned.
  List<T> findAllAccountsByType<T>(AccountType accountType,
      {OwnerType? ownerType}) {
    List<AccountAnalysis> accountAnalyses =
        filteredAccounts(accountType: accountType, ownerType: ownerType);
    return accountAnalyses.whereType<T>().toList();
  }

  /// Returns a list [SavingsAccountAnalysis] for all taxable savings accounts owned by [ownerType].
  /// If [ownerType] is omitted accounts for both self and (if married) spouse is returned.
  List<SavingsAccountAnalysis> findAllSavingsAcconts({OwnerType? ownerType}) {
    return findAllAccountsByType<SavingsAccountAnalysis>(
        AccountType.taxableSavings,
        ownerType: ownerType);
  }

  /// Returns a list [BrokerageAccountAnalysis] for all brokerage accounts owned by [ownerType].
  /// If [ownerType] is omitted accounts for both self and (if married) spouse is returned.
  List<BrokerageAccountAnalysis> findAllBrokerageAcconts(
      {OwnerType? ownerType}) {
    return findAllAccountsByType<BrokerageAccountAnalysis>(
        AccountType.taxableBrokerage,
        ownerType: ownerType);
  }

  /// Returns a list [IraAccountAnalysis] for all IRA accounts owned by [ownerType].
  /// If [ownerType] is omitted accounts for both self and (if married) spouse is returned.
  List<IraAccountAnalysis> findAllIraAcconts({OwnerType? ownerType}) {
    return findAllAccountsByType<IraAccountAnalysis>(AccountType.traditionalIRA,
        ownerType: ownerType);
  }

  /// Returns a list [RothAccountAnalysis] for all ROTH accounts owned by [ownerType].
  /// If [ownerType] is omitted accounts for both self and (if married) spouse is returned.
  List<RothAccountAnalysis> findAllRothAcconts({OwnerType? ownerType}) {
    return findAllAccountsByType<RothAccountAnalysis>(
        AccountType.traditionalIRA,
        ownerType: ownerType);
  }

  /// Returns the list of [AccountAnalysis] that match the specified [ownerType] and [accountType].
  /// If [ownerType] is omitted, returns a list that matches either self or spouse (if married).
  List<AccountAnalysis> filteredAccounts(
      {OwnerType? ownerType, required AccountType accountType}) {
    return accountAnalyses
        .where(
          (accountAnalysis) =>
              accountAnalysis.type == accountType &&
              ((ownerType == null &&
                      accountAnalysis.ownerType == OwnerType.self) ||
                  (ownerType == OwnerType.self &&
                      accountAnalysis.ownerType == ownerType) ||
                  (ownerType == null &&
                      accountAnalysis.ownerType == OwnerType.spouse &&
                      analysisConfig.isMarried) ||
                  (ownerType == OwnerType.spouse &&
                      analysisConfig.isMarried &&
                      accountAnalysis.ownerType == ownerType)),
        )
        .toList();
  }

  /// Estimates / Returns the remaining RMD amount needed to take for the specified [ownerType], starting [month].
  ///
  /// Notes:
  /// * If [ownerType] is omitted, returns a list that matches either self or spouse (if married).
  /// * If [month] is omitted, the full year RMD amount is returned.
  double remainingRmd({OwnerType? ownerType, int month = 1}) {
    double result = 0.0;
    for (final accountAnalysis in filteredAccounts(
        ownerType: ownerType, accountType: AccountType.traditionalIRA)) {
      final IraAccountAnalysis iraAccountAnalysis =
          accountAnalysis as IraAccountAnalysis;
      result += iraAccountAnalysis.rmdDistributionPlan.remainingBalance(month);
    }
    return result;
  }

  /// Estimates/Returns the total yearly taxable income gains for the specified [ownerType]
  (double yearlyInterestGain, double yearlyDividendGain)
      yearToDateTaxableGainsByOwner(OwnerType ownerType) {
    double yearlyInterestGains = 0.0;
    double yearlyDividendGains = 0.0;
    for (final accountAnalysis in accountAnalyses) {
      if (accountAnalysis.ownerType == ownerType &&
          accountAnalysis.type.isTaxable) {
        final (double interestGain, double dividendGain) =
            accountAnalysis.yearToDateGains();
        yearlyInterestGains += interestGain;
        yearlyDividendGains += dividendGain;
      }
    }
    return (yearlyInterestGains, yearlyDividendGains);
  }

  /// Returns the total yearly captial gains for the specified [ownerType]
  ///
  /// Inputs:
  /// * [month] - Month of for the first month that has yet to be accued into the accounts.
  /// * [ownerType] - Owner of the accounts to be estimated.
  double estimateYearlyCapitalGainsByOwner(int month, OwnerType ownerType) {
    double result = 0.0;
    for (final accountAnalysis in filteredAccounts(
        ownerType: ownerType, accountType: AccountType.taxableBrokerage)) {
      result += accountAnalysis.yearlyCapitalGainEstimate(month);
    }
    return result;
  }

  /// Accrues account gains (income and price) for the specified [month].
  void accrueMonthAccountGains(int month) {
    for (final AccountAnalysis account in accountAnalyses) {
      account.accrueMonthlyGain(month);
    }
  }

  /// Accrues account gains (income and price) for the all months from [month] and later.
  void accrueRemainingAccountGains(int month) {
    for (final AccountAnalysis account in accountAnalyses) {
      account.accrueRemainingAccountGains(month);
    }
  }

  /// Returns the total avalible assets over all of the accounts for the specifed [accountType] and [ownerType].
  /// If [ownerType] is null, accounts for both self or spouse (if married) are included.
  double availibeBalanceByAccountType(AccountType accountType,
      {OwnerType? ownerType}) {
    double result = 0;
    final List<AccountAnalysis> accountAnalyses =
        filteredAccounts(ownerType: ownerType, accountType: accountType);
    for (final accountAnlysis in accountAnalyses) {
      result += accountAnlysis.availableBalance;
    }
    return result;
  }

  /// Returns the total yearly withdraws over all of the accounts for the specifed [accountType] and [ownerType].
  /// * [month] - should be the last month that made withdrawns. When omitted the current withdraw amount is returned.
  /// * Omitting [month] should only be done when withdraws for all 12 months have been made.
  double yearToDateWithdrawnByAccountType(
      AccountType accountType, OwnerType ownerType) {
    double result = 0;
    final List<AccountAnalysis> accountAnalyses =
        filteredAccounts(ownerType: ownerType, accountType: accountType);
    for (final accountAnlysis in accountAnalyses) {
      result += accountAnlysis.yearToDateWithdrawn();
    }
    return result;
  }

  /// Moves [amountOfAssetsToMove] between the [fromAccount] into the [toAccount] recording the move
  /// with the specified [month] and [memo].
  void moveAssetsBetweenAccounts({
    required double amountOfAssetsToMove,
    required AccountAnalysis fromAccount,
    required AccountAnalysis toAccount,
    required int month,
    String memo = '',
  }) {
    fromAccount.withdraw(amountOfAssetsToMove, month, memo);
    toAccount.deposit(amountOfAssetsToMove, month, memo);
  }

  /// Transfers Required Minimum Distributions into the specified accounts, i.e., for every IRA account, for the specified [month].
  /// * [month] - Month that the transfer is being perfromed.
  /// * [cashAmount] - Amount of the RMDs that should be diverted to [cashAccount].
  /// * [toAccount] - Account to transfer the balance of the RMDs.
  /// * [transferRmdBalance] - When true, the remaining RMD balance
  /// will be transferred instead of just the RMD for the month.
  ///
  /// Returns the amount of cash that was unable to be transferred into the [cashAccount];
  /// Zero is the [cashAmount] was fulfilled.
  ///
  double transferRmds(int month, double cashAmount, AccountAnalysis toAccount,
      {bool transferRmdBalance = false}) {
    final List<IraAccountAnalysis> iraAccounts = findAllIraAcconts();
    double remaimingCashNeed = cashAmount;
    for (final rmdAccount in iraAccounts) {
      final double cashReserved = rmdAccount.transferRmd(
        month: month,
        reserveAmount: remaimingCashNeed,
        reserveAccount: cashAccount,
        toAccount: toAccount,
        transferRmdBalance: transferRmdBalance,
      );
      remaimingCashNeed -= cashReserved;
    }
    return remaimingCashNeed;
  }

  /// Moves [amountOfAssetsToMove] between account accounts of type [accountType] into the [toAccount] recording the move
  /// with the specified [month] and [memo].
  void moveAssetsFromAccountTypeToAccount({
    required double amountOfAssetsToMove,
    required AccountType accountType,
    required AccountAnalysis toAccount,
    required int month,
    String memo = '',
  }) {
    var assetsWithdrawn = withdraw(amountOfAssetsToMove, accountType, month);
    if (assetsWithdrawn < amountOfAssetsToMove) {
      throw (Exception(
          'Request to move more assets than availible from accounts fo type ${accountType.label} to ${toAccount.name}'));
    }
    toAccount.deposit(assetsWithdrawn, month, memo);
  }

  /// Withdraws as much of [requestedWithdrawAmount] as possible from one or more accounts of [accountType] owned by [ownerType],
  /// and returns the amount withdrawn.
  /// If [ownerType] is omitted accounts for both self and (if married) spouse can be used for withdraw.
  /// Logs withdraw using the specified [month] and optional [memo].
  /// Returns a record (double assetsWithdrawn, bool accountsAreEmpty)
  double withdraw(
      double requestedWithdrawAmount, AccountType accountType, int month,
      {OwnerType? ownerType, String memo = ''}) {
    List<AccountAnalysis> accountAnalayses =
        findAllAccountsByType<AccountAnalysis>(accountType,
            ownerType: ownerType);
    double totalAssetsWithdrawn = 0.0;
    double nextWithdrawAmount = requestedWithdrawAmount;

    for (final fromAccount in accountAnalayses) {
      final assetsWithdrawn = fromAccount.withdraw(
          nextWithdrawAmount, month, memo,
          partialWithDrawAllowed: true);
      totalAssetsWithdrawn += assetsWithdrawn;
      nextWithdrawAmount -= assetsWithdrawn;
      if (totalAssetsWithdrawn >= requestedWithdrawAmount) {
        break;
      }
    }
    return totalAssetsWithdrawn;
  }

  /// Returns true if one or more accounts of [accountType] owned by [ownerType] exist and
  /// at least on of those accounts has a non-zero balance.
  /// * Note: If [ownerType] is omitted accounts for both self and (if married) spouse are checked.
  bool hasAssets(AccountType accountType, {OwnerType? ownerType}) {
    List<AccountAnalysis> accountAnalayses =
        findAllAccountsByType<AccountAnalysis>(accountType,
            ownerType: ownerType);
    for (final account in accountAnalayses) {
      if (account.availableBalance > 0.0) {
        return true;
      }
    }
    return false;
  }

  /// Pays [amount] from savings accounts.
  /// * [amountToPay] - Amount that needs to be payed.
  /// * [paymentMonth] - MOnth number when the payment must be made.
  /// * [memo] - To be used to document payments in the trasaction log.
  void payExpense(double amountToPay, int paymentMonth, {String memo = ''}) {
    final cashAccounts = findAllSavingsAcconts();
    for (final cashAccount in cashAccounts) {
      final double amountPaid = cashAccount.pay(
          paymentAmount: amountToPay, paymentMonth: paymentMonth, memo: memo);
      if (amountPaid == amountToPay) {
        break;
      }
      amountToPay -= amountPaid;
    }
    if (amountToPay > 0) {
      throw (Exception('Insufficient assets in savings to pay expense'));
    }
  }

  /// Returns an array of account avalible balances in the same order defined in the accountInforProvider.
  List<double> allAccountBalances() {
    return accountAnalyses.map<double>((accountAnalysis) => accountAnalysis.availableBalance).toList();
  }

  /// Adds a summary record to the transaction log, recording the account balance
  /// for all accounts.
  void logAccountBalances() {
    for (final account in accountAnalyses) {
      analysisConfig.transactionLog.add(TransactionEntry.info(
          transactionType: TransactionType.accountInfo,
          transactionDate: (year: targetYear, month: 0),
          extraInfo: account.name,
          value: account.availableBalance,
          memo: 'Account balance'));
    }
  }
}
