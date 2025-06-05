import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/models/enums/color_option.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:uuid/uuid.dart';

/// Returns a UUID provider from the UUID library package
const Uuid _uuid = Uuid();

/// Returns the next integer value avalible for creating a default name, see [_nextName]
int _nextVal = 0;

/// Returns a placeholder account name of the form 'Acct1234'
/// Where the number portion increments for each new name.
String _nextName() {
  NumberFormat formatter = NumberFormat("0000");
  return 'Scn${formatter.format(_nextVal++)}';
}

/// Class that manages the Roth Conversion Amount Constraint.
/// [type] - Species how the amount constraint should be interpreted. See [AmountConstraintType].
/// [fixedAmount] - Depends on type. Can be either a fixed Roth Conversion Amount must not
/// casue the specified amount to be exceeded.
/// Or, can be a federal limit on MAGI where the Roth COnversion amount cannot
class AmountConstraint extends Equatable {
  final AmountConstraintType type;
  final double fixedAmount;

  /// A text string that should be used for JSON encode/decode of the [type] field
  static const String _typeKey = 'type';

  /// Returns a text string that should be used for JSON encode/decode of the [fixedAmount] field
  static const String _fixedAmountKey = 'fixedAmount';

  /// A handy instance of an [AmountConstraint] object that can be used to access its default field values.
  static const AmountConstraint defaultInfo = AmountConstraint();

  /// A text string that identifies a path to  JSON field
  static const String ansestorKey = 'scenarioInfo.amountConstraint';

  /// Returns a default instaance of an [AmountConstraint].
  const AmountConstraint(
      {this.type = AmountConstraintType.magiLimit, this.fixedAmount = 0.0});

  /// Required by the [Equatable] base class. Used to specify field string values that should be processed by [Equatable]
  @override
  List<Object?> get props => [
        type,
        fixedAmount,
      ];

  /// Required by the [Equatable] base class to support [toString] operations.
  @override
  bool get stringify => true;

  /// Returns a copy of the [AmountConstraint] object, with updates to the specified fields
  /// [type] - Roth Conversion ammount constraint type to update (if specified)
  /// [fixedAmount] - Roth Conversion amount value to update (if specified)
  AmountConstraint copyWith({
    AmountConstraintType? type,
    double? fixedAmount,
  }) {
    return AmountConstraint(
      type: type ?? this.type,
      fixedAmount: fixedAmount ?? this.fixedAmount,
    );
  }

  /// Returns a Map object that repreesents the fields of the [AmountConstraint] object.
  JsonMap toJsonMap() {
    return {
      _typeKey: type.label,
      _fixedAmountKey: fixedAmount,
    };
  }

  /// Returns a [AmountConstraint] object from a MAP object
  /// [messageService] - Used to record any errors or problems encountered during the construction from the MAP object
  /// [data] - Map data to be used to create the [AmountConstraint] object
  /// [ansestorKey] - Text string that sepcifies the JSON path to the ansestor object.
  /// Used to help generate path strings for any errors or problems that get reported to the [messageService].
  factory AmountConstraint.fromJsonMap(
    MessageService messageService,
    JsonMap data,
    String ansestorKey,
  ) {
    // Fetch AmountConstraint.type
    AmountConstraintType type = getJsonFieldValue<AmountConstraintType>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _typeKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.type,
      fieldEncoder: AmountConstraintType.fromLabel,
    );

    // Fetch AmountConstraint.fixedAmount
    double fixedAmount = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _fixedAmountKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.fixedAmount,
    );

    // Check to see if there were additional / unknown fields in the json
    checkForUnknownFields(
      messageService: messageService,
      jsonMap: data,
      ansestorKey: ansestorKey,
    );

    return AmountConstraint(type: type, fixedAmount: fixedAmount);
  }
}

