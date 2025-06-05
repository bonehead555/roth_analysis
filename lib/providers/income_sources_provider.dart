import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';

/// Riverpod provider for a List of [IncomeInfo].
class IncomeSourcesProvider extends StateNotifier<IncomeInfos> {
  IncomeSourcesProvider() : super(IncomeInfos.empty() /*_incomeSources*/);

  /// Updates the entire list of [IncomeInfo].  Used for example when new data is read from a file.
  void updateAll(IncomeInfos newIncomeInfos) {
    state = newIncomeInfos;
  }

  /// Replaces the item specified by [oldInfo] with the item specified in [newInfo].
  void updateInfoItem(IncomeInfo oldInfo, IncomeInfo newInfo) {
    state = state.map((info) => info == oldInfo ? newInfo : info).toList();
  }

  /// Adds / inserts the item specified in [newInfo] at the location specified by [insertAt].
  bool addInfoItem(IncomeInfo newInfo, int insertAt) {
    final IncomeInfos newIncomeInfos = [...state];
    if (insertAt <  0) return false;
    if (insertAt > newIncomeInfos.length) return false;
    newIncomeInfos.insert(insertAt, newInfo);
    state = newIncomeInfos;
    return true;
  }

  /// Removes at the location specified in [removeAt].
  void removeInfoItemAt(int removeAt) {
    final IncomeInfos newIncomeInfos = [...state];
    newIncomeInfos.removeAt(removeAt);
    state = newIncomeInfos;
  }

  /// Moves the item at [oldIndex] to the location specified at [newIndex].
  void moveInfoItem(int oldIndex, int newIndex) {
    final IncomeInfos newIncomeInfos = [...state];
    final IncomeInfo item = newIncomeInfos.removeAt(oldIndex);
    newIncomeInfos.insert(newIndex, item);
    state = newIncomeInfos;
  }
}

typedef IncomeSourcesNotifierProvider
    = StateNotifierProvider<IncomeSourcesProvider, IncomeInfos>;

final incomeInfoProvider = IncomeSourcesNotifierProvider((ref) {
  return IncomeSourcesProvider();
});

// Default list of income streams used for initial development.
// ignore: unused_element
final List<IncomeInfo> _incomeSources = [
  IncomeInfo(
    type: IncomeType.socialSecurity,
    startDate: DateTime(2025, 11, 18),
  ),
  IncomeInfo(
      type: IncomeType.employment,
      yearlyIncome: 77000.00,
      startDate: DateTime.now(),
      endDate: DateTime(2025, 11, 18)),
  IncomeInfo(
    type: IncomeType.pension,
    owner: OwnerType.spouse,
    startDate: DateTime(2023, 12, 21),
    endDate: DateTime(2025, 11, 18),
  ),
  IncomeInfo(
    type: IncomeType.selfEmployment,
    yearlyIncome: 16000.00,
    owner: OwnerType.spouse,
    startDate: DateTime.now(),
    endDate: DateTime(2025, 11, 18),
  ),
];
