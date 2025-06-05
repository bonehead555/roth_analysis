import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/data/plan_info.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/data/tax_filing_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/providers/accounts_provider.dart';
import 'package:roth_analysis/providers/income_sources_provider.dart';
import 'package:roth_analysis/providers/person_provider.dart';
import 'package:roth_analysis/providers/plan_provider.dart';
import 'package:roth_analysis/providers/provider_json_label.dart';
import 'package:roth_analysis/providers/scenarios_provider.dart';
import 'package:roth_analysis/providers/tax_filing_info_provider.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';
import 'package:roth_analysis/services/message_service.dart';

import 'dart:io';

/// Loads the providers from specified file.
/// [ref] - Allows access to the providers vit RiverPod.
/// [filePath] - Path to file to load from.
/// [messageService] - Service to store any error/warning/informational messages generated in the process
/// of opening and parsing the file content.
Future<void> loadProviders(
  WidgetRef ref,
  String filePath,
  MessageService messageService,
) async {
  String json;

  // Read JSON from specified file
  try {
    File file = File(filePath);
    json = await file.readAsString();
  } on FileSystemException catch (e) {
    messageService
        .addError('FileIO: ${e.message} while reading from $filePath');
    return;
  }

  // Parse JSON and intialize providers
  _jsonToProviders(ref, json, messageService);
  return;
}

/// Parses the json content read from the file an intializes respective providers.
/// [ref] - Allows access to the providers via RiverPod.
/// [json] - JSON data read from file.
/// [messageService] - Service to store and error/warning/informational messages generated in the process
/// of parsing the JSON content.
void _jsonToProviders(
    WidgetRef ref, String json, MessageService messageService) {
  // Decode JSON data to a JsonMap
  JsonMap jsonMap = {};
  try {
    jsonMap = jsonDecode(json);
  } on FormatException catch (e) {
    messageService.addError('JSON: ${e.message} (at character ${e.offset}).');
    return;
  } catch (e) {
    messageService.addError(e.toString());
    return;
  }

  // Build a 'self' PersonInfo from JsonMap
  PersonInfo selfInfo = getNestedJsonFieldValue(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.self.label,
    ansestorKey: 'root',
    defaultValue: const PersonInfo(),
    fieldEncoder: PersonInfo.fromJsonMap,
  );

  // Build a 'spouse' PersonInfo from JsonMap
  PersonInfo spouseInfo = getNestedJsonFieldValue(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.spouse.label,
    ansestorKey: 'root',
    defaultValue: const PersonInfo(),
    fieldEncoder: PersonInfo.fromJsonMap,
  );

  // Build a PlanInfo from JsonMap
  PlanInfo planInfo = getNestedJsonFieldValue(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.planInfo.label,
    ansestorKey: 'root;',
    defaultValue: const PlanInfo(),
    fieldEncoder: PlanInfo.fromJsonMap,
  );

  // Build a TaxFilingInfo from JsonMap
  TaxFilingInfo taxFilingInfo = getNestedJsonFieldValue(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.taxFilingInfo.label,
    ansestorKey: 'root',
    defaultValue: const TaxFilingInfo(),
    fieldEncoder: TaxFilingInfo.fromJsonMap,
  );

  // Build a list of IncomeInfo from JsonMap
  IncomeInfos incomeInfos = getListJsonFieldValue<IncomeInfo>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.incomeInfos.label,
    ansestorKey: 'root',
    defaultValue: IncomeInfo(type: IncomeType.employment),
    fieldEncoder: IncomeInfo.fromJsonMap,
  );

  // Build a list of AccountInfo from JsonMap
  AccountInfos accountInfos = getListJsonFieldValue<AccountInfo>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.accountInfos.label,
    ansestorKey: 'root',
    defaultValue: AccountInfo(type: AccountType.taxableSavings),
    fieldEncoder: AccountInfo.fromJsonMap,
  );

  // Build a list of ScenarioInfo from JsonMap
  ScenarioInfos scenarioInfos = getListJsonFieldValue<ScenarioInfo>(
    messageService: messageService,
    jsonMap: jsonMap,
    fieldKey: ProviderJsonLabel.scenarioInfos.label,
    ansestorKey: 'root',
    defaultValue: ScenarioInfo(),
    fieldEncoder: ScenarioInfo.fromJsonMap,
  );

  if (messageService.errorCount == 0) {
    // Update all providers from info loaded/built above
    ref.read(selfProvider.notifier).updateAll(selfInfo);
    ref.read(spouseProvider.notifier).updateAll(spouseInfo);
    ref.read(planProvider.notifier).updateAll(planInfo);
    ref.read(taxFilingInfoProvider.notifier).updateAll(taxFilingInfo);
    ref.read(incomeInfoProvider.notifier).updateAll(incomeInfos);
    ref.read(accountInfoProvider.notifier).updateAll(accountInfos);
    ref.read(scenarioInfosProvider.notifier).updateAll(scenarioInfos);
  }
}