/// Class that manages configuration information for a single Roth Conversion Scenario.
/// [id] - An auto-generated [id] used to aid Flutter's tracking of a [ScenarioInfo] object in a list
/// [name] - Textual name of the scenario.
/// [colorOption] - Color to use for displaying graphical scenario results.
/// [amountConstraint] - Configuration for how the Roth Conversion shall be performed.
/// [startDateConstraint] - Configuration for the year Roth Conversions should start.
/// [specificStartDate] - Date/Year Roth Conversions should start when [startDateConstraint] indicates
/// it starts on a fixed date.
/// [endDateConstraint] - Configuration for the year Roth Conversions should end
/// [specificEndDate] - Date/Year Roth Conversions should end when [endDateConstraint] indicates
/// it ends on a fixed date.
/// [stopWhenTaxableIncomeUnavailible] - Configuration that indicates that Roth Conversions should end if there
/// are insufficient taxable assets to pay for the additional Roth Conversion taxes.
class ScenarioInfo extends BaseInfo {
  static const int maxNameLength = 10;
  final String id;
  final String name;
  final ColorOption colorOption;
  final AmountConstraint amountConstraint;
  final ConversionStartDateConstraint startDateConstraint;
  final DateTime? specificStartDate;
  final ConversionEndDateConstraint endDateConstraint;
  final DateTime? specificEndDate;
  final bool stopWhenTaxableIncomeUnavailible;

  /// Text strings that should be used for JSON encode/decode the corresponding field
  static const _nameKey = 'name';
  static const _colorOptionKey = 'colorEnum';
  static const _amountConstraintKey = 'amountConstraint';
  static const _startDateConstraintKey = 'startDateConstraint';
  static const _specifcStartDateKey = 'specificStartDate';
  static const _endDateConstraintKey = 'endDateConstraint';
  static const _specificEndDateKey = 'specificEndDate';
  static const _stopWhenTaxableIncomeUnavilibleKey =
      'stopWhenTaxableIncomeUnavilible';

  /// A handy instance of an [ScenarioInfo] object that can be used to access its default field values.
  static ScenarioInfo defaultInfo = ScenarioInfo();

  /// Returns a [SenarioInfo] object created based on provided values (if provided)
  /// [name] - Textual name of the scenario. Auto-generated if omitted.
  /// [colorOption] - Color to use for displaying graphical scenario results. Defaults to blue.
  /// [amountConstraint] - Configuration for how the Roth Conversion shall be performed. Defaults to onPlanStart.
  /// [startDateConstraint] - Year the Roth Conversions should start.
  /// [specificStartDate] - Date/Year the Roth Conversions should start when [startDateConstraint] indicates
  /// it starts on a fixed date. Defaults to null.
  /// [endDateConstraint] - Year the Roth Conversions should end. Defailts to endOfPlan.
  /// [specificEndDate] - Date/Year the Roth Conversions should end when [endDateConstraint] indicates
  /// it ends on a fixed date. Defaults to null.
  /// [stopWhenTaxableIncomeUnavailible] - Indicates whether Roth Conversions should end if there
  /// are insufficient taxable assets to pay for the additional Roth Conversion taxes. Defaults to true.
  ScenarioInfo({
    String? name,
    this.colorOption = ColorOption.blue,
    this.amountConstraint = AmountConstraint.defaultInfo,
    this.startDateConstraint = ConversionStartDateConstraint.onPlanStart,
    this.specificStartDate,
    this.endDateConstraint = ConversionEndDateConstraint.onEndOfPlan,
    this.specificEndDate,
    this.stopWhenTaxableIncomeUnavailible = true,
  })  : name = name ?? _nextName(),
        id = _uuid.v4();

  /// Required by the [Equatable] base class. Used to specify field string values that should be processed by [Equatable]
  @override
  List<Object?> get props => [
        name,
        colorOption.label,
        amountConstraint,
        startDateConstraint.label,
        dateToString(specificStartDate),
        endDateConstraint.label,
        dateToString(specificEndDate),
        stopWhenTaxableIncomeUnavailible,
      ];

  /// Required by the [Equatable] base class to support [toString] operations.
  @override
  bool get stringify => true;

