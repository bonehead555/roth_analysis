import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

/// Used to manage configiuration information for the overall plan.
/// * [planStartDate] - Year and month when the plan begins.
/// * [planEndDate] - Year and month when the plan ends.
/// * [yearlyExpenses] - Yearly expenses at the start of plan.
/// * [cola] - Cost of Living Adjustement to be used for the plan duration, e.g., 0.03.
class PlanInfo extends BaseInfo {
  final DateTime? planStartDate;
  final DateTime? planEndDate;
  final double yearlyExpenses;
  final double cola;

  /// Constuctor.
  /// * [planStartDate] - Year and month when the plan begins.
  /// * [planEndDate] - Year and month when the plan ends.
  /// * [yearlyExpenses] - Yearly expenses at the start of plan/
  /// * [cola] - Cost of Living Adjustement to be used for the paln duration
  const PlanInfo({
    this.planStartDate,
    this.planEndDate,
    this.yearlyExpenses = 0.0,
    this.cola = CostOfLiving.defaultColaPercent / 100.0,
  });

  // Strings used for JSON encoding.
  static const _planStartDateKey = 'planStartDate';
  static const _planEndDateKey = 'planEndDate';
  static const _yearlyExpensesKey = 'yearlyExpenses';
  static const _colaKey = 'cola';

  /// Returns the class properties that Equatable should process.
  @override
  List<Object?> get props => [planStartDate, planEndDate, yearlyExpenses, cola];
  @override
  bool get stringify => true;

  /// Returns a new immutable [PlanInfo] object updated with the specified arguments.
  PlanInfo copyWith({
    DateTime? planStartDate,
    DateTime? planEndDate,
    double? yearlyExpenses,
    double? cola,
  }) =>
      PlanInfo(
        planStartDate: planStartDate ?? this.planStartDate,
        planEndDate: planEndDate ?? this.planEndDate,
        yearlyExpenses: yearlyExpenses ?? this.yearlyExpenses,
        cola: cola ?? this.cola,
      );

  /// Validates the fields of the [PlanInfo], storing any isuses in the provided [messageService].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  void validate(MessageService messageService) {
    if (planStartDate == null) {
      messageService.addError('Plan: Missing required plan start date.');
    }
    if (planStartDate == null) {
      messageService.addError('Plan: Missing required plan end date.');
    }
    if (planStartDate != null &&
        planEndDate != null &&
        !planStartDate!.isBefore(planEndDate!)) {
      messageService
          .addError('Plan: Start date must be cronologically before end date.');
    }
    if (yearlyExpenses < 0) {
      messageService.addError(
          'Plan: Yearly expenses must be a value greater or equal to zero.');
    }
    if (cola < 0.0 || cola > 25.0) {
      messageService.addError('Plan: COLA rate must be between 0.0 and 25.');
    }
  }

  /// Returns a map/dictionary of field name and value that can be used to generate JSON content.
  @override
  JsonMap toJsonMap() {
    return {
      _planStartDateKey: dateToString(planStartDate),
      _planEndDateKey: dateToString(planEndDate),
      _yearlyExpensesKey: yearlyExpenses,
      _colaKey: cola,
    };
  }

  /// Returns an [PlanInfo] object derived from the provided [data].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [data] - MAP of JSON keywords and values.
  /// * [ancestorKey] - Path string to the current nodes immediate ancestor, used to help generate relevant text strings
  /// for error/wanring/information issues encountered during processing.
  factory PlanInfo.fromJsonMap(
    MessageService messageService,
    JsonMap data,
    String ancestorKey,
  ) {
    // create an Imcome from default constuctor for defining default values.
    PlanInfo defaultInfo = const PlanInfo();

    // Fetch PlanInfo.planStartDate
    DateTime? planStartDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _planStartDateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.planStartDate,
    );

    // Fetch PlanInfo.planStartDate
    DateTime? planEndDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _planEndDateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.planEndDate,
    );

    // Fetch PlanInfo.yearlyExpenses
    double yearlyExpenses = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _yearlyExpensesKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.yearlyExpenses,
    );

    // Fetch PlanInfo.yearlyExpenses
    double cola = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _colaKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.cola,
    );

    // Check to see if there were additiona / unknown fields in the json
    checkForUnknownFields(
        messageService: messageService,
        jsonMap: data,
        ansestorKey: ancestorKey);

    return PlanInfo(
      planStartDate: planStartDate,
      planEndDate: planEndDate,
      yearlyExpenses: yearlyExpenses,
      cola: cola,
    );
  }
}
