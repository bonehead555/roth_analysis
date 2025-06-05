import 'dart:io';

import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

typedef TransactionDate = ({int year, int month});

enum TransactionType {
  deposit('Deposit'),
  withdraw('Withdraw'),
  payment('Payment'),
  gain('Gain'),
  accountInfo('AccountInfo'),
  taxInfo('TaxInfo'),
  incomeInfo('IncomeInfo');

  final String label;

  const TransactionType(this.label);
}

/// Manages a Single Transaction.
/// [when] - Specifes year and month formatted as yyyy/mm.
/// [transactionType] - The type of transaction. See [TransactionType].
/// [amount] - The amount that was transferred.
/// [accountName] - Name of the account where transaction occured.
/// [memo] - Description/Reason for the transfer.
class TransactionEntry {
  final String when;
  final TransactionType transactionType;
  final double amount;
  final String accountName;
  final double accountBalance;
  final String memo;

  /// Returns a well-formated date string.
  static String _fmtDate(TransactionDate transactionDate) {
    final (:year, :month) = transactionDate;
    return showYyyyMm(year, month);
  }

  /// Private/Default constructor.
  /// [transactionDate] - Specifes year and month formatted as (int year, int month).
  /// [transactionType] - The type of transaction. See [TransactionType].
  /// [amount] - The amount that was transferred.
  /// [accountName] - Name of the account where transaction occured.
  /// [accountBalance] - The availible balance inthe account.
  /// [memo] - Description/Reason for the transfer.
  TransactionEntry._({
    required TransactionDate transactionDate,
    required this.transactionType,
    required this.amount,
    required this.accountName,
    required this.accountBalance,
    required this.memo,
  }) : when = _fmtDate(transactionDate);

  /// Constructor for an entry that describes asset deposits into an account
  /// [transactionDate] - Specifes year and month formatted as (int year, int month)
  /// [amount] - The amount that was transferred
  /// [accountName] - Name of the account where transaction occured
  /// [accountBalance] - The availible balance inthe account.
  /// [memo] - Description/Reason for the transfer
  factory TransactionEntry.deposit({
    required TransactionDate transactionDate,
    required double amount,
    required String accountName,
    required double accountBalance,
    required String memo,
  }) =>
      TransactionEntry._(
        transactionDate: transactionDate,
        transactionType: TransactionType.deposit,
        amount: amount,
        accountName: accountName,
        accountBalance: accountBalance,
        memo: memo,
      );

  /// Constructor for an entry that describes asset withdraws from an account
  /// [transactionDate] - Specifes year and month formatted as (int year, int month)
  /// [amount] - The amount that was transferred
  /// [accountName] - Name of the account where transaction occured
  /// [accountBalance] - The availible balance inthe account.
  /// [memo] - Description/Reason for the transfer
  factory TransactionEntry.withdraw({
    required TransactionDate transactionDate,
    required double amount,
    required String accountName,
    required double accountBalance,
    required String memo,
  }) =>
      TransactionEntry._(
        transactionDate: transactionDate,
        transactionType: TransactionType.withdraw,
        amount: amount,
        accountName: accountName,
        accountBalance: accountBalance,
        memo: memo,
      );

  /// Constructor for an entry that describes payments from an account
  /// [transactionDate] - Specifes year and month formatted as (int year, int month)
  /// [amount] - The amount that was transferred
  /// [accountName] - Name of the account where transaction occured
  /// [accountBalance] - The availible balance inthe account.
  /// [memo] - Description/Reason for the transfer
  factory TransactionEntry.payment({
    required TransactionDate transactionDate,
    required double amount,
    required String accountName,
    required double accountBalance,
    required String memo,
  }) =>
      TransactionEntry._(
        transactionDate: transactionDate,
        transactionType: TransactionType.payment,
        amount: amount,
        accountName: accountName,
        accountBalance: accountBalance,
        memo: memo,
      );

  /// Constructor for an entry that describes gains within an account
  /// [transactionDate] - Specifes year and month formatted as (int year, int month)
  /// [amount] - The amount that was transferred
  /// [accountName] - Name of the account where transaction occured
  /// [accountBalance] - The availible balance inthe account.
  /// [memo] - Description/Reason for the transfer
  factory TransactionEntry.gain({
    required TransactionDate transactionDate,
    required double amount,
    required String accountName,
    required double accountBalance,
    required String memo,
  }) =>
      TransactionEntry._(
        transactionDate: transactionDate,
        transactionType: TransactionType.gain,
        amount: amount,
        accountName: accountName,
        accountBalance: accountBalance,
        memo: memo,
      );

  /// Constructor for an entry that describes general information about the simulation.
  /// [transactionType] - one of AccountInfo, TaxInfo, IncomeInfo
  /// [transactionDate] - Specifes year and month formatted as (int year, int month)
  /// [extraInfo] - Extra information than can optionally be logged. Managed in the [accountName] field.
  /// [value] - A transaction value that can be optionally logged. Managed in the [accountBalance] field
  /// [memo] - Description/Reason that can optionally be logged.
  factory TransactionEntry.info({
    required TransactionType transactionType,
    required TransactionDate transactionDate,
    String extraInfo = '',
    double value = 1.0,
    String memo = '',
  }) =>
      TransactionEntry._(
        transactionDate: transactionDate,
        transactionType: transactionType,
        amount: double.nan,
        accountName: extraInfo,
        accountBalance: value,
        memo: memo,
      );

  @override
  String toString() =>
      '$when, ${transactionType.label}, $accountName, ${amount.roundToTwoPlaces()}, ${accountBalance.roundToTwoPlaces()}, $memo';
}

/// Holds an ordered history of a list of [TransactionEntry]
class TransactionLog {
  final List<TransactionEntry> _transactionEntries = [];
  List<TransactionEntry> get entries => _transactionEntries;

  /// Addes [entry] to the log.
  ///
  /// Notes:
  /// * The entry will be addeded ONLY if the [entry].amount is greater than 0.0
  void add(TransactionEntry entry) {
    if (entry.amount.isNaN || entry.amount > 0.0) {
      _transactionEntries.add(entry);
    }
  }

  /// Creates a string containing N lines where each line is a dump of one [TransactionEntry]
  String dumpLog() {
    StringBuffer buffer = StringBuffer();
    String header = 'Date, Type, Account, Amount, Balance, Memo';
    buffer.writeln(header);
    for (final TransactionEntry entry in entries) {
      String when = entry.when.toString();
      String label = entry.transactionType.label;
      String accountName = entry.accountName;
      String amount = entry.amount.isNaN ? '': entry.amount.roundToTwoPlaces().toString();
      String accountBalance = entry.accountBalance.roundToTwoPlaces().toString();
      String memo = entry.memo;
      String csv = '$when,$label,$accountName,$amount,$accountBalance,$memo';
      buffer.writeln(csv);
    }
    return buffer.toString();
  }

  /// Writes/Dumps the [TransactionLog] to a CSV file specified as [fullPath]
  /// Where each the logs [TransactionEntry] is one CSV line.
  void dumpToFile(String fullPath) {
    final file = File(fullPath);
    file.writeAsStringSync(dumpLog());
  }
}