  /// Returns a copy of the [ScenarioInfo] object, with optional updates to the specified fields
  /// [name] - Textual name of the scenario.
  /// [colorOption] - Color to use for displaying graphical scenario results.
  /// [amountConstraint] - Configuration for how the Roth Conversion shall be performed.
  /// [startDateConstraint] - Year the Roth Conversions should start.
  /// [specificStartDate] - Date/Year the Roth Conversions should start when [startDateConstraint] indicates
  /// it starts on a fixed date.
  /// [endDateConstraint] - Year the Roth Conversions should end. Defailts to endOfPlan.
  /// [specificEndDate] - Date/Year the Roth Conversions should end when [endDateConstraint] indicates
  /// it ends on a fixed date.
  /// [stopWhenTaxableIncomeUnavailible] - Indicates whether Roth Conversions should end if there
  /// are insufficient taxable assets to pay for the additional Roth Conversion taxes.
  ScenarioInfo copyWith({
    String? name,
    ColorOption? colorOption,
    AmountConstraint? amountConstraint,
    ConversionStartDateConstraint? startDateConstraint,
    DateTime? specificStartDate,
    ConversionEndDateConstraint? endDateConstraint,
    DateTime? specificEndDate,
    bool? stopWhenTaxableIncomeUnavailible,
  }) {
    return ScenarioInfo(
        name: name ?? this.name,
        colorOption: colorOption ?? this.colorOption,
        amountConstraint: amountConstraint ?? this.amountConstraint,
        startDateConstraint: startDateConstraint ?? this.startDateConstraint,
        specificStartDate: specificStartDate ?? this.specificStartDate,
        endDateConstraint: endDateConstraint ?? this.endDateConstraint,
        specificEndDate: specificEndDate ?? this.specificEndDate,
        stopWhenTaxableIncomeUnavailible: stopWhenTaxableIncomeUnavailible ??
            this.stopWhenTaxableIncomeUnavailible);
  }

  /// Validates the configuration values of the [ScenarioInfo] and throws an exception if someting is
  /// found to be invalid.
  void validate({
    required MessageService messageService,
    DateTime? planStartDate,
    DateTime? planEndDate,
    DateTime? rmdStartDate,
  }) {
    String showName = name.isEmpty ? '?' : name;
    if (name.isEmpty || name.length > maxNameLength) {
      messageService.addError(
          'Scenario "$showName": Name must be a text string between 1 and $maxNameLength characters.');
    }

    if (amountConstraint.fixedAmount < 0.0) {
      messageService.addError(
          'Scenario "$name": Yearly amount constraint must be greater than or equal to zero.');
    }

    if (startDateConstraint == ConversionStartDateConstraint.onFixedDate &&
        specificStartDate == null) {
      messageService
          .addError('Scenario: $name: Missing required start date constraint.');
    }
    if (endDateConstraint == ConversionEndDateConstraint.onFixedDate &&
        specificEndDate == null) {
      messageService
          .addError('Scenario: $name: Missing required end date constraint.');
    }
    if (startDateConstraint == ConversionStartDateConstraint.onFixedDate &&
        specificStartDate != null &&
        planStartDate != null &&
        specificStartDate!.isBefore(planStartDate)) {
      messageService.addWarning(
          'Scenario "$showName": Scenario start date should not be cronologically before plan start date.');
    }
    if (endDateConstraint == ConversionEndDateConstraint.onFixedDate &&
        specificEndDate != null &&
        planEndDate != null &&
        specificEndDate!.isAfter(planEndDate)) {
      messageService.addWarning(
          'Scenario "$showName": Scenario end date should be cronologically before plan end date.');
    }
    if (startDateConstraint == ConversionStartDateConstraint.onFixedDate &&
        endDateConstraint == ConversionEndDateConstraint.onFixedDate &&
        specificStartDate != null &&
        specificEndDate != null &&
        specificStartDate!.isAfter(specificEndDate!)) {
      messageService.addError(
          'Scenario "$showName": Scenario start date must not be cronologically before scenario end date.');
    }
    if (startDateConstraint == ConversionStartDateConstraint.onFixedDate &&
        endDateConstraint == ConversionEndDateConstraint.onRmdStart &&
        specificStartDate != null &&
        rmdStartDate != null &&
        !specificStartDate!.isBefore(rmdStartDate)) {
      messageService.addWarning(
          'Scenario "$showName": Scenario start date shouold be cronologically before RMD start date.');
    }
  }

