import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Helper to specify a list of [IncomeInfo].
typedef IncomeInfos = List<IncomeInfo>;

/// Used to manage configiuration information for income streams.
/// * [id] - Unique ID for the income item (based on UUID).
/// * [type] - Imcome type, e.g., regular, se;f-employed, Social Security, Pension.
/// * [owner] - Income owner, e.g., self, spouse.
/// * [yearlyIncome] - Yearly total income. NOte: independent of [startDate] and [endDate].
/// * [startDate] - Year and month when the income stream begins.
/// * [endDate] - Year and month when the income stream ends.
class IncomeInfo extends BaseInfo {
  final String id;
  final IncomeType type;
  final OwnerType owner;
  final double yearlyIncome;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Constuctor
  /// * [type] - Imcome type, e.g., regular, se;f-employed, Social Security, Pension.
  /// * [owner] - Income owner, e.g., self, spouse.
  /// * [yearlyIncome] - Yearly total income. NOte: independent of [startDate] and [endDate]. Defaults to 0.0.
  /// * [startDate] - Year and month when the income stream begins. Defaults to null.
  /// * [endDate] - Year and month when the income stream ends. Defaults to mull.
  IncomeInfo(
      {required this.type,
      this.owner = OwnerType.self,
      this.yearlyIncome = 0.0,
      this.startDate,
      this.endDate})
      : id = _uuid.v4();

  // Strings used for JSON encoding.
  static const _typeKey = 'type';
  static const _ownerKey = 'owner';
  static const _yearlyIncomeKey = 'yearlyIncome';
  static const _startDateKey = 'startDate';
  static const _endDateKey = 'endDate';

  /// Returns the class properties that Equatable should process.
  @override
  List<Object?> get props => [
        type.label,
        owner.label,
        yearlyIncome,
        dateToString(startDate),
        dateToString(endDate),
      ];
  @override
  bool get stringify => true;

  /// Returns a new immutable [IncomeInfo] class updated with the specified arguments.
  IncomeInfo copyWith(
          {IncomeType? type,
          OwnerType? owner,
          double? yearlyIncome,
          DateTime? startDate,
          DateTime? endDate}) =>
      IncomeInfo(
        type: type ?? this.type,
        owner: owner ?? this.owner,
        yearlyIncome: yearlyIncome ?? this.yearlyIncome,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  /// Validates the fields of the [IncomeInfo], storing any issues in the provided [messageService].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [incomeLineNumber] - Index of the income item being processed. Used to impove messages.
  /// * [isMarried] - Provided so that validating can take into account whether the owner is married or not.
  /// * [planStartDate] - Plan start date used to validate income stream start date is in range.
  /// * [planEndDate] - Plan end date used to validate income stream end date is in range.
  void validate(
    MessageService messageService,
    int incomeLineNumber, {
    required bool isMarried,
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) {
    if (!isMarried && owner == OwnerType.spouse) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Owner type of ${OwnerType.spouse.label} is not valid in a plan designed for a non-married tax filing.');
    }
    if (yearlyIncome < 0.0) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Yearly income must be greater than or equal to zero.');
    }
    if (startDate == null) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Missing required start date constraint.');
    }
    if (startDate != null &&
        planStartDate != null &&
        startDate!.isBefore(planStartDate)) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Income start date must be cronologically after plan start date.');
    }
    if (startDate != null &&
        planEndDate != null &&
        startDate!.isAfter(planEndDate)) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Income start date must be cronologically before plan end date.');
    }
    if (type != IncomeType.socialSecurity && endDate == null) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Missing required end date constraint.');
    }
    if (type != IncomeType.socialSecurity &&
        endDate != null &&
        planStartDate != null &&
        endDate!.isBefore(planStartDate)) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Income end date must be cronologically after plan start date.');
    }
    if (type != IncomeType.socialSecurity &&
        endDate != null &&
        planEndDate != null &&
        endDate!.isAfter(planEndDate)) {
      messageService.addError(
          'Income Entry $incomeLineNumber: Income end date must be cronologically before plan end date.');
    }
  }

  /// Returns a map/dictionary of field name and value that can be used to generate JSON content.
  @override
  JsonMap toJsonMap() {
    return {
      _typeKey: type.label,
      _ownerKey: owner.label,
      _yearlyIncomeKey: yearlyIncome,
      _startDateKey: dateToString(startDate),
      _endDateKey: dateToString(endDate),
    };
  }

  /// Returns an [IncomeInfo] object derived from the provided [data].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [data] - MAP of JSON keywords and values.
  /// * [ancestorKey] - Path string to the current nodes immediate ancestor, used to help generate relevant text strings
  /// for error/wanring/information issues encountered during processing.
  factory IncomeInfo.fromJsonMap(MessageService messageService,
      Map<String, dynamic> data, String ancestorKey) {
    // create an ImcomeInfo from default constuctor for defining default values.
    final IncomeInfo defaultInfo = IncomeInfo(type: IncomeType.employment);

    // Fetch IncomeInfo.type
    IncomeType type = getJsonFieldValue<IncomeType>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _typeKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.type,
      fieldEncoder: IncomeType.fromLabel,
    );

    // Fetch IncomeInfo.owner
    OwnerType owner = getJsonFieldValue<OwnerType>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _ownerKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.owner,
      fieldEncoder: OwnerType.fromLabel,
    );

    // Fetch IncomeInfo.yearlyIncome
    double yearlyIncome = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _yearlyIncomeKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.yearlyIncome,
    );

    // Fetch IncomeInfo.startdate
    DateTime? startDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _startDateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.startDate,
    );

    // Fetch IncomeInfo.endDate
    DateTime? endDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _endDateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.endDate,
    );

    // Check to see if there were additiona / unknown fields in the json
    checkForUnknownFields(
        messageService: messageService,
        jsonMap: data,
        ansestorKey: ancestorKey);

    return IncomeInfo(
      type: type,
      owner: owner,
      yearlyIncome: yearlyIncome,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
