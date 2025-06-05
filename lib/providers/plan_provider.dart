import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/plan_info.dart';

/// Riverpod provider class for [PlanInfo].
class PlanProvider extends StateNotifier<PlanInfo> {
  PlanProvider() : super(const PlanInfo());

  /// Updates the specified information by creating a new copy of [PlanInfo].
  /// * [planStartDate] - Year and month when the plan begins.
  /// * [planEndDate] - Year and month when the plan ends.
  /// * [yearlyExpenses] - Yearly expenses at the start of plan.
  /// * [cola] - Cost of Living Adjustement to be used for the plan duration, e.g., 0.03.
  void update({
    DateTime? planStartDate,
    DateTime? planEndDate,
    double? yearlyExpenses,
    double? cola,
  }) {
    state = state.copyWith(
      planStartDate: planStartDate,
      planEndDate: planEndDate,
      yearlyExpenses: yearlyExpenses,
      cola: cola,
    );
  }

  /// Updates the entire [PlanInfo] with [newInfo].  Used for example when new data is read from a file.
  void updateAll(PlanInfo newInfo) {
    state = newInfo;
  }
}

typedef PlanNotifierProvider = StateNotifierProvider<PlanProvider, PlanInfo>;

/// [PlanProvider] for the general plan configuration.
final planProvider = PlanNotifierProvider((ref) {
  return PlanProvider();
});
