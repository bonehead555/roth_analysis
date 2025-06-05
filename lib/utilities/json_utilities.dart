import 'package:roth_analysis/models/data/base_info.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';

typedef JsonMap = Map<String, dynamic>;

List<JsonMap> buildJsonMapFromList(
  List<BaseInfo> items,
) {
  List<JsonMap> result = [];
  for (BaseInfo item in items) {
    result.add(item.toJsonMap());
  }
  return result;
}

T getJsonFieldValue<T>({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required T defaultValue,
  T Function(String)? fieldEncoder,
}) {
  T? result = getNullableJsonFieldValue<T>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
    fieldEncoder: fieldEncoder,
  );
  if (result == null) {
    return defaultValue;
  } else {
    return result;
  }
}

String getJsonStringFieldValue({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required String defaultValue,
}) {
  String result = getJsonFieldValue<String>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
  );
  return result;
}

bool getJsonBoolFieldValue({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required bool defaultValue,
}) {
  bool result = getJsonFieldValue<bool>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
  );
  return result;
}

double getJsonDoubleFieldValue({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required double defaultValue,
}) {
  double result = getJsonFieldValue<double>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
  );
  return result;
}

int getJsonIntFieldValue({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required int defaultValue,
}) {
  int result = getJsonFieldValue<int>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
  );
  return result;
}

DateTime? getJsonDateFieldValue({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required DateTime? defaultValue,
}) {
  var result = getNullableJsonFieldValue<DateTime?>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: fieldKey,
    ansestorKey: ansestorKey,
    defaultValue: defaultValue,
    fieldEncoder: dateFromString,
  );
  return result;
}

T? getNullableJsonFieldValue<T>({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required T? defaultValue,
  T? Function(String)? fieldEncoder,
}) {
  dynamic temp = jsonMap.remove(fieldKey);
  T? result = defaultValue;
  if (temp == null) {
    messageService.addWarning(
        'JSON: Missing field "$ansestorKey.$fieldKey". Default value of "$defaultValue" assumed!');
  } else if (temp is T && fieldEncoder == null) {
    result = temp;
  } else if (temp is String && fieldEncoder != null) {
    result = fieldEncoder(temp);
  } else {
    messageService.addWarning(
        'JSON: Invalid field value "$ansestorKey.$fieldKey:$temp". Default value of "$defaultValue" assumed!');
  }
  return result;
}

T getNestedJsonFieldValue<T>({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required T defaultValue,
  required T Function(MessageService, JsonMap, String) fieldEncoder,
}) {
  String myFullKey = '$ansestorKey.$fieldKey';
  dynamic temp = jsonMap.remove(fieldKey);
  T result = defaultValue;
  if (temp == null) {
    messageService.addWarning(
        'JSON: Missing field "$myFullKey". Default value of "$defaultValue" assumed!');
  } else if (temp is JsonMap) {
    result = fieldEncoder(messageService, temp, myFullKey);
  } else {
    messageService.addWarning(
        'JSON: Invalid nested field value for "$myFullKey". Default value assumed!');
  }
  checkForUnknownFields(
      messageService: messageService, jsonMap: temp, ansestorKey: myFullKey);
  return result;
}

List<T> getListJsonFieldValue<T>({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String fieldKey,
  required String ansestorKey,
  required T defaultValue,
  required T Function(MessageService, JsonMap, String) fieldEncoder,
}) {
  List<T> result = [];
  String myFullKey = '$ansestorKey.$fieldKey';
  dynamic temp = jsonMap.remove(fieldKey);

  if (temp == null) {
    messageService
        .addWarning('JSON: Missing field "$myFullKey". Empty array assumed!');
  } else if (temp is List<dynamic>) {
    for (int i = 0; i < temp.length; i++) {
      JsonMap element = temp[i] as JsonMap;
      String myArrayKey = '$myFullKey[$i]';
      result.add(fieldEncoder(messageService, element, myArrayKey));
    }
  } else {
    messageService.addWarning(
        'JSON: Invalid nested field value for "$myFullKey". Empty array assumed');
  }
   return result;
}

void checkForUnknownFields({
  required MessageService messageService,
  required JsonMap jsonMap,
  required String ansestorKey,
}) {
  if (jsonMap.isNotEmpty) {
    for (String key in jsonMap.keys) {
      messageService.addWarning(
          'JSON: Invalid/Unknown field: "$ansestorKey.$key". Key ignored!');
    }
  }
}
