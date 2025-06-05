import 'package:intl/intl.dart';
import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

int _nextVal = 0;

/// Returns a default account name of the form Acct1234.
String _nextName() {
  NumberFormat formatter = NumberFormat("0000");
  return 'Acct${formatter.format(_nextVal++)}';
}

typedef AccountInfos = List<AccountInfo>;

/// Used to manage configiuration information for user accounts.
/// * [name] - Name of the account.
/// * [id] - Unique ID for the account (based on UUID).
/// * [type] - Account type, e.g., savings, brokerage, IRA, Roth.
/// * [owner] - Account owner, e.g., self, spouse.
/// * [balance] - Account balance at plan start.
/// * [costBasis] - Amount of the balance that is considered costBasis. Relevant for brokerage accounts.
/// * [roiGain] - Yearly return on investemnt or rate of gain earned by the account. E.g., 0.25 is 25%.
/// * [roiIncome] - Yearly return on investemnt of taxable income earned by the account. E.g., 0.05 is 5%. Relevant for brokerage accounts.
class AccountInfo extends BaseInfo {
  static const int maxNameLength = 15;
  final String id;
  final String name;
  final AccountType type;
  final OwnerType owner;
  final double balance;
  final double costBasis;
  final double roiGain;
  final double roiIncome;

  /// Constructor
  /// * [name] - Name of the account. Creates a default of the form name of the form Acct1234.
  /// * [id] - Unique ID for the account (based on UUID).
  /// * [type] - Account type, e.g., savings, brokerage, IRA, Roth.
  /// * [owner] - Account owner, e.g., self, spouse. Defaults to self.
  /// * [balance] - Account balance at plan start. Defaults to 0.0.
  /// * [costBasis] - Amount of the balance that is considered costBasis. Relevant for brokerage accounts. Defaults to 0.0.
  /// * [roiGain] - Yearly return on investemnt or rate of gain earned by the account. E.g., 0.25 is 25%. Defaults to 0.0.
  /// * [roiIncome] - Yearly return on investemnt of taxable income earned by the account. E.g., 0.05 is 5%.
  /// Relevant for brokerage accounts. Defaults to 0.0.
  AccountInfo(
      {String? name,
      required this.type,
      this.owner = OwnerType.self,
      this.balance = 0.0,
      this.costBasis = 0.0,
      this.roiGain = 0.0,
      this.roiIncome = 0.0})
      : name = name ?? _nextName(),
        id = _uuid.v4();

  // Strings used for JSON encoding.
  static const String _nameKey = 'name';
  static const String _typeKey = 'type';
  static const String _ownerKey = 'owner';
  static const String _balanceKey = 'balance';
  static const String _costBasisKey = 'costBasis';
  static const String _roiGainKey = 'roiGain';
  static const String _roiIncomeKey = 'roiIncome';

  /// Returns the class properties that Equatable should process.
  @override
  List<Object> get props => [
        name,
        type.label,
        owner.label,
        balance,
        costBasis,
        roiGain,
        roiIncome,
      ];
  @override
  bool get stringify => true;

  /// Returns a new immutable [AccountInfo] class updated with the specified arguments.
  AccountInfo copyWith(
          {String? name,
          AccountType? type,
          OwnerType? owner,
          double? balance,
          double? costBasis,
          double? roiGain,
          double? roiIncome}) =>
      AccountInfo(
        name: name ?? this.name,
        type: type ?? this.type,
        owner: owner ?? this.owner,
        balance: balance ?? this.balance,
        costBasis: costBasis ?? this.costBasis,
        roiGain: roiGain ?? this.roiGain,
        roiIncome: roiIncome ?? this.roiIncome,
      );

