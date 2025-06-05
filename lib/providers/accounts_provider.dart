import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';

/// Riverpod provider class for a List of [AccountInfo].
class AccountsProvider extends StateNotifier<AccountInfos> {
  AccountsProvider() : super(AccountInfos.empty() /*_accountSources*/);

  /// Updates the entire list of [AccountInfo].  Used for example when new data is read from a file.
  void updateAll(AccountInfos newAccountInfos) {
    state = newAccountInfos;
  }

  /// Replaces the item specified by [oldInfo] with the item specified in [newInfo].
  void updateInfoItem(AccountInfo oldInfo, AccountInfo newInfo) {
    // Make sure the newInfo's roiIncome is zero'ed when account type is not taxableBrokerage.
    if (oldInfo.type != newInfo.type &&
        newInfo.type != AccountType.taxableBrokerage &&
        newInfo.roiIncome != 0.0) {
      newInfo = newInfo.copyWith(roiIncome: 0.0);
    }
    state = state.map((info) => info == oldInfo ? newInfo : info).toList();
  }

  /// Adds / inserts the item specified in [newInfo] at the location specified by [insertAt].
  bool addInfoItem(AccountInfo newInfo, int insertAt) {
    final AccountInfos newInfos = [...state];
    if (insertAt < 0) return false;
    if (insertAt > newInfos.length) return false;
    newInfos.insert(insertAt, newInfo);
    state = newInfos;
    return true;
  }

  /// Removes at the location specified in [removeAt].
  void removeInfoItemAt(int removeAt) {
    final AccountInfos newInfos = [...state];
    newInfos.removeAt(removeAt);
    state = newInfos;
  }

  /// Moves the item at [oldIndex] to the location specified at [newIndex].
  void moveInfoItem(int oldIndex, int newIndex) {
    final AccountInfos newInfos = [...state];
    final AccountInfo item = newInfos.removeAt(oldIndex);
    newInfos.insert(newIndex, item);
    state = newInfos;
  }
}

typedef AccountsNotifierProvider
    = StateNotifierProvider<AccountsProvider, AccountInfos>;

/// Riverpod provider for a List of [AccountInfo].
final accountInfoProvider = AccountsNotifierProvider((ref) {
  return AccountsProvider();
});

// Default list of accounts used for initial development.
// ignore: unused_element
final List<AccountInfo> _accountSources = [
  AccountInfo(
    type: AccountType.taxableSavings,
    balance: 100000.00,
    roiGain: 0.040,
  ),
  AccountInfo(
    type: AccountType.taxableBrokerage,
    balance: 100000.00,
    roiGain: 0.040,
  ),
  AccountInfo(
    name: 'MyRoth',
    type: AccountType.rothIRA,
    balance: 200000,
    roiGain: 0.05,
  ),
  AccountInfo(
      type: AccountType.traditionalIRA,
      owner: OwnerType.spouse,
      balance: 40400,
      roiGain: 0.07),
  AccountInfo(
    name: 'Schwab1',
    type: AccountType.taxableBrokerage,
    owner: OwnerType.self,
    balance: 1200000,
    costBasis: 30000,
    roiGain: 0.05,
    roiIncome: 0.029,
  ),
];
