import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/data/plan_info.dart';
import 'package:roth_analysis/models/data/tax_filing_info.dart';
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

/// Saves the providers to specified file.
/// [ref] - Allows access to the providers vit RiverPod.
/// [filePath] - Path to file to save into.
/// [messageService] - Service to store any error/warning/informational messages generated in the process
/// of opening and saving the file content.
Future<void> saveProviders(
  WidgetRef ref,
  String filePath,
  MessageService messageService,
) async {
  // Convert configuration to JSON
  String? json = _providersToJson(ref, messageService);
  if (json == null) return;

  // Write JSON to specified file
  try {
    File file = File(filePath);
    await file.writeAsString(json);
  } on FileSystemException catch (e) {
    messageService.addError('FileIO: ${e.message} while writing to $filePath');
    return;
  } catch (e) {
    messageService.addError(e.toString());
  }

  // Success
  return;
}

/// Encodes reseoctive provider content into JSON content and returns that content.
/// [ref] - Allows access to the providers via RiverPod.
/// [messageService] - Service to store and error/warning/informational messages generated in the process
/// of encoding the JSON content.
String? _providersToJson(WidgetRef ref, MessageService messageService) {
  // Get infos from providers
  PersonInfo selfInfo = ref.read(selfProvider);
  PersonInfo spouseInfo = ref.read(spouseProvider);
  PlanInfo planInfo = ref.read(planProvider);
  TaxFilingInfo taxFilingInfo = ref.read(taxFilingInfoProvider);
  IncomeInfos incomeInfos = ref.read(incomeInfoProvider);
  AccountInfos accountInfos = ref.read(accountInfoProvider);
  ScenarioInfos scenarioInfos = ref.read(scenarioInfosProvider);

  // Convert infos to a JsonMap
  JsonMap jsonMap = {
    ProviderJsonLabel.self.label: selfInfo.toJsonMap(),
    ProviderJsonLabel.spouse.label: spouseInfo.toJsonMap(),
    ProviderJsonLabel.planInfo.label: planInfo.toJsonMap(),
    ProviderJsonLabel.taxFilingInfo.label: taxFilingInfo.toJsonMap(),
    ProviderJsonLabel.incomeInfos.label: buildJsonMapFromList(incomeInfos),
    ProviderJsonLabel.accountInfos.label: buildJsonMapFromList(accountInfos),
    ProviderJsonLabel.scenarioInfos.label: buildJsonMapFromList(scenarioInfos),
  };

  // Convert JsonMap to JSON
  String? jsonString;
  try {
    jsonString = jsonEncode(jsonMap);
  } catch (e) {
    messageService.addError(e.toString());
  }

  // Return JSON result
  return jsonString;
}