  /// Returns a Map object that repreesents the fields of the [ScenarioInfo] object.
  @override
  JsonMap toJsonMap() {
    return {
      _nameKey: name,
      _colorOptionKey: colorOption.label,
      _amountConstraintKey: amountConstraint.toJsonMap(),
      _startDateConstraintKey: startDateConstraint.label,
      _specifcStartDateKey: dateToString(specificStartDate),
      _endDateConstraintKey: endDateConstraint.label,
      _specificEndDateKey: dateToString(specificEndDate),
      _stopWhenTaxableIncomeUnavilibleKey: stopWhenTaxableIncomeUnavailible,
    };
  }

  /// Returns a [ScenarioInfo] object from a MAP object
  /// [messageService] - Used to record any errors or problems encountered during the construction from the MAP object
  /// [data] - Map data to be used to create the [ScenarioInfo] object
  /// [ansestorKey] - Text string that sepcifies the JSON path to the ansestor object.
  /// Used to help generate path strings for any errors or problems that get reported to the [messageService].
  factory ScenarioInfo.fromJsonMap(
    MessageService messageService,
    JsonMap data,
    String ansestorKey,
  ) {
    // create a variable that identifies this JSON field

    // Fetch Scenario.name
    String name = getJsonStringFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _nameKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.name,
    );

    // Fetch Scenario.colorOption
    ColorOption colorOption = getJsonFieldValue<ColorOption>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _colorOptionKey,
      ansestorKey: ansestorKey,
      fieldEncoder: ColorOption.fromLabel,
      defaultValue: defaultInfo.colorOption,
    );

    // Fetch Scenario.amountConstraint
    AmountConstraint amountConstraint =
        getNestedJsonFieldValue<AmountConstraint>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _amountConstraintKey,
      ansestorKey: ansestorKey,
      fieldEncoder: AmountConstraint.fromJsonMap,
      defaultValue: defaultInfo.amountConstraint,
    );

    // Fetch Scenario.startDateConstraint
    ConversionStartDateConstraint startDateConstraint =
        getJsonFieldValue<ConversionStartDateConstraint>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _startDateConstraintKey,
      ansestorKey: ansestorKey,
      fieldEncoder: ConversionStartDateConstraint.fromLabel,
      defaultValue: defaultInfo.startDateConstraint,
    );

    // Fetch Scenario.specificStartDate
    DateTime? specificStartDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _specifcStartDateKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.specificStartDate,
    );
    // Fetch Scenario.endDateConstraint
    ConversionEndDateConstraint endDateConstraint =
        getJsonFieldValue<ConversionEndDateConstraint>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _endDateConstraintKey,
      ansestorKey: ansestorKey,
      fieldEncoder: ConversionEndDateConstraint.fromLabel,
      defaultValue: defaultInfo.endDateConstraint,
    );

    // Fetch Scenario.specificEndDate
    DateTime? specificEndDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _specificEndDateKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.specificEndDate,
    );

    // Fetch Scenario.name
    bool stopWhenTaxableIncomeUnavilibleKey = getJsonBoolFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _stopWhenTaxableIncomeUnavilibleKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.stopWhenTaxableIncomeUnavailible,
    );

    return ScenarioInfo(
      name: name,
      colorOption: colorOption,
      amountConstraint: amountConstraint,
      startDateConstraint: startDateConstraint,
      specificStartDate: specificStartDate,
      endDateConstraint: endDateConstraint,
      specificEndDate: specificEndDate,
      stopWhenTaxableIncomeUnavailible: stopWhenTaxableIncomeUnavilibleKey,
    );
  }
}