  /// Validates the fields of the [AccountInfo], storing any issues in the provided [messageService].
  /// [isMarried] is provided so that validating can take into account whether the owner is married or not.
  void validate(MessageService messageService, bool isMarried) {
    String shownName = name.isEmpty ? '?' : name;
    if (name.isEmpty || name.length > maxNameLength) {
      messageService.addError(
          'Account "$shownName": Name must be a text string between 1 and $maxNameLength characters.');
    }
    if (!isMarried && owner == OwnerType.spouse) {
      messageService.addError(
          'Account "$name": Owner type of ${OwnerType.spouse.label} is not valid in a plan designed for a single person.');
    }
    if (balance < 0.0) {
      messageService.addError(
          'Account "$name": Balance must be greater than or equal to zero.');
    }
    if (roiGain < 0.0) {
      messageService.addError(
          'Account "$name": Yearly gain rate must be greater than or equal to zero.');
    }
    if (type == AccountType.taxableBrokerage && roiIncome < 0.0) {
      messageService.addError(
          'Account "$name": Yearly income rate must be greater than or equal to zero.');
    }
    if (type == AccountType.taxableBrokerage && costBasis < 0.0) {
      messageService.addError(
          'Account "$name": Cost basis must be greater than or equal to zero.');
    }
  }

  /// Returns a map/dictionary of field name and value that can be used to generate JSON content.
  @override
  JsonMap toJsonMap() {
    return {
      _nameKey: name,
      _typeKey: type.label,
      _ownerKey: owner.label,
      _balanceKey: balance,
      _costBasisKey: costBasis,
      _roiGainKey: roiGain,
      if (type == AccountType.taxableBrokerage) _roiIncomeKey: roiIncome,
    };
  }

  /// Returns an [AccountInfo] object derived from the provided [data].
  /// * [messageService] - Is updated with messages for error/wanring/information issues encountered during processing.
  /// * [data] - MAP of JSON keywords and values.
  /// * [ancestorKey] - Path string to the current nodes immediate ancestor, used to help generate relevant text strings
  /// for error/wanring/information issues encountered during processing.
  factory AccountInfo.fromJsonMap(
    MessageService messageService,
    Map<String, dynamic> data,
    String ansestorKey,
  ) {
    // create an AccountInfo from default constuctor for defining default values.
    final AccountInfo defaultInfo =
        AccountInfo(type: AccountType.taxableSavings);

    // Fetch AccountInfo.name
    String name = getJsonStringFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _nameKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.name,
    );

    // Fetch AccountInfo.type
    AccountType type = getJsonFieldValue<AccountType>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _typeKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.type,
      fieldEncoder: AccountType.fromLabel,
    );

    // Fetch AccountInfo.owner
    OwnerType owner = getJsonFieldValue<OwnerType>(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _ownerKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.owner,
      fieldEncoder: OwnerType.fromLabel,
    );

    // Fetch AccountInfo.balance
    double balance = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _balanceKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.balance,
    );

    // Fetch AccountInfo.costBasis
    double costBasis = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _costBasisKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.costBasis,
    );

    // Fetch AccountInfo.roiGain
    double roiGain = getJsonDoubleFieldValue(
      messageService: messageService,
      jsonMap: data,
      fieldKey: _roiGainKey,
      ansestorKey: ansestorKey,
      defaultValue: defaultInfo.roiGain,
    );

    // Fetch AccountInfo.roiIncome (if its a brokerage account)
    double roiIncome = defaultInfo.roiIncome;
    if (type == AccountType.taxableBrokerage) {
      roiIncome = getJsonDoubleFieldValue(
        messageService: messageService,
        jsonMap: data,
        fieldKey: _roiIncomeKey,
        ansestorKey: ansestorKey,
        defaultValue: defaultInfo.roiIncome,
      );
    }

    // Check to see if there were additional / unknown fields in the json
    checkForUnknownFields(
        messageService: messageService,
        jsonMap: data,
        ansestorKey: ansestorKey);

    // Now return a new AccountInfo based on parsed values.
    return AccountInfo(
      name: name,
      type: type,
      owner: owner,
      balance: balance,
      costBasis: costBasis,
      roiGain: roiGain,
      roiIncome: roiIncome,
    );
  }
}
