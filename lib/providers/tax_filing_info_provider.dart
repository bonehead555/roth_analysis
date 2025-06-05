import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/tax_filing_info.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';

/// Riverpod provider class for [TaxFilingInfo].
class TaxFilingInfoProvider extends StateNotifier<TaxFilingInfo> {
  TaxFilingInfoProvider() : super(const TaxFilingInfo());

  /// Updates the specified information by creating a new copy of [TaxFilingInfo].
  /// * [filingStatusEnum] - Federal filing status, e.g., single, married-filing-jointly, head-of-household.
  /// * [filingStateEnum] - Filing state.
  /// * [otherStateTaxPercentage] - State income tax rate (e.g., 0.04). Valid only when state is "OTHER".
  /// * [otherStateTaxDeduction] - Stste standard deduction. Valid only when state is "OTHER".
  /// * [otherStateTaxableSS] - True if state taxes sociaal security. Valid only when state is "OTHER".
  /// * [otherStateTaxableRetirementIncome] - True is state taxes pension and IRA income. Valid only when state is "OTHER".
  /// * [localTaxPercentage] - Local income tax rate (e.g., 0.04).
  void update({
    FilingStatus? filingStatusEnum,
    FilingState? filingStateEnum,
    double? otherStateTaxPercentage,
    double? otherStateTaxDeduction,
    bool? otherStateTaxableSS,
    bool? otherStateTaxableRetirementIncome,
    double? localTaxPercentage,
  }) {
    state = state.copyWith(
      filingStatus: filingStatusEnum,
      filingState: filingStateEnum,
      stateTaxPercentage: otherStateTaxPercentage,
      stateStandardDeduction: otherStateTaxDeduction,
      stateTaxesSS: otherStateTaxableSS,
      stateTaxesRetirementIncome: otherStateTaxableRetirementIncome,
      localTaxPercentage: localTaxPercentage,
    );
  }

  /// Updates the entire [TaxFilingInfo] with [newInfo].  Used for example when new data is read from a file.
  void updateAll(TaxFilingInfo newInfo) {
    state = newInfo;
  }
}

typedef TaxFilingInfoNotifierProvider
    = StateNotifierProvider<TaxFilingInfoProvider, TaxFilingInfo>;

/// [TaxFilingInfoProvider] for the tax configuration.
final taxFilingInfoProvider = TaxFilingInfoNotifierProvider((ref) {
  return TaxFilingInfoProvider();
});
