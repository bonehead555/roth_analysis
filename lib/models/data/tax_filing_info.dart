import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';
import '../enums/filing_status.dart';
import '../enums/filing_state.dart';

/// Used to manage configiuration information for income streams.
/// * [filingStatus] - Federal filing status, e.g., single, married-filing-jointly, head-of-household.
/// * [filingState] - Filing state
/// * [stateTaxPercentage] - State income tax rate (e.g., 0.04). Valid only when state is "OTHER".
/// * [stateStandardDeduction] - Stste standard deduction. Valid only when state is "OTHER".
/// * [stateTaxesSS] - True if state taxes sociaal security. Valid only when state is "OTHER".
/// * [stateTaxesRetirementIncome] - True is state taxes pension and IRA income. Valid only when state is "OTHER".
/// * [localTaxPercentage] - Local income tax rate (e.g., 0.04).
class TaxFilingInfo extends BaseInfo {
  final FilingStatus filingStatus;
  final FilingState filingState;
  final double stateTaxPercentage;
  final double stateStandardDeduction;
  final bool stateTaxesSS;
  final bool stateTaxesRetirementIncome;
  final double localTaxPercentage;

  /// Constructor.
  /// * [filingStatus] - Federal filing status, e.g., single, married-filing-jointly, head-of-household.
  ///  Defaults to single.
  /// * [filingState] - Filing state. Defaults to "OTHER".
  /// * [stateTaxPercentage] - State income tax rate (e.g., 0.04). Valid only when state is "OTHER". Defaults to 0.04.
  /// * [stateStandardDeduction] - Stste standard deduction. Valid only when state is "OTHER". Defaults to 0.0.
  /// * [stateTaxesSS] - True if state taxes social security. Valid only when state is "OTHER". Defaults to false.
  /// * [stateTaxesRetirementIncome] - True is state taxes pension and IRA income. Valid only when state is "OTHER".
  /// Defaults to false.
  /// * [localTaxPercentage] - Local income tax rate (e.g., 0.04). Defaults to 0.0.
  const TaxFilingInfo({
    this.filingStatus = FilingStatus.single,
    this.filingState = FilingState.other,
    this.stateTaxPercentage = 0.04,
    this.stateStandardDeduction = 0.0,
    this.stateTaxesSS = false,
    this.stateTaxesRetirementIncome = false,
    this.localTaxPercentage = 0.0,
  });

  // Strings used for JSON encoding.
  static const _filingStatusKey = 'filingStatus';
  static const _filingStateKey = 'filingState';
  static const _stateTaxPercentageKey = 'stateTaxPercentage';
  static const _stateStandardDeductionKey = 'stateStandardDeduction';
  static const _stateTaxesSSKey = 'stateTaxesSS';
  static const _stateTaxesRetirementIncomeKey = 'stateTaxesRetirementIncome';
  static const _localTaxPercentageKey = 'localTaxPercentage';

  /// Returns the class properties that Equatable should process.
  @override
  List<Object> get props => [
        filingStatus.label,
        filingState.label,
        stateTaxPercentage,
        stateStandardDeduction,
        stateTaxesSS,
        stateTaxesRetirementIncome,
        localTaxPercentage,
      ];
  @override
  bool get stringify => true;

  /// Returns a new immutable [TaxFilingInfo] class updated with the specified arguments.
  TaxFilingInfo copyWith({
    FilingStatus? filingStatus,
    FilingState? filingState,
    double? stateTaxPercentage,
    double? stateStandardDeduction,
    bool? stateTaxesSS,
    bool? stateTaxesRetirementIncome,
    double? localTaxPercentage,
  }) =>
      TaxFilingInfo(
        filingStatus: filingStatus ?? this.filingStatus,
        filingState: filingState ?? this.filingState,
        stateTaxPercentage: stateTaxPercentage ?? this.stateTaxPercentage,
        stateStandardDeduction:
            stateStandardDeduction ?? this.stateStandardDeduction,
        stateTaxesSS: stateTaxesSS ?? this.stateTaxesSS,
        stateTaxesRetirementIncome:
            stateTaxesRetirementIncome ?? this.stateTaxesRetirementIncome,
        localTaxPercentage: localTaxPercentage ?? this.localTaxPercentage,
      );

