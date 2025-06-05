import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';

/// Used to manage configiuration information a person in the analysis.
/// * [birthDate] - Perons birthdate.
/// * [isBlind] - True if person is blind.
/// * [isMarried] - True if person is married.
class PersonInfo extends BaseInfo {
  final DateTime? birthDate;
  final bool isBlind;
  final bool isMarried;

  // Constructor.
  /// * [birthDate] - Perons birthdate.
  /// * [isBlind] - True if person is blind. Defaults to false.
  /// * [isMarried] - True if person is married. Defaults to true.
  const PersonInfo(
      {this.birthDate, this.isBlind = false, this.isMarried = true});

  // JSON Key values
  static const _birthDateKey = 'birthDate';
  static const _isBlindKey = 'isBlind';
  static const _isMarriedKey = 'isMarried';

  /// Returns the class properties that Equatable should process.
  @override
  List<Object?> get props => [dateToString(birthDate), isBlind, isMarried];
  @override
  bool get stringify => true;

  /// Returns a new immutable [PersonInfo] class updated with the specified arguments.
  PersonInfo copyWith({DateTime? birthDate, bool? isBlind, bool? isMarried}) =>
      PersonInfo(
        birthDate: birthDate ?? this.birthDate,
        isBlind: isBlind ?? this.isBlind,
        isMarried: isMarried ?? this.isMarried,
      );

  /// Validates the fields of the [PersonInfo], storing any issues in the provided [messageService].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [ownerType] - Indicates whether this peros is in the role of self or spouse.
  void validate(MessageService messageService, OwnerType ownerType) {
    if (birthDate == null) {
      messageService
          .addError('Person ${ownerType.label}: Missing required birthdate.');
    }
  }

  /// Returns a map/dictionary of field name and value that can be used to generate JSON content.
  @override
  JsonMap toJsonMap() {
    return {
      _birthDateKey: dateToString(birthDate),
      _isBlindKey: isBlind,
      _isMarriedKey: isMarried,
    };
  }

  /// Returns an [PersonInfo] object derived from the provided [data].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [data] - MAP of JSON keywords and values.
  /// * [ancestorKey] - Path string to the current nodes immediate ancestor, used to help generate relevant text strings
  /// for error/wanring/information issues encountered during processing.
  factory PersonInfo.fromJsonMap(
    MessageService messageService,
    JsonMap data,
    String ancestorKey,
  ) {
    // create an IncomeInfo from default constuctor for defining default values.
    PersonInfo defaultInfo = const PersonInfo();

    // Fetch IncomeInfo.startdate
    DateTime? birthDate = getJsonDateFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _birthDateKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.birthDate,
    );

    // Fetch IncomeInfo.isBlind
    bool isBlind = getJsonBoolFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _isBlindKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.isBlind,
    );

    // Fetch IncomeInfo.isMarried
    bool isMarried = getJsonBoolFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _isMarriedKey,
      ansestorKey: ancestorKey,
      defaultValue: defaultInfo.isMarried,
    );

    // Check to see if there were additiona / unknown fields in the json
    checkForUnknownFields(
        messageService: messageService,
        jsonMap: data,
        ansestorKey: ancestorKey);

    return PersonInfo(
      birthDate: birthDate,
      isBlind: isBlind,
      isMarried: isMarried,
    );
  }
}