  /// Validates the fields of the [IncomeInfo], storing any issues in the provided [messageService].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [isMarried] - Provided so that validating can take into account whether the owner is married or not.
  void validate(MessageService messageService, bool isMarried) {
    if (filingStatus == FilingStatus.single && isMarried) {
      messageService.addError(
          'Filing Information: Invalid Federal Tax Filing Status for married individual.');
    }
    if (filingStatus == FilingStatus.marriedFilingSeparately) {
      messageService.addError(
          'Filing Information: Federal Filing Status of ${FilingStatus.marriedFilingSeparately.label} is currently unsupported.');
    }
    if (filingState == FilingState.other && stateTaxPercentage < 0.0) {
      messageService.addError(
          'Filing Information: State taxing percentage must be greater than or equal to zero.');
    }
    if (localTaxPercentage < 0.0) {
      messageService.addError(
          'Filing Information: Local taxing percentage must be greater than or equal to zero.');
    }
  }

  /// Returns a map/dictionary of field name and value that can be used to generate JSON content.
  @override
  JsonMap toJsonMap() {
    return {
      _filingStatusKey: filingStatus.label,
      _filingStateKey: filingState.label,
      _stateTaxPercentageKey: stateTaxPercentage,
      _stateStandardDeductionKey: stateStandardDeduction,
      _stateTaxesSSKey: stateTaxesSS,
      _stateTaxesRetirementIncomeKey: stateTaxesRetirementIncome,
      _localTaxPercentageKey: localTaxPercentage,
    };
  }

  /// Returns an [TaxFilingInfo] object derived from the provided [data].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [data] - MAP of JSON keywords and values.
  /// * [ancestorKey] - Path string to the current nodes immediate ancestor, used to help generate relevant text strings
  /// for error/wanring/information issues encountered during processing.
  factory TaxFilingInfo.fromJsonMap(
    MessageService messageService,
    JsonMap data,
    String ancestorKey,
  ) {
    // create an Imcome from default constuctor for defining default values.
    const TaxFilingInfo defaultInfo = TaxFilingInfo();

    // Fetch PlanInfo.filingStatus
    FilingStatus filingStatus = getJsonFieldValue<FilingStatus>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _filingStatusKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.filingStatus,
      fieldEncoder: FilingStatus.fromLabel,
    );

    // Fetch PlanInfo.filingState
    FilingState filingState = getJsonFieldValue<FilingState>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _filingStateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.filingState,
      fieldEncoder: FilingState.fromLabel,
    );

    // Fetch PlanInfo.stateTaxPercentage
    double stateTaxPercentage = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _stateTaxPercentageKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.stateTaxPercentage,
    );

    // Fetch PlanInfo.stateTaxPercentage
    double stateStandardDeduction = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _stateStandardDeductionKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.stateStandardDeduction,
    );

    // Fetch PlanInfo.stateTaxesSS
    bool stateTaxesSS = getJsonBoolFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _stateTaxesSSKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.stateTaxesSS,
    );

    // Fetch PlanInfo.stateTaxesSS
    bool stateTaxesRetirementIncome = getJsonBoolFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _stateTaxesRetirementIncomeKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.stateTaxesRetirementIncome,
    );

    // Fetch PlanInfo.stateTaxPercentage
    double localTaxPercentage = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _localTaxPercentageKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.localTaxPercentage,
    );

    // Check to see if there were additiona / unknown fields in the json
    checkForUnknownFields(
      messageService: messageService,
      jsonMap: data,
      ansestorKey: ancestorKey,
    );

    return TaxFilingInfo(
      filingStatus: filingStatus,
      filingState: filingState,
      stateTaxPercentage: stateTaxPercentage,
      stateStandardDeduction: stateStandardDeduction,
      stateTaxesSS: stateTaxesSS,
      stateTaxesRetirementIncome: stateTaxesRetirementIncome,
      localTaxPercentage: localTaxPercentage,
    );
  }
}
